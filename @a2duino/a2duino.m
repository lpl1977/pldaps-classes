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
        serialObj
        adcSchedule
    end
    
    properties (SetAccess=private)
        commandQueue = cell(0);
        resultBuffer = struct([]);
        commandLock = false;
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
        commandStartPelletRelease = uint8(42);
        commandSetAdcSchedule = uint8(50);
        
        %  Constants related to Arduino communication
        bytesSentAtStart = 18;
    end
    
    properties (SetAccess=private,Hidden)
        adcScheduleRunning
        eventListener0Listening
        
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
        function obj = a2duino(verbose,varargin)
            
            %  Create ADC schedule
            obj.adcSchedule = a2duino.adcSchedule(varargin{:});
            
            %  Create serial port object
            obj.serialObj = a2duino.serial(varargin{:});
            
            %  Open serial port connection
            fopen(obj.serialObj.connection);
            
            %  Read Arduino settings from serial
            while (obj.serialObj.connection.BytesAvailable < obj.bytesSentAtStart)
            end
            obj.compareMatchRegister1 = fread(obj.serialObj.connection,1,'int16');
            obj.prescalar1 = fread(obj.serialObj.connection,1,'int16');
            obj.compareMatchRegister2 = fread(obj.serialObj.connection,1,'int16');
            obj.prescalar2 = fread(obj.serialObj.connection,1,'int16');
            obj.adcMaxBufferSize = fread(obj.serialObj.connection,1,'int16');
            obj.adcNumChannels = fread(obj.serialObj.connection,1,'int16');
            obj.rewardNumPins = fread(obj.serialObj.connection,1,'int16');
            obj.eventNumPins = fread(obj.serialObj.connection,1,'int16');
            obj.eventMaxNumDetections = fread(obj.serialObj.connection,1,'int16');
            
            %  Determine sampling rates and smallest time step
            obj.clockRate1 = 16e6 / (obj.prescalar1*(obj.compareMatchRegister1 + 1));
            obj.clockRate2 = 16e6 / (obj.prescalar2*(obj.compareMatchRegister2 + 1));
            obj.timeStep = 1000/obj.clockRate2;
            
            if(verbose)
                fprintf('Opened serial port %s at %d Bd\n\n',obj.serialObj.portName,obj.serialObj.baud);
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
        
        %  Class destructor
        function delete(obj)
            obj.close;
        end
        
        %  Close the connection
        function close(obj)
            fclose(obj.serialObj.connection);
        end
        
        %  Check connection
        function output = connectionOpen(obj)
            output = strcmpi(obj.serialObj.connection.Status,'open');
        end
        
        %  Set ADC schedule
        function obj = setAdcSchedule(obj)
            
            %  Stop ADC schedule before changing
            if(obj.adcScheduleRunning)
                obj.stopAdcSchedule;
            end
            
            %  Set schedule based on validity
            obj.adcSchedule.samplingRate = obj.clockRate2;
            obj.adcSchedule.numScheduledChannels = min(obj.adcNumChannels,length(obj.adcSchedule.scheduledChannelList));
            obj.adcSchedule.scheduledChannelList = obj.adcSchedule.scheduledChannelList(1:obj.adcSchedule.numScheduledChannels);
            obj.adcSchedule.numScheduledFrames = min(obj.adcSchedule.numScheduledFrames,floor(obj.adcMaxBufferSize / obj.adcSchedule.numScheduledChannels));
            obj.adcSchedule.numRequestedFrames = min(obj.adcSchedule.numRequestedFrames,obj.adcSchedule.numScheduledFrames);
            obj.adcBufferSize = obj.adcSchedule.numScheduledFrames*obj.adcSchedule.numScheduledChannels;
            
            %  Write adjusted schedule
            fwrite(obj.serialObj.connection,obj.commandSetAdcSchedule);
            fwrite(obj.serialObj.connection,uint8(8+obj.adcSchedule.numScheduledChannels));
            fwrite(obj.serialObj.connection,uint8(obj.adcSchedule.numScheduledChannels));
            fwrite(obj.serialObj.connection,uint8(obj.adcSchedule.scheduledChannelList-1));
            fwrite(obj.serialObj.connection,typecast(int16(obj.adcSchedule.numScheduledFrames),'uint8'));
            fwrite(obj.serialObj.connection,typecast(int16(obj.adcSchedule.onsetDelay),'uint8'));
            fwrite(obj.serialObj.connection,uint8(obj.adcSchedule.useRingBuffer));
            fwrite(obj.serialObj.connection,typecast(int16(obj.adcSchedule.numRequestedFrames),'uint8'));
        end
        
        %  Start ADC schedule
        function obj = startAdcSchedule(obj)
            obj.adcScheduleRunning = true;
            fwrite(obj.serialObj.connection,obj.commandStartAdcSchedule);
        end
        
        %  Stop ADC schedule
        function obj = stopAdcSchedule(obj)
            obj.adcScheduleRunning = false;
            fwrite(obj.serialObj.connection,obj.commandStopAdcSchedule);
        end
        
        %  Start Event listener
        function obj = startEventListener0(obj)
            obj.eventListener0Listening = true;
            fwrite(obj.serialObj.connection,obj.commandStartEventListener0);
        end
        
        %  Stop Event Listener
        function obj = stopEventListener0(obj)
            obj.eventListener0Listening = false;
            fwrite(obj.serialObj.connection,obj.commandStopEventListener0);
        end
        
        %  Start Pellet Release
        function obj = startPelletRelease(obj,varargin)
            maxReleaseAttempts = varargin{1};
            fwrite(obj.serialObj.connection,obj.commandStartPelletRelease);
            fwrite(obj.serialObj.connection,uint8(1));
            fwrite(obj.serialObj.connection,uint8(maxReleaseAttempts));
        end
        
        %  Get time since start (msec)
        function output = getTicksSinceStart(obj,varargin)
            if(nargin==1 && ~obj.commandLock)
                fwrite(obj.serialObj.connection,obj.commandGetTicksSinceStart);
                controlFlag = 'receive';
            else
                controlFlag = varargin{1};
            end
            switch controlFlag
                case 'send'
                    fwrite(obj.serialObj.connection,obj.commandGetTicksSinceStart);
                case 'receive'
                    if(~obj.commandLock)
                        output = fread(obj.serialObj.connection,1,'uint32')*obj.timeStep;
                    end
            end
        end
        
        %  Get ADC voltages
        function output = getAdcVoltages(obj,varargin)
            if(nargin==1 && ~obj.commandLock)
                fwrite(obj.serialObj.connection,obj.commandGetAdcVoltages);
                controlFlag = 'receive';
            else
                controlFlag = varargin{1};
            end
            switch controlFlag
                case 'send'
                    fwrite(obj.serialObj.connection,obj.commandGetAdcVoltages);
                case 'receive'
                    if(~obj.commandLock)
                        num = fread(obj.serialObj.connection,1,'int16');
                        output = fread(obj.serialObj.connection,num,'int16');
                    end
            end
        end
        
        %  Get ADC Schedule
        function output = getAdcSchedule(obj,varargin)
            if(nargin==1 && ~obj.commandLock)
                fwrite(obj.serialObj.connection,obj.commandGetAdcSchedule);
                controlFlag = 'receive';
            else
                controlFlag = varargin{1};
            end
            switch controlFlag
                case 'send'
                    fwrite(obj.serialObj.connection,obj.commandGetAdcSchedule);
                case 'receive'
                    if(~obj.commandLock)
                        output.numScheduledChannels = fread(obj.serialObj.connection,1,'int16');
                        output.scheduledChannelList = fread(obj.serialObj.connection,output.numScheduledChannels,'int16')+1;
                        output.numScheduledFrames = fread(obj.serialObj.connection,1,'int16');
                        output.onsetDelay = fread(obj.serialObj.connection,1,'int16');
                        output.useRingBuffer = fread(obj.serialObj.connection,1,'uint8');
                        output.numRequestedFrames = fread(obj.serialObj.connection,1,'int16');
                    end
            end
        end
        
        %  Get ADC Buffer
        function output = getAdcBuffer(obj,varargin)
            if(nargin==1 && ~obj.commandLock)
                fwrite(obj.serialObj.connection,obj.commandGetAdcBuffer);
                controlFlag = 'receive';
            else
                controlFlag = varargin{1};
            end
            switch controlFlag
                case 'send'
                    fwrite(obj.serialObj.connection,obj.commandGetAdcBuffer);
                case 'receive'
                    if(~obj.commandLock)
                        output.bufferData = fread(obj.serialObj.connection,[obj.adcSchedule.numScheduledChannels,obj.adcSchedule.numRequestedFrames],'int16');
                        output.timeStamp = fread(obj.serialObj.connection,1,'uint32');
                        output.writeTime = fread(obj.serialObj.connection,1,'uint32');
                        output.timeStamp = 1000*output.timeStamp/obj.adcSchedule.samplingRate;
                        output.timeBase = (output.timeStamp+(1-obj.adcSchedule.numRequestedFrames:1:0)*1000/obj.adcSchedule.samplingRate);
                        if(~isempty(obj.lastSampleTime))
                            ix = output.timeBase > obj.lastSampleTime;
                            output.timeBase = output.timeBase(ix);
                            output.bufferData = output.bufferData(:,ix);
                            output.underFlow = obj.adcSchedule.numScheduledFrames - sum(ix);
                            output.overFlow = max(0,output.timeStamp - obj.lastSampleTime - obj.adcSchedule.numScheduledFrames);
                        end
                        obj.lastSampleTime = output.timeStamp;
                    end
            end
        end
        
        %  Get ADC status
        function output = getAdcStatus(obj,varargin)
            if(nargin==1 && ~obj.commandLock)
                fwrite(obj.serialObj.connection,obj.commandGetAdcStatus);
                controlFlag = 'receive';
            else
                controlFlag = varargin{1};
            end
            switch controlFlag
                case 'send'
                    fwrite(obj.serialObj.connection,obj.commandGetAdcStatus);
                case 'receive'
                    if(~obj.commandLock)
                        output = fread(obj.serialObj.connection,1,'uint8');
                        obj.adcScheduleRunning = ~~output;
                    end
            end
        end
        
        %  Get Event Listner
        function output = getEventListener0(obj,varargin)
            if(nargin==1 && ~obj.commandLock)
                fwrite(obj.serialObj.connection,obj.commandGetEventListener0);
                controlFlag = 'receive';
            else
                controlFlag = varargin{1};
            end
            switch controlFlag
                case 'send'
                    fwrite(obj.serialObj.connection,obj.commandGetEventListener0);
                case 'receive'
                    if(~obj.commandLock)
                        output.numEvents = fread(obj.serialObj.connection,1,'int16');
                        if(output.numEvents > 0)
                            output.events = fread(obj.serialObj.connection,output.numEvents,'uint32');
                        else
                            output.events = [];
                        end
                    end
            end
        end
        
        %  Get pellet release status
        function output = getPelletReleaseStatus(obj,varargin)
            if(nargin==1 && ~obj.commandLock)
                fwrite(obj.serialObj.connection,obj.commandGetPelletReleaseStatus);
                controlFlag = 'receive';
            else
                controlFlag = varargin{1};
            end
            switch controlFlag
                case 'send'
                    fwrite(obj.serialObj.connection,obj.commandGetPelletReleaseStatus);
                case 'receive'
                    if(~obj.commandLock)
                        output.releaseInProgress = fread(obj.serialObj.connection,1,'uint8');
                        output.releaseDetected = fread(obj.serialObj.connection,1,'uint8');
                        output.releaseTime = fread(obj.serialObj.connection,1,'uint32');
                        output.numAttempts = fread(obj.serialObj.connection,1,'int16');
                    end
            end
        end
        
        %  Add command to command queue
        function obj = addCommand(obj,varargin)
            if(ismethod(obj,varargin{1}))
                obj.commandQueue{end+1} = varargin{1};
            else
                error('%s is not a valid method of a2duino and cannot be added to command queue',varargin{1});
            end
        end
        
        %  Run commands in command queue
        function obj = sendCommands(obj)
            flushinput(obj.serialObj.connection);
            for i=1:length(obj.commandQueue)
                feval(obj.commandQueue{i},obj,'send');
            end
            obj.commandLock = true;
        end
        
        %  Retreive output from command queue
        function obj = retrieveOutput(obj)
            obj.commandLock = false;
            obj.resultBuffer = struct([]);
            for i=1:length(obj.commandQueue)
                obj.resultBuffer(i).command = obj.commandQueue{i};
                obj.resultBuffer(i).output = feval(obj.commandQueue{i},obj,'receive');
            end
            obj.commandQueue = cell(0);
        end
        
        %  Recover output from result buffer
        %  This will return all outputs corresponding to the specified
        %  command; if there is none, then output will be empty
        function output = recoverResult(obj,varargin)
            output = [obj.resultBuffer(strcmp(varargin{1},{obj.resultBuffer.command})).output];
        end
    end
end