/*
   a2duino

   sketch for Arduino based data acquisition system
   configured and controlled through corresponding MATLAB object

   Some notes on serial communications:
   http://www.gammon.com.au/serial

   Some notes on interrupts:
   http://www.gammon.com.au/interrupts

   Some notes on timers:
   http://www.avrfreaks.net/forum/tut-c-newbies-guide-avr-timers?name=PNphpBB2&file=viewtopic&t=50106

   Lee Lovejoy
   ll2833@columbia.edu
   January 2017

   March 2017--revisions for use with ATmega32u4 as well as ATmega328p based MCU, mainly using Timer0 and Timer1 which are the same on these two MCU's
*/

/*
   Constants
*/

// Serial communication rate in bits per second
const unsigned long __baudRate = 230400;

// Timers; timer0 is the primary clock for analog data sampling
// Target Timer Count = (Input Frequency / Prescale) / Target Frequency - 1
// Input frequency is 16 MHz
// Timer0 is 8-bit; 256 values
// Timer1 is 16-bit, 65536 values
// (CMR = 249, prescalar = 64) give a sampling rate of 1KHz on Timer0
// (CMR = 12499, prescalar = 256) give a sampling rate of 5 Hz on Timer1
const int __compareMatchRegisterTimer0 = 249;
const int __prescalarTimer0 = 64;
const int __compareMatchRegisterTimer1 = 12499;
const int __prescalarTimer1 = 256;

// External interrupts
// Interrupt Sense Control on ISC00 and ISC01:
// LOW, CHANGE, FALLING, and RISING
// Pin modes:  INPUT, OUTPUT, and INPUT_PULLUP
const int __externalInterruptRequest0 = 2;
const int __externalInterruptSenseControl0 = FALLING;
const int __externalInterruptRequest0PinMode = INPUT_PULLUP;
const int __externalInterruptRequest1 = 3;
const int __externalInterruptSenseControl1 = FALLING;
const int __externalInterruptRequest1PinMode = INPUT_PULLUP;

// Analog data acquisition buffer
const int __adcNumChannels = 6;
const int __adcChannels[__adcNumChannels] = {0, 1, 2, 3, 4, 5};
const int __adcMaxBufferSize = 516;

// Reward delivery
const int __rewardOutputPin = 12;
const int __rewardOutputPinInitialState = LOW;
const int __pelletMaxAttempts = 11;

// Event listener
const int __eventListenerPin = __externalInterruptRequest1;
const int __eventListenerMaxEvents = 30;

// Command codes
const int __maxInstructionLength = 100;

const int __writeTicsSinceStart = 1;
const int __writeAdcVoltages = 3;
const int __writeAdcSchedule = 7;
const int __writeAdcStatus = 9;
const int __writeAdcBuffer = 11;
const int __writeeventListener = 13;
const int __writePelletReleaseStatus = 17;
const int __writeDeviceSettings = 19;
const int __startAdcSchedule = 21;
const int __stopAdcSchedule = 23;
const int __starteventListener = 25;
const int __stopeventListener = 27;
const int __startFluidReward = 40;
const int __startPelletRelease = 41;
const int __readAdcSchedule = 50;

/*
   Global variables
*/

byte instruction[__maxInstructionLength];

volatile unsigned long ticksSinceStart = 0;

// Analog data acquisition buffer
volatile boolean adcScheduleRunning = false;
volatile int adcVoltages[__adcNumChannels];
volatile int adcBuffer[__adcMaxBufferSize];
int adcBufferSize;
volatile int adcBufferIndex;
boolean adcUseRingBuffer = true;
int adcScheduleOnsetDelay = 0;
unsigned long adcScheduleOnset = 0;
volatile unsigned long adcLastTick;
int adcNumScheduledChannels;
int adcNumScheduledFrames;
int adcNumRequestedFrames;
int adcNumRequestedBytes;
int adcScheduledChannelList[__adcNumChannels];

// Pellet delivery--on rewardOutputPin, controlled via externalInterruptRequest0
volatile boolean pelletReleaseDetected = false;
volatile unsigned long pelletStartReleaseTicks;
volatile unsigned long pelletCompleteReleaseTicks;
volatile int pelletNumAttempts;

// Event Listener
boolean eventListenerListening = false;
volatile boolean eventListenerEventDetected = false;
unsigned long eventListenerStartTicks;
volatile unsigned long eventListenerDetections[__eventListenerMaxEvents];
volatile int eventListenerIndex = 0;

// Function for converting bytes to integers
int bytes2int(byte *a) {
  return a[0] + (a[1] << 8);
}

/*
   setup

   Here we configure the timers and interrupts, configure pins, and open the serial connection
*/

void setup() {

  // Initialize and enable Timer0 (clock for ADC)
  TIMSK0 &= (0 << OCIE0A);                  // Clear OCIE0A to DISABLE compare A match interrupt on TIMER0_COMPA_vect
  TCCR0A = 0;                               // Clear TCCR0A register (normal operation)
  TCCR0B = 0;                               // Clear TCCR0B register (normal operation)
  TCNT0 = 0;                                // Initialize counter value to 0
  OCR0A = __compareMatchRegisterTimer0;     // Set compare match register
  TCCR0A |= (1 << WGM01);                   // Set TCCR0A bit WGM21 to enable CTC mode
  switch (__prescalarTimer0) {
    case 1:
      TCCR0B |= (1 << CS00);                // Set TCCR0B bit CS00 for no prescaling
      break;
    case 8:
      TCCR0B |= (1 << CS01);                // set TCRR0B bit CS01 for 8 prescaling
      break;
    case 64:
      TCCR0B |= (1 << CS01) | (1 << CS00);  // Set TCCR0B bit CS01 and CS00 for 64 prescaling
      break;
    case 256:
      TCCR0B |= (1 << CS02);                // Set TCCR0B bit CS02 for 256 prescaling
      break;
    case 1024:
      TCCR0B |= (1 << CS02) | (1 << CS00);  // Set TCCR0B bits CS02 and CS00 for 1024 prescaling
      break;
  }
  TIMSK0 |= (1 << OCIE0A);                  // Set OCIE0A to ENABLE compare A match interrupt on TIMER0_COMPA_vect

  // Initialize Timer1 but do not enable (for reward system)
  TIMSK1 &= (0 << OCIE1A);                  // Set OCIE1A to DISABLE compare A match interrupt on TIMER1_COMPA_vect
  TIMSK1 &= (0 << OCIE1B);                  // Set OCIE1B to DISABLE compare B match interrupt on TIMER1_COMBB_vect
  TCCR1A = 0;                               // Clear TCCR1A register (normal operation)
  TCCR1B = 0;                               // Clear TCCR1B register (normal operation)
  TCNT1  = 0;                               // Initialize counter value to 0
  OCR1A  = __compareMatchRegisterTimer1;    // Set compare match register
  TCCR1B |= (1 << WGM12);                   // Set TCCR1B bit WGM12 to enable CTC mode
  switch (__prescalarTimer1) {
    case 1:
      TCCR1B |= (1 << CS10);                // Set TCCR1B bit CS10 for no prescaling
      break;
    case 8:
      TCCR1B |= (1 << CS11);                // set TCRR1B bit CS11 for 8 prescaling
      break;
    case 64:
      TCCR1B |= (1 << CS11) | (1 << CS10);  // Set TCCR1B bit CS11 and CS10 for 64 prescaling
      break;
    case 256:
      TCCR1B |= (1 << CS12);                // Set TCCR1B bit CS12 for 256 prescaling
      break;
    case 1024:
      TCCR1B |= (1 << CS12) | (1 << CS10);  // Set TCCR1B bits CS12 and CS10 for 1024 prescaling
      break;
  }

  // Set pin modes for external interrupts
  pinMode(__externalInterruptRequest0, __externalInterruptRequest0PinMode);
  pinMode(__externalInterruptRequest1, __externalInterruptRequest1PinMode);

  // configure external interrupts
  EICRA = (EICRA & ~((1 << ISC00) | (1 << ISC01))) | (__externalInterruptSenseControl0 << ISC00);
  EIMSK |= (1 << INT0);
  EICRA = (EICRA & ~((1 << ISC10) | (1 << ISC11))) | (__externalInterruptSenseControl1 << ISC10);
  EIMSK |= (1 << INT1);

  // Set digital output pin
  pinMode(__rewardOutputPin, OUTPUT);
  digitalWrite(__rewardOutputPin, __rewardOutputPinInitialState);

  // Open serial connection at minimum baud, then transmit board data
  Serial.begin(230400);

  // Write to serial the board specific constants for MATLAB object
  writeDeviceSettings();

  // Wait for outgoing serial data to complete
  Serial.flush();
}

/*
   loop

   We want to receive instructions without "blocking" the Arduino from other processes.
   Hence I need to store incoming serial data into a buffer during the loop; once it is
   complete, I can process the instruction.

   Any command with a one in the least significant bit will be executed immediately.
*/
void loop() {

  static boolean instructionIncoming = false; //  Flag to track if instruction is incoming
  static int numBytes;                        //  Number of bytes in the instruction
  static int command;                         //  Commmand
  static int index = 0;                       //  index into byte array

  if (Serial.available() > 0) {
    if (!instructionIncoming) {
      command = (int) Serial.read();
      if (command & 1) processInstruction(command);
      else {
        numBytes = 0;
        instructionIncoming = true;
      }
    } else if (instructionIncoming && numBytes == 0) numBytes = (int) Serial.read();
    else if (instructionIncoming) {
      instruction[index++] = Serial.read();
      if (!(index %= numBytes)) {
        instructionIncoming = false;
        processInstruction(command);
      }
    }
  }
}

/*
   processInstruction

   Based on the command, route the instruction to the appropriate command function
*/
void processInstruction(int command) {

  switch (command) {

    case __writeTicsSinceStart:
      writeTicsSinceStart();
      break;

    case __writeAdcVoltages:
      writeAdcVoltages();
      break;

    case __writeAdcSchedule:
      writeAdcSchedule();
      break;

    case __writeAdcStatus:
      writeAdcStatus();
      break;

    case __writeAdcBuffer:
      writeAdcBuffer();
      break;

    case __writeeventListener:
      writeeventListener();
      break;

    case __writePelletReleaseStatus:
      writePelletReleaseStatus();
      break;

    case __writeDeviceSettings:
      writeDeviceSettings();
      break;

    case __startAdcSchedule:
      startAdcSchedule();
      break;

    case __stopAdcSchedule:
      stopAdcSchedule();
      break;

    case __starteventListener:
      starteventListener();
      break;

    case __stopeventListener:
      stopeventListener();
      break;

    case __startFluidReward:
      startFluidReward();
      break;

    case __startPelletRelease:
      startPelletRelease();
      break;

    case __readAdcSchedule:
      readAdcSchedule();
      break;
  }
}

/*
   writeTicsSinceStart

   Write to serial the number of samples counted since startup
*/
void writeTicsSinceStart() {
  Serial.write((byte*)&ticksSinceStart, sizeof(ticksSinceStart));
}

/*
   writeAdcVoltages

   Write to serial the voltages on the ADC channels
*/
void writeAdcVoltages() {
  Serial.write((byte*)&__adcNumChannels, sizeof(__adcNumChannels));
  Serial.write((byte*)adcVoltages, sizeof(adcVoltages[0])*__adcNumChannels);
}

/*
   writeAdcSchedule

   Write ADC Schedule to serial
*/
void writeAdcSchedule() {
  Serial.write((byte*)&adcNumScheduledChannels, sizeof(adcNumScheduledChannels));
  Serial.write((byte*)adcScheduledChannelList, sizeof(adcScheduledChannelList[0])*adcNumScheduledChannels);
  Serial.write((byte*)&adcNumScheduledFrames, sizeof(adcNumScheduledFrames));
  Serial.write((byte*)&adcScheduleOnsetDelay, sizeof(adcScheduleOnsetDelay));
  Serial.write(adcUseRingBuffer);
  Serial.write((byte*)&adcNumRequestedFrames, sizeof(adcNumRequestedFrames));
}

/*
   writeAdcStatus
*/
void writeAdcStatus() {
  Serial.write(adcScheduleRunning);
}

/*
   writeAdcBuffer

   Write ADC buffer to serial port
*/
void writeAdcBuffer() {
  int adcBufferIndex__ = adcBufferIndex;
  int startIndex;
  unsigned long adcLastTick__ = adcLastTick;

  startIndex = (adcBufferIndex__ - adcNumRequestedFrames * adcNumScheduledChannels) % adcBufferSize;

  if (adcBufferIndex__ >= adcNumRequestedBytes)
    Serial.write((byte*)&adcBuffer[adcBufferIndex__ - adcNumRequestedBytes], sizeof(adcBuffer[0])*adcNumRequestedBytes);
  else {
    Serial.write((byte*)&adcBuffer[adcBufferSize - adcNumRequestedBytes + adcBufferIndex__], sizeof(adcBuffer[0]) * (adcNumRequestedBytes - adcBufferIndex__));
    Serial.write((byte*)&adcBuffer[0], sizeof(adcBuffer[0])*adcBufferIndex__);
  }
  Serial.write((byte*)&adcLastTick__, sizeof(adcLastTick__));
}

/*
   writeEventListener
*/
void writeeventListener() {
  Serial.write((byte*)&eventListenerIndex, sizeof(eventListenerIndex));
  if (eventListenerIndex > 0) Serial.write((byte*)eventListenerDetections, sizeof(eventListenerDetections[0])*eventListenerIndex);
  eventListenerIndex = 0;
  eventListenerEventDetected = false;
}

/*
   writePelletReleaseStatus
*/
void writePelletReleaseStatus() {
  Serial.write(pelletReleaseDetected);
  Serial.write((byte*)&pelletCompleteReleaseTicks, sizeof(pelletCompleteReleaseTicks));
  Serial.write((byte*)&pelletNumAttempts, sizeof(pelletNumAttempts));
}

/*
   writeDeviceSettings
*/
void writeDeviceSettings() {
  int mcuType = SIGNATURE_2;
  Serial.write((byte*)&mcuType, sizeof(mcuType));
  Serial.write((byte*)&__compareMatchRegisterTimer0, sizeof(__compareMatchRegisterTimer0));
  Serial.write((byte*)&__prescalarTimer0, sizeof(__prescalarTimer0));
  Serial.write((byte*)&__compareMatchRegisterTimer1, sizeof(__compareMatchRegisterTimer1));
  Serial.write((byte*)&__prescalarTimer1, sizeof(__prescalarTimer1));
  Serial.write((byte*)&__adcMaxBufferSize, sizeof(__adcMaxBufferSize));
  Serial.write((byte*)&__adcNumChannels, sizeof(__adcNumChannels));
  Serial.write((byte*)&__eventListenerMaxEvents, sizeof(__eventListenerMaxEvents));
  Serial.write((byte*)&__pelletMaxAttempts, sizeof(__pelletMaxAttempts));
}


/*
   startAdcSchedule
*/
void startAdcSchedule() {
  int i;

  adcScheduleOnset = ticksSinceStart + adcScheduleOnsetDelay;
  adcBufferIndex = 0;
  adcScheduleRunning = true;
}

/*
   stopAdcSchedule
*/
void stopAdcSchedule() {
  adcScheduleRunning = false;
}

/*
   starteventListener
*/
void starteventListener() {
  eventListenerListening = true;
  eventListenerIndex = 0;
  eventListenerStartTicks = ticksSinceStart;
  eventListenerEventDetected = false;
}

/*
   stopeventListener
*/
void stopeventListener() {
  eventListenerListening = false;
  eventListenerEventDetected = false;
}

/*
   startFluidReward
*/
void startFluidReward() {
  TCNT1 = 0;                                // Reset counter
  OCR1B = bytes2int(&instruction[0]);       // Set compare match register B to fluid reward duration
  OCR1A = OCR1B;                            // Make sure OCR1A == OCR1B
  TIMSK1 |= (1 << OCIE1B);                  // Enable interrupt TIMER1_COMPB_vect
}

/*
   startPelletRelease
*/
void startPelletRelease() {
  pelletReleaseDetected = false;
  pelletCompleteReleaseTicks = 0;
  pelletNumAttempts = 0;
  OCR1A  = __compareMatchRegisterTimer1;    // Set compare match register A
  TCNT1  = 0;                               // Reset counter
  TIMSK1 |= (1 << OCIE1A);                  // Enable interrupt TIMER1_COMPA_vect
}

/*
   readAdcSchedule

   Read ADC schedule
*/
void readAdcSchedule() {
  int i;

  adcNumScheduledChannels = instruction[0];
  for (i = 0; i < adcNumScheduledChannels; i++) adcScheduledChannelList[i] = instruction[i + 1];
  adcNumScheduledFrames = bytes2int(&instruction[adcNumScheduledChannels + 1]);
  adcScheduleOnsetDelay = bytes2int(&instruction[adcNumScheduledChannels + 3]);
  adcUseRingBuffer = (instruction[adcNumScheduledChannels + 5] > 0);
  adcNumRequestedFrames = bytes2int(&instruction[adcNumScheduledChannels + 6]);
  adcBufferSize = adcNumScheduledFrames * adcNumScheduledChannels;
  adcNumRequestedBytes = adcNumRequestedFrames * adcNumScheduledChannels;
}

/*
  Interrupt service routine triggered at INT0_vect (external interrupt request 0, pin D2)
  Detect pellet release
*/
ISR(INT0_vect) {
  pelletReleaseDetected = true;
  pelletCompleteReleaseTicks = ticksSinceStart - pelletStartReleaseTicks;
  TIMSK1 &= (0 << OCIE1A);                    // Disable TIMER1_COMPA_vect until next call
}

/*
  Interrupt service routine triggered at INT1_vect (external interrupt request 1, pin D3)
*/
ISR(INT1_vect) {
  if (eventListenerListening && eventListenerIndex < __eventListenerMaxEvents) eventListenerDetections[eventListenerIndex++] = ticksSinceStart;
  eventListenerEventDetected = true;
}

/*
   Interrupt service routine triggered at TIMER0_COMPA_vect
   Capture analog data
*/
ISR(TIMER0_COMPA_vect) {
  int i;

  for (i = 0; i < __adcNumChannels; i++) adcVoltages[i] = analogRead(i);
  if (adcScheduleRunning) {
    if (ticksSinceStart >= adcScheduleOnset) {
      for (i = 0; i < adcNumScheduledChannels; i++) adcBuffer[adcBufferIndex + i] = adcVoltages[adcScheduledChannelList[i]];
      adcBufferIndex += adcNumScheduledChannels;
      adcLastTick = ticksSinceStart;
      if (adcBufferIndex >= adcBufferSize)
        if (adcUseRingBuffer) adcBufferIndex = 0;
        else adcScheduleRunning = false;
    }
  }
  ticksSinceStart++;
}

/*
    Interrupt service routine triggered at TIMER1_COMPA_vect
    Trigger pellet release
*/
ISR(TIMER1_COMPA_vect) {
  if (pelletNumAttempts < __pelletMaxAttempts) {
    digitalWrite(__rewardOutputPin, HIGH);
    digitalWrite(__rewardOutputPin, LOW);
    pelletStartReleaseTicks = ticksSinceStart;
    pelletNumAttempts++;
  } else
    TIMSK1 &= (0 << OCIE1A);                    // Disable interrupt until next call
}

/*
   Interrupt service routine triggered at TIMER1_COMPB_vect
   Start and stop fluid reward
*/
ISR(TIMER1_COMPB_vect) {
  if (!digitalRead(__rewardOutputPin))
    digitalWrite(__rewardOutputPin, HIGH);
  else {
    digitalWrite(__rewardOutputPin, LOW);
    TIMSK1 &= (0 << OCIE1B);
  }
}

