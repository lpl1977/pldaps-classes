classdef a2duino < handle
    %a2duino class for communication with Arduino running a DAQ sketch
    %
    %  Lee Lovejoy
    %  ll2833@columbia.edu
    %  January 2017
    
    %  NB regarding Arduino / MATLAB data type conversion:
    %
    %  char:  8-bit (1-byte) -128 to 127, signed integer; int8
    %  byte:  8-bit (1-byte) 0 to 255, an unsigned integer; uint8
    %  int: 16-bit (2-byte) -32,768 to 32,767; int16 / short
    %  word (aka unsigned int): 16-bit (2-byte) 0 to 65,535; uint16 / ushort
    %  long: 32-bit (4-byte) -2,147,483,648 to 2,147,483,647; int32 / int
    %  unsigned long:  32-bit (4-byte) 0 to 4,294,967,295; uint32 / uint
            
    %  Current pin assignments:
    %  A00 - joystick X position
    %  A01 - joystick Y position
    %  A02 - range finder
    %  A03
    %  A04
    %  A05
    %  D00 - TX
    %  D01 - RX
    %  D02 - External interrupt (pellet dispenser)
    %  D03 - External interrupt (event detection)
    %  D04
    %  D05
    %  D06
    %  D07
    %  D08
    %  D09
    %  D10
    %  D11
    %  D12 - TTL output:  pellet dispenser
    %  D13 - TTL output:  debug pin
    
    properties
        %  serial port object
        serialObj
        
        adcSchedule = struct(...
            'samplingRate',[],...
            'numScheduledChannels',1,...
            'scheduledChannelList',1,...
            'numScheduledFrames',1000,...
            'onsetDelay',0,...
            'useRingBuffer',true);
    end
    
    properties (Constant,Hidden)
        
        %  Define single byte (0-255) codes for communicating with Arduino.
        %  All commands with a 1 in the least significant bit (i.e. odd)
        %  will be executed immediately upon receipt, whereas commands
        %  without a 1 in the lsb are accompanied by arguments
        commandGetTicksSinceStart = uint8(1);
        commandGetAdcVoltages = uint8(3);
        commandGetAdcSchedule = uint8(7);
        commandGetAdcStatus = uint8(9);
        commandGetAdcBuffer = uint8(11);
        commandGetEventListener0 = uint8(13);
        commandGetPelletReleaseStatus = uint8(17);
        commandStartAdcSchedule = uint8(21);
        commandStopAdcSchedule = uint8(23);
        commandStartEventListener0 = uint8(25);
        commandStopEventListener0 = uint8(27);
        commandStartPelletRelease = uint8(41);
        commandSetAdcSchedule = uint8(50);
        
        %  Constants related to Arduino communication
        portName = '/dev/ttyACM0';
        baud = 115200;
        inputBufferSize = 2048;
        bytesSentAtStart = 18;
    end
    
    properties (Hidden)
        compareMatchRegister1
        prescalar1
        clockRate1
        compareMatchRegister2
        prescalar2
        clockRate2
        adcNumChannels
        adcMaxBufferSize
        adcBufferSize
        rewardNumPins
        eventNumPins
        eventMaxNumDetections
        timeStep
        lastSampleTime
    end
    
    methods
        %  Class constructor
        function obj = a2duino(varargin)
            
            %  Create and open serial port object
            obj.serialObj = serial(obj.portName,'baud',obj.baud);
            obj.serialObj.InputBufferSize = obj.inputBufferSize;
            fopen(obj.serialObj);

            %  Read Arduino settings from serial
            while (obj.serialObj.BytesAvailable < obj.bytesSentAtStart)
            end
            obj.compareMatchRegister1 = fread(obj.serialObj,1,'int16');
            obj.prescalar1 = fread(obj.serialObj,1,'int16');
            obj.compareMatchRegister2 = fread(obj.serialObj,1,'int16');
            obj.prescalar2 = fread(obj.serialObj,1,'int16');
            obj.adcMaxBufferSize = fread(obj.serialObj,1,'int16');
            obj.adcNumChannels = fread(obj.serialObj,1,'int16');
            obj.rewardNumPins = fread(obj.serialObj,1,'int16');
            obj.eventNumPins = fread(obj.serialObj,1,'int16');
            obj.eventMaxNumDetections = fread(obj.serialObj,1,'int16');
            
            %  Determine sampling rates and smallest time step
            obj.clockRate1 = 16e6 / (obj.prescalar1*(obj.compareMatchRegister1 + 1));
            obj.clockRate2 = 16e6 / (obj.prescalar2*(obj.compareMatchRegister2 + 1));
            obj.timeStep = 1000/obj.clockRate2;
            
            if(nargin>0)
                option = varargin{1};
                if(strcmpi(option,'verbose'))
                    fprintf('Opened serial port %s at %d Bd\n\n',obj.portName,obj.baud);
                    fprintf('            compare match register1:  %d\n',obj.compareMatchRegister1);
                    fprintf('                         prescalar1:  %d\n',obj.prescalar1);
                    fprintf('                        clock1 rate:  %d Hz\n',obj.clockRate1);
                    fprintf('            compare match register2:  %d\n',obj.compareMatchRegister2);
                    fprintf('                         prescalar2:  %d\n',obj.prescalar2);
                    fprintf('                        clock2 rate:  %d Hz\n',obj.clockRate2);
                    fprintf('            maximum ADC buffer size:  %d samples of type int16\n',obj.adcMaxBufferSize);
                    fprintf('             number of ADC channels:  %d\n',obj.adcNumChannels);
                    fprintf('      number of reward control pins:  %d\n',obj.rewardNumPins);
                    fprintf('     number of event detection pins:  %d\n',obj.eventNumPins);
                    fprintf('maximum number of detections stored:  %d\n',obj.eventMaxNumDetections);
                end
            end
        end
        
        %  Class destructor
        function delete(obj)
            fclose(obj.serialObj);
        end
        
        %  Close the connection
        function close(obj)
            fclose(obj.serialObj);
        end
        
        %  Get time since start (msec)
        function output = getTimeSinceStart(obj)
            fwrite(obj.serialObj,obj.commandGetTicksSinceStart);
            output = fread(obj.serialObj,1,'uint32')*obj.timeStep;
        end
        
        %  Get ADC voltages
        function output = getAdcVoltages(obj)
            fwrite(obj.serialObj,obj.commandGetAdcVoltages);
            num = fread(obj.serialObj,1,'int16');
            output = fread(obj.serialObj,num,'int16');
        end
        
        %  Get ADC Schedule
        function output = getAdcSchedule(obj)
            fwrite(obj.serialObj,obj.commandGetAdcSchedule);
            output.numScheduledChannels = fread(obj.serialObj,1,'int16');
            output.scheduledChannelList = fread(obj.serialObj,output.numScheduledChannels,'int16')+1;
            output.numScheduledFrames = fread(obj.serialObj,1,'int16');
            output.onsetDelay = fread(obj.serialObj,1,'int16');
            output.useRingBuffer = fread(obj.serialObj,1,'uint8');
        end
        
        %  Get ADC Buffer
        function output = getAdcBuffer(obj)
            fwrite(obj.serialObj,obj.commandGetAdcBuffer);            
            output.bufferData = fread(obj.serialObj,[obj.adcSchedule.numScheduledChannels,obj.adcSchedule.numScheduledFrames],'int16');
            output.timeStamp = fread(obj.serialObj,1,'uint32');
            output.writeTime = fread(obj.serialObj,1,'uint32');
            output.timeStamp = 1000*output.timeStamp/obj.adcSchedule.samplingRate;
            output.timeBase = (output.timeStamp+(1-obj.adcSchedule.numScheduledFrames:1:0)*1000/obj.adcSchedule.samplingRate);
            if(~isempty(obj.lastSampleTime))
                ix = output.timeBase > obj.lastSampleTime;
                output.timeBase = output.timeBase(ix);
                output.bufferData = output.bufferData(:,ix);
                output.underFlow = obj.adcSchedule.numScheduledFrames - sum(ix);
                output.overFlow = max(0,output.timeStamp - obj.lastSampleTime - obj.adcSchedule.numScheduledFrames);
            end
            obj.lastSampleTime = output.timeStamp;
        end
        
        %  Get ADC status
        function output = getAdcStatus(obj)
            fwrite(obj.serialObj,obj.commandGetAdcStatus);
            output = fread(obj.serialObj,1,'uint8');
        end
        
        %  Get Event Listner
        function output = getEventListener0(obj)
            fwrite(obj.serialObj,obj.commandGetEventListener0);
            numEvents = fread(obj.serialObj,1,'int16');
            if(numEvents > 0)
                output = fread(obj.serialObj,numEvents,'uint32');
            else
                output = [];
            end
        end
        
        %  Get pellet release status
        function output = getPelletReleaseStatus(obj)
            fwrite(obj.serialObj,obj.commandGetPelletReleaseStatus);
            output.dropMade = fread(obj.serialObj,1,'uint8');
            output.dropTime = fread(obj.serialObj,1,'uint32');
            output.numAttempts = fread(obj.serialObj,1,'int16');
        end
        
        %  Set ADC schedule
        function obj = setAdcSchedule(obj)
            obj.adcSchedule.samplingRate = obj.clockRate2;
            obj.adcSchedule.numScheduledChannels = min(obj.adcNumChannels,length(obj.adcSchedule.scheduledChannelList));
            obj.adcSchedule.scheduledChannelList = obj.adcSchedule.scheduledChannelList(1:obj.adcSchedule.numScheduledChannels);
            obj.adcSchedule.numScheduledFrames = min(obj.adcSchedule.numScheduledFrames,floor(obj.adcMaxBufferSize / obj.adcSchedule.numScheduledChannels));
            obj.adcBufferSize = obj.adcSchedule.numScheduledFrames*obj.adcSchedule.numScheduledChannels;            
            fwrite(obj.serialObj,obj.commandSetAdcSchedule);
            fwrite(obj.serialObj,uint8(6+obj.adcSchedule.numScheduledChannels));
            fwrite(obj.serialObj,uint8(obj.adcSchedule.numScheduledChannels));
            fwrite(obj.serialObj,uint8(obj.adcSchedule.scheduledChannelList-1));
            fwrite(obj.serialObj,typecast(int16(obj.adcSchedule.numScheduledFrames),'uint8'));
            fwrite(obj.serialObj,typecast(int16(obj.adcSchedule.onsetDelay),'uint8'));
            fwrite(obj.serialObj,uint8(obj.adcSchedule.useRingBuffer));
        end
        
        %  Start ADC schedule
        function obj = startAdcSchedule(obj)
            fwrite(obj.serialObj,obj.commandStartAdcSchedule);
        end
        
        %  Stop ADC schedule
        function obj = stopAdcSchedule(obj)
            fwrite(obj.serialObj,obj.commandStopAdcSchedule);
        end
        
        %  Start Event listener
        function obj = startEventListener0(obj)
            fwrite(obj.serialObj,obj.commandStartEventListener0);
        end
        
        %  Stop Event Listener
        function obj = stopEventlistener0(obj)
            fwrite(obj.serialObj,obj.commandStopEventListener0);
        end
        
        %  Start Pellet Release
        function obj = startPelletRelease(obj)
            fwrite(obj.serialObj,obj.commandStartPelletRelease);
        end        
    end
end
