/*
   a2duino

   sketch for Arduino based data acquisition system
   configured and controlled through corresponding MATLAB object

   Some notes on serial communications:
   http://www.gammon.com.au/serial

   Some notes on interrupts:
   http://www.gammon.com.au/interrupts

   Lee Lovejoy
   ll2833@columbia.edu
   January 2017
*/

/*
   Constants
*/

// Serial communication
const unsigned long __baud = 230400;

// Timers
// (CMR = 12499, prescalar = 256) give a sampling rate of 5 Hz
// (CMR = 24999, prescalar = 64) give a sampling rate of 10 Hz
// (CMR = 249, prescalar = 64) give a sampling rate of 1KHz
const int __compareMatchRegisterTimer1 = 12499;
const int __prescalarTimer1 = 256;
const int __compareMatchRegisterTimer2 = 249;
const int __prescalarTimer2 = 64;

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
const int __adcMaxBufferSize = 500;

// Reward delivery
const int __rewardNumOutputPins = 1;
const int __rewardOutputPin0 = 12;
const int __rewardOutputPin0InitialState = LOW;
const int __pelletMaxAttempts = 11;

// Event listeners
const int __eventListenersNumInputPins = 1;
const int __eventListener0Pin = __externalInterruptRequest1;
const int __eventListenersMaxEvents = 30;

// Command codes
const int __maxInstructionLength = 100;
const int __writeTicsSinceStart = 1;
const int __writeAdcVoltages = 3;
const int __writeAdcSchedule = 7;
const int __writeAdcStatus = 9;
const int __writeAdcBuffer = 11;
const int __writeEventListener0 = 13;
const int __writePelletReleaseStatus = 17;
const int __startAdcSchedule = 21;
const int __stopAdcSchedule = 23;
const int __startEventListener0 = 25;
const int __stopEventListener0 = 27;
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

// Pellet delivery--on rewardOutputPin0, controlled via externalInterruptRequest0
volatile boolean pelletReleaseInProgress = false;
volatile boolean pelletDropDetected = false;
volatile boolean pelletReleaseFailed = false;
unsigned long pelletStartReleaseTicks;
volatile unsigned long pelletCompleteReleaseTicks;
volatile int pelletNumAttempts;

// Event Listener
boolean eventListener0Listening = false;
volatile boolean eventListener0EventDetected = false;
unsigned long eventListener0StartTicks;
volatile unsigned long eventListener0Detections[__eventListenersMaxEvents];
volatile int eventListener0Index = 0;

// Function for converting bytes to integers
int bytes2int(byte *a) {
  return a[0] + (a[1] << 8);
}

/*
   setup

   Here we configure the timers and interrupts, configure pins, and open the serial connection
*/

void setup() {
  int i;

  // Prior to initializing timers, disable all interrupts.
  noInterrupts();

  // Initialize timer1

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
  TIMSK1 |= (1 << OCIE1A);                  // Set OCIE1A to enable compare A match interrupt on TIMER1_COMPA_vect

  // Initialize timer2

  TCCR2A = 0;                               // Clear TCCR2A register (normal operation)
  TCCR2B = 0;                               // Clear TCCR2B register (normal operation)
  TCNT2 = 0;                                // Initialize counter value to 0
  OCR2A = __compareMatchRegisterTimer2;     // Set compare match register
  TCCR2A |= (1 << WGM21);                   // Set TCCR2A bit WGM21 to enable CTC mode
  switch (__prescalarTimer2) {
    case 1:
      TCCR2B |= (1 << CS20);                // Set TCCR2B bit CS20 for no prescaling
      break;
    case 8:
      TCCR2B |= (1 << CS21);                // set TCRR2B bit CS21 for 8 prescaling
      break;
    case 32:
      TCCR2B |= (1 << CS21) | (1 << CS20);  // Set TCCR2B bit CS21 and CS20 for 32 prescaling
      break;
    case 64:
      TCCR2B |= (1 << CS22);                // Set TCCR2B bit CS22 for 64 prescaling
      break;
    case 128:
      TCCR2B |= (1 << CS22) | (1 << CS20);  // Set TCCR2B bits CS22 and CS20 for 128 prescaling
      break;
    case 256:
      TCCR2B |= (1 << CS22) | (1 << CS21);  // Set TCCR2B bits CS22 and CS21 for 256 prescaling
      break;
    case 1024:
      TCCR2B |= (1 << CS22) | (1 << CS21) | (1 << CS20);  // Set TCCR2B bits CS22, CS21, and CS20 for 1024 prescaling
      break;
  }
  TIMSK2 |= (1 << OCIE2A);

  // Once timers have been initialized, enable interrupts
  interrupts();

  // Set pin modes for external interrupts
  pinMode(__externalInterruptRequest0, __externalInterruptRequest0PinMode);
  pinMode(__externalInterruptRequest1, __externalInterruptRequest1PinMode);

  // configure external interrupts
  EICRA = (EICRA & ~((1 << ISC00) | (1 << ISC01))) | (__externalInterruptSenseControl0 << ISC00);
  EIMSK |= (1 << INT0);
  EICRA = (EICRA & ~((1 << ISC10) | (1 << ISC11))) | (__externalInterruptSenseControl1 << ISC10);
  EIMSK |= (1 << INT1);

  // Set digital output pin
  pinMode(__rewardOutputPin0, OUTPUT);
  digitalWrite(__rewardOutputPin0, __rewardOutputPin0InitialState);

  // Open serial connection
  Serial.begin(__baud);

  // Write to serial the Arduinio specific constants for MATLAB object
  Serial.write((byte*)&__compareMatchRegisterTimer1, sizeof(__compareMatchRegisterTimer1));
  Serial.write((byte*)&__prescalarTimer1, sizeof(__prescalarTimer1));
  Serial.write((byte*)&__compareMatchRegisterTimer2, sizeof(__compareMatchRegisterTimer2));
  Serial.write((byte*)&__prescalarTimer2, sizeof(__prescalarTimer2));
  Serial.write((byte*)&__adcMaxBufferSize, sizeof(__adcMaxBufferSize));
  Serial.write((byte*)&__adcNumChannels, sizeof(__adcNumChannels));
  Serial.write((byte*)&__rewardNumOutputPins, sizeof(__rewardNumOutputPins));
  Serial.write((byte*)&__eventListenersNumInputPins, sizeof(__eventListenersNumInputPins));
  Serial.write((byte*)&__eventListenersMaxEvents, sizeof(__eventListenersMaxEvents));
}

/*
   loop

   Receiving serial data is slow, and we want to receive the instruction without "blocking"
   the Arduino from other processes.  Hence I need to store incoming serial data into a buffer
   during the loop; once it is complete, I can process the instruction.

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

    case __writeEventListener0:
      writeEventListener0();
      break;

    case __writePelletReleaseStatus:
      writePelletReleaseStatus();
      break;

    case __startAdcSchedule:
      startAdcSchedule();
      break;

    case __stopAdcSchedule:
      stopAdcSchedule();
      break;

    case __startEventListener0:
      startEventListener0();
      break;

    case __stopEventListener0:
      stopEventListener0();
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
  unsigned long t;

  startIndex = (adcBufferIndex__ - adcNumRequestedFrames * adcNumScheduledChannels) % adcBufferSize;

  t = micros();
  if (adcBufferIndex__ >= adcNumRequestedBytes)
    Serial.write((byte*)&adcBuffer[adcBufferIndex__ - adcNumRequestedBytes], sizeof(adcBuffer[0])*adcNumRequestedBytes);
  else {
    Serial.write((byte*)&adcBuffer[adcBufferSize - adcNumRequestedBytes + adcBufferIndex__], sizeof(adcBuffer[0]) * (adcNumRequestedBytes - adcBufferIndex__));
    Serial.write((byte*)&adcBuffer[0], sizeof(adcBuffer[0])*adcBufferIndex__);
  }
  //  Serial.write((byte*)&adcBuffer[adcBufferIndex__], sizeof(adcBuffer[0]) * (adcBufferSize - adcBufferIndex__));
  // Serial.write((byte*)&adcBuffer[0], sizeof(adcBuffer[0])*adcBufferIndex__);
  Serial.write((byte*)&adcLastTick__, sizeof(adcLastTick__));
  t = micros() - t;
  Serial.write((byte*)&t, sizeof(t));
}

/*
   writeEventListener0
*/
void writeEventListener0() {
  Serial.write((byte*)&eventListener0Index, sizeof(eventListener0Index));
  if (eventListener0Index > 0) Serial.write((byte*)eventListener0Detections, sizeof(eventListener0Detections[0])*eventListener0Index);
  eventListener0Index = 0;
  eventListener0EventDetected = false;
}

/*
   writePelletReleaseStatus
*/
void writePelletReleaseStatus() {
  Serial.write(pelletDropDetected);
  if (pelletDropDetected) pelletCompleteReleaseTicks -= pelletStartReleaseTicks;
  else pelletCompleteReleaseTicks = 0;
  Serial.write((byte*)&pelletCompleteReleaseTicks, sizeof(pelletCompleteReleaseTicks));
  Serial.write((byte*)&pelletNumAttempts, sizeof(pelletNumAttempts));
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
   startEventListener0
*/
void startEventListener0() {
  eventListener0Listening = true;
  eventListener0Index = 0;
  eventListener0StartTicks = ticksSinceStart;
  eventListener0EventDetected = false;
}

/*
   stopEventListener0
*/
void stopEventListener0() {
  eventListener0Listening = false;
  eventListener0EventDetected = false;
}

/*
   startPelletRelease
*/
void startPelletRelease() {
  pelletReleaseInProgress = true;
  pelletDropDetected = false;
  pelletReleaseFailed = false;
  pelletStartReleaseTicks = ticksSinceStart;
  pelletNumAttempts = 0;
  TCNT1  = __compareMatchRegisterTimer1 - 1;  // This resets the timer so that we count from first attempt
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
*/
ISR(INT0_vect) {
  pelletDropDetected = true;
  pelletCompleteReleaseTicks = ticksSinceStart;
  pelletReleaseInProgress = false;
}

/*
  Interrupt service routine triggered at INT1_vect (external interrupt request 1, pin D3)
*/
ISR(INT1_vect) {
  if (eventListener0Listening && eventListener0Index < __eventListenersMaxEvents) eventListener0Detections[eventListener0Index++] = ticksSinceStart;
  eventListener0EventDetected = true;
}

/*
    Interrupt service routine triggered at TIMER1_COMPA_vect
*/
ISR(TIMER1_COMPA_vect) {
  if (pelletReleaseInProgress && !pelletDropDetected && pelletNumAttempts < __pelletMaxAttempts) {
    digitalWrite(__rewardOutputPin0, HIGH);
    digitalWrite(__rewardOutputPin0, LOW);
    pelletNumAttempts++;
  } else if (!pelletDropDetected) {
    pelletReleaseFailed = true;
  }
}

/*
   Interrupt service routine triggered at TIMER2_COMPA_vect
*/
ISR(TIMER2_COMPA_vect) {
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

