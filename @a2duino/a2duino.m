classdef a2duino < handle
    %a2duino class for communication with Arduino running a DAQ sketch
    %
    %  Lee Lovejoy
    %  ll2833@columbia.edu
    
    %  NB regarding Arduino / MATLAB data type conversion:
    %
    %  char:  8-bit (1-byte) -128 to 127, signed integer; int8
    %  byte:  8-bit (1-byte) 0 to 255, an unsigned integer; uint8
    %  int: 16-bit (2-byte) -32,768 to 32,767; int16 / short
    %  word (aka unsigned int): 16-bit (2-byte) 0 to 65,535; uint16 / ushort
    %  long: 32-bit (4-byte) -2,147,483,648 to 2,147,483,647; int32 / int
    %  unsigned long:  32-bit (4-byte) 0 to 4,294,967,295; uint32 / uint
    
    %  Notes on digital pins supporting interrupts:
    %  ATMega328p (Uno) 2 and 3 only
    %  ATMega32u4 (Leonardo) 0, 1, 2, 3, and 7
    %  ATMega2560 (Mega 2560) 2, 3, 18, 19, 20, 21
    
    %  Current pin assignments (works with Uno):
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
    %  D12 - TTL output:  reward trigger pin
    %  D13 - TTL output:  debug pin
    
    properties (Constant,Hidden)
        
        %  Define single byte (0-255) codes for communicating with Arduino.
        %  All commands with a 1 in the least significant bit (i.e. odd)
        %  will be executed immediately upon receipt, whereas commands
        %  without a 1 in the lsb (even) are accompanied by arguments and
        %  will be executed once all arguments have been acquired.
        commandReadTicksSinceStart = uint8(1);
        commandReadAdcVoltages = uint8(3);
        commandReadAdcSchedule = uint8(7);
        commandReadAdcStatus = uint8(9);
        commandReadAdcBuffer = uint8(11);
        commandReadEventListener = uint8(13);
        commandReadFluidRewardStatus = uint8(15);
        commandReadPelletReleaseStatus = uint8(17);
        commandReadDeviceSettings = uint8(19);
        commandStartAdcSchedule = uint8(21);
        commandStopAdcSchedule = uint8(23);
        commandStartEventListener = uint8(25);
        commandStopEventListener = uint8(27);
        commandStartFluidReward = uint8(40);
        commandStartPelletRelease = uint8(41);
        commandWriteAdcSchedule = uint8(50);
    end
    
    properties (SetAccess=private)
        serialObj
        
        commandQueue = cell(0);
        resultBuffer = struct([]);
        commandLock = false;
        adcScheduleRunning = false;
        eventListenerListening = false;
        
        numScheduledChannels
        scheduledChannelList = [1 2 3];
        numScheduledFrames = 1000;
        onsetDelay = 0;
        useRingBuffer = true;
        numRequestedFrames = 1000;
        adcBufferSize
        
        portName = '/dev/ttyACM0';
        baud = 230400;
        inputBufferSize = 2048;
        
        mcuType
        compareMatchRegister0
        prescalar0
        compareMatchRegister1
        prescalar1
        adcMaxBufferSize
        adcNumChannels
        eventListenerMaxEvents
        maxReleaseAttempts
        
        lastSampleTime
        
        pelletReleaseInProgress = false;
        pelletReleaseDetected = false;        
        
        fluidReleaseInProgress = false;
        fluidReleaseComplete = false;
    end
    
    properties (Dependent)
        samplingRate
        timeStep
        connectionOpen
    end
    
    methods
        
        %
        %  Class constructor
        %
        
        function obj = a2duino(varargin)
            
            %  Update parameter values
            for i=1:2:nargin
                if(any(strcmp(properties(a2duino),varargin{i})))
                    obj.(varargin{i}) = varargin{i+1};
                end
            end
            
            %  Create serial port object
            obj.serialObj = serial(obj.portName,'baud',obj.baud);
            obj.serialObj.InputBufferSize = obj.inputBufferSize;
            fopen(obj.serialObj);
            
            %  Obtain device settings so we can set default ADC schedule
            readDeviceSettings(obj,'receive');
            writeAdcSchedule(obj);
        end
        
        %
        %  Class destructor
        %
        
        function delete(obj)
            obj.close;
        end
        
        %
        %  Close connection
        %
        function close(obj)
            fclose(obj.serialObj);
        end
        
        
        %
        %  Dependent properties
        %
        
        function output = get.samplingRate(obj)
            output = 16e6 / (obj.prescalar0*(obj.compareMatchRegister0 + 1));
        end
        
        function output = get.timeStep(obj)
            output = 1000/obj.samplingRate;
        end
        
        function output = get.connectionOpen(obj)
            output = strcmpi(obj.serialObj.Status,'open');
        end
        
        %
        %  Display settings to command line
        %
        
        function showConnectionSettings(obj)
            fprintf('     serial port:  %s\n',obj.portName);
            fprintf('connection speed:  %d Bd\n',obj.baud);
            fprintf('    input buffer:  %d bytes\n',obj.inputBufferSize);
            if(obj.connectionOpen)
                fprintf('          Status:  open\n');
            else
                fprintf('          Status:  closed\n');
            end
            fprintf('\n');
        end
        
        function showDeviceSettings(obj)
            fprintf('                       MCU type:  %s\n',obj.mcuType);
            fprintf('       compare match register 0:  %d\n',obj.compareMatchRegister0);
            fprintf('                    prescalar 0:  %d\n',obj.prescalar0);
            fprintf('       compare match register 1:  %d\n',obj.compareMatchRegister1);
            fprintf('                    prescalar 1:  %d\n',obj.prescalar1);
            fprintf('             maximum ADC buffer:  %d bytes\n',obj.adcMaxBufferSize);
            fprintf('         number of ADC channels:  %d\n',obj.adcNumChannels);
            fprintf('       maximum event detections:  %d\n',obj.eventListenerMaxEvents);
            fprintf('maximum pellet release attempts:  %d\n',obj.maxReleaseAttempts);
        end
        
        function showAdcSchedule(obj)
            fprintf('number scheduled channels:  %d\n',obj.numScheduledChannels);
            fprintf('   scheduled channel list:  %s\n',sprintf('%d ',obj.scheduledChannelList));
            fprintf('  number scheduled frames:  %d\n',obj.numScheduledFrames);
            fprintf('            sampling rate:  %d Hz\n',obj.samplingRate);
            fprintf('              onset delay:  %d\n',obj.onsetDelay);
            if(obj.useRingBuffer)
                fprintf('          use ring buffer:  true\n');
            else
                fprintf('          use ring buffer:  false\n');
            end
            fprintf('  number requested frames:  %d\n',obj.numRequestedFrames);
            fprintf('               ADC buffer:  %d bytes\n',obj.adcBufferSize);
        end
        
        function output = adcSchedule(obj)
            output.numScheduledChannels = obj.numScheduledChannels;
            output.scheduledChannelList = obj.scheduledChannelList;
            output.numScheduledFrames = obj.numScheduledFrames;
            output.onsetDelay = obj.onsetDelay;
            output.useRingBuffer = obj.useRingBuffer;
            output.numRequestedFrames = obj.numRequestedFrames;
        end
        
        %
        %  Write commands to Arduino
        %
        
        %  writeAdcSchedule
        %
        %  Optional name/value pair arguments to set ADC schedule
        function writeAdcSchedule(obj,varargin)
            
            %  Stop ADC schedule before changing
            if(obj.adcScheduleRunning)
                obj.stopAdcSchedule;
            end
            
            %  Update parameter values if specified
            for i=1:2:length(varargin)
                if(any(strcmp(properties(obj),varargin{i})))
                    obj.(varargin{i}) = varargin{i+1};
                end
            end
            
            %  Set ADC schedule based on validity
            obj.numScheduledChannels = min(obj.adcNumChannels,length(obj.scheduledChannelList));
            obj.scheduledChannelList = obj.scheduledChannelList(1:obj.numScheduledChannels);
            obj.numScheduledFrames = min(obj.numScheduledFrames,floor(obj.adcMaxBufferSize / obj.numScheduledChannels));
            obj.numRequestedFrames = min(obj.numRequestedFrames,obj.numScheduledFrames);
            obj.adcBufferSize = obj.numScheduledFrames*obj.numScheduledChannels;
            
            %  Write schedule to Arduino
            fwrite(obj.serialObj,obj.commandWriteAdcSchedule);
            fwrite(obj.serialObj,uint8(8+obj.numScheduledChannels));
            fwrite(obj.serialObj,uint8(obj.numScheduledChannels));
            fwrite(obj.serialObj,uint8(obj.scheduledChannelList-1));
            fwrite(obj.serialObj,typecast(int16(obj.numScheduledFrames),'uint8'));
            fwrite(obj.serialObj,typecast(int16(obj.onsetDelay),'uint8'));
            fwrite(obj.serialObj,uint8(obj.useRingBuffer));
            fwrite(obj.serialObj,typecast(int16(obj.numRequestedFrames),'uint8'));
        end
        
        %  startAdcSchedule
        function startAdcSchedule(obj)
            if(~obj.adcScheduleRunning)
                obj.adcScheduleRunning = true;
                fwrite(obj.serialObj,obj.commandStartAdcSchedule);
            end
        end
        
        %  stopAdcSchedule
        function stopAdcSchedule(obj)
            if(obj.adcScheduleRunning)
                obj.adcScheduleRunning = false;
                fwrite(obj.serialObj,obj.commandStopAdcSchedule);
            end
        end
        
        %  startEventListener
        function startEventListener(obj)
            if(~obj.eventListenerListening)
                obj.eventListenerListening = true;
                fwrite(obj.serialObj,obj.commandStartEventListener);
            end
        end
        
        %  stopEventListener
        function stopEventListener(obj)
            if(obj.eventListenerListening)
                obj.eventListenerListening = false;
                fwrite(obj.serialObj,obj.commandStopEventListener);
            end
        end
        
        %  startPelleRelease
        %
        %  Returns true if pellet release started
        function output = startPelletRelease(obj)
            output = ~obj.pelletReleaseInProgress;
            if(output)
                fwrite(obj.serialObj,obj.commandStartPelletRelease);
                obj.pelletReleaseInProgress = true;
                obj.pelletReleaseDetected = false;
            end            
        end
        
        %  startFluidReward
        %
        %  Requires reward duration in seconds
        %  Returns true if fluid reward started
        function output = startFluidReward(obj,rewardDuration)
            output = ~obj.fluidReleaseInProgress;
            if(output)
                rewardDuration = 16e6 * (rewardDuration / obj.prescalar1) - 1;
                fwrite(obj.serialObj,obj.commandStartFluidReward);
                fwrite(obj.serialObj,uint8(2));
                fwrite(obj.serialObj,typecast(int16(rewardDuration),'uint8'));
                obj.fluidReleaseInProgress = true;
                obj.fluidReleaseComplete = false;
            end
        end
        
        %  readTicksSinceStart
        %
        %  Optional argument 'send' or 'receive', default 'receive'
        %  Returns number of ticks (typically msec) since connection opened
        function output = readTicksSinceStart(obj,varargin)
            if(nargin==1 && ~obj.commandLock)
                fwrite(obj.serialObj,obj.commandReadTicksSinceStart);
                controlFlag = 'receive';
            else
                controlFlag = varargin{1};
            end
            switch controlFlag
                case 'send'
                    fwrite(obj.serialObj,obj.commandReadTicksSinceStart);
                case 'receive'
                    if(~obj.commandLock)
                        output = fread(obj.serialObj,1,'uint32')*obj.timeStep;
                    end
            end
        end
        
        %  readAdcVoltages
        %
        %  Optional argument 'send' or 'receive', default 'receive'
        %  Returns vector of voltages on ADC        
        function output = readAdcVoltages(obj,varargin)
            if(nargin==1 && ~obj.commandLock)
                fwrite(obj.serialObj,obj.commandReadAdcVoltages);
                controlFlag = 'receive';
            else
                controlFlag = varargin{1};
            end
            switch controlFlag
                case 'send'
                    fwrite(obj.serialObj,obj.commandReadAdcVoltages);
                case 'receive'
                    if(~obj.commandLock)
                        num = fread(obj.serialObj,1,'int16');
                        output = fread(obj.serialObj,num,'int16');
                    end
            end
        end
        
        %  readAdcSchedule
        %
        %  Optional argument 'send' or 'receive', default 'receive'
        %  Returns current ADC schedule on Arduino        
        function output = readAdcSchedule(obj,varargin)
            if(nargin==1 && ~obj.commandLock)
                fwrite(obj.serialObj,obj.commandReadAdcSchedule);
                controlFlag = 'receive';
            else
                controlFlag = varargin{1};
            end
            switch controlFlag
                case 'send'
                    fwrite(obj.serialObj,obj.commandReadAdcSchedule);
                case 'receive'
                    if(~obj.commandLock)
                        output.numScheduledChannels = fread(obj.serialObj,1,'int16');
                        output.scheduledChannelList = fread(obj.serialObj,output.numScheduledChannels,'int16')+1;
                        output.numScheduledFrames = fread(obj.serialObj,1,'int16');
                        output.onsetDelay = fread(obj.serialObj,1,'int16');
                        output.useRingBuffer = fread(obj.serialObj,1,'uint8');
                        output.numRequestedFrames = fread(obj.serialObj,1,'int16');
                    end
            end
        end
        
        %  readAdcBuffer
        %
        %  Optional argument 'send' or 'receive', default 'receive'
        %  Returns contents of ADC buffer        
        function output = readAdcBuffer(obj,varargin)
            if(nargin==1 && ~obj.commandLock)
                fwrite(obj.serialObj,obj.commandReadAdcBuffer);
                controlFlag = 'receive';
            else
                controlFlag = varargin{1};
            end
            switch controlFlag
                case 'send'
                    fwrite(obj.serialObj,obj.commandReadAdcBuffer);
                case 'receive'
                    if(~obj.commandLock)
                        output.bufferData = fread(obj.serialObj,[obj.numScheduledChannels,obj.numRequestedFrames],'int16');
                        output.timeStamp = fread(obj.serialObj,1,'uint32');
                        output.timeStamp = 1000*output.timeStamp/obj.samplingRate;
                        output.timeBase = (output.timeStamp+(1-obj.numRequestedFrames:1:0)*1000/obj.samplingRate);
                        if(~isempty(obj.lastSampleTime))
                            ix = output.timeBase > obj.lastSampleTime;
                            output.timeBase = output.timeBase(ix);
                            output.bufferData = output.bufferData(:,ix);
                            output.underFlow = obj.numScheduledFrames - sum(ix);
                            output.overFlow = max(0,output.timeStamp - obj.lastSampleTime - obj.numScheduledFrames);
                        end
                        obj.lastSampleTime = output.timeStamp;
                    end
            end
        end
        
        %  readAdcStatus
        %
        %  Optional argument 'send' or 'receive', default 'receive'
        %  Returns true if ADC schedule running on Arduino        
        function output = readAdcStatus(obj,varargin)
            if(nargin==1 && ~obj.commandLock)
                fwrite(obj.serialObj,obj.commandReadAdcStatus);
                controlFlag = 'receive';
            else
                controlFlag = varargin{1};
            end
            switch controlFlag
                case 'send'
                    fwrite(obj.serialObj,obj.commandReadAdcStatus);
                case 'receive'
                    if(~obj.commandLock)
                        output = logical(fread(obj.serialObj,1,'uint8'));
                        obj.adcScheduleRunning = output;
                    end
            end
        end
        
        %  readEventListener
        %
        %  Optional argument 'send' or 'receive', default 'receive'
        %  Returns contents of events listener buffer 
        function output = readEventListener(obj,varargin)
            if(nargin==1 && ~obj.commandLock)
                fwrite(obj.serialObj,obj.commandReadEventListener);
                controlFlag = 'receive';
            else
                controlFlag = varargin{1};
            end
            switch controlFlag
                case 'send'
                    fwrite(obj.serialObj,obj.commandReadEventListener);
                case 'receive'
                    if(~obj.commandLock)
                        output.numEvents = fread(obj.serialObj,1,'int16');
                        if(output.numEvents > 0)
                            output.events = fread(obj.serialObj,output.numEvents,'uint32');
                        else
                            output.events = [];
                        end
                    end
            end
        end
        
        %  readFluidRewardStatus
        %
        %  Optional argument 'send' or 'receive', default 'receive'
        function readFluidRewardStatus(obj,varargin)
            if(nargin==1 && ~obj.commandLock)
                fwrite(obj.serialObj,obj.commandReadFluidRewardStatus);
                controlFlag = 'receive';
            else
                controlFlag = varargin{1};
            end
            switch controlFlag
                case 'send'
                    fwrite(obj.serialObj,obj.commandReadFluidRewardStatus);
                case 'receive'
                    if(~obj.commandLock)
                        obj.fluidReleaseComplete = logical(fread(obj.serialObj,1,'uint8'));
                        if(obj.fluidReleaseComplete)
                            obj.fluidReleaseInProgress = false;
                        else
                            obj.fluidReleaseInProgress = true;
                        end
                    end
            end
        end
        
        %  readPelletReleaseStatus
        %
        %  Optional argument 'send' or 'receive', default 'receive'
        %  Returns struct with following fields:
        %  output.releaseTime--time in msec between last release trigger and
        %  successfull release
        %  output.numAttempts--number of release triggers given
        %  output.releaseFailed--true if release failed
        function output = readPelletReleaseStatus(obj,varargin)
            if(nargin==1 && ~obj.commandLock)
                fwrite(obj.serialObj,obj.commandReadPelletReleaseStatus);
                controlFlag = 'receive';
            else
                controlFlag = varargin{1};
            end
            switch controlFlag
                case 'send'
                    fwrite(obj.serialObj,obj.commandReadPelletReleaseStatus);
                case 'receive'
                    if(~obj.commandLock)
                        obj.pelletReleaseDetected = logical(fread(obj.serialObj,1,'uint8'));
                        output.releaseTime = fread(obj.serialObj,1,'uint32');
                        output.numAttempts = fread(obj.serialObj,1,'int16');
                        if(obj.pelletReleaseDetected)
                            obj.pelletReleaseInProgress = false;
                            output.releaseFailed = false;
                        elseif(output.numAttempts == obj.maxReleaseAttempts)
                            obj.pelletReleaseInProgress = false;
                            output.releaseFailed = true;
                        end
                    end
            end
        end
        
        %  readDeviceSettings
        %
        %  Optional argument 'send' or 'receive', default 'receive'
        function readDeviceSettings(obj,varargin)
            if(nargin == 1 && ~obj.commandLock)
                fwrite(obj.serialObj,obj.commandReadDeviceSettings);
                controlFlag = 'receive';
            else
                controlFlag = varargin{1};
            end
            switch controlFlag
                case 'send'
                    fwrite(obj.serialObj,obj.commandReadDeviceSettings);
                case 'receive'
                    if(~obj.commandLock)
                        switch dec2hex(fread(obj.serialObj,1,'int16'),2)
                            case '0F'
                                obj.mcuType = 'ATMega328p';
                            case '87'
                                obj.mcuType = 'ATMega32u4';
                            case '01'
                                obj.mcuType = 'ATMega2560';
                            otherwise
                                obj.mcuType = 'unknown';
                        end
                        obj.compareMatchRegister0 = fread(obj.serialObj,1,'int16');
                        obj.prescalar0 = fread(obj.serialObj,1,'int16');
                        obj.compareMatchRegister1 = fread(obj.serialObj,1,'int16');
                        obj.prescalar1 = fread(obj.serialObj,1,'int16');
                        obj.adcMaxBufferSize = fread(obj.serialObj,1,'int16');
                        obj.adcNumChannels = fread(obj.serialObj,1,'int16');
                        obj.eventListenerMaxEvents = fread(obj.serialObj,1,'int16');
                        obj.maxReleaseAttempts = fread(obj.serialObj,1,'int16');
                    end
            end
        end
        
        
        %
        %  Command queue control functions
        %
        
        %  addCommand
        %
        %  Required argument name of command to add to queue
        function addCommand(obj,varargin)
            if(ismethod(obj,varargin{1}))
                obj.commandQueue{end+1} = varargin{1};
            else
                error('%s is not a valid method of a2duino and cannot be added to command queue',varargin{1});
            end
        end
        
        %  sendCommands
        %
        %  Write command queue to Arduino
        function sendCommands(obj)
            flushinput(obj.serialObj);
            for i=1:length(obj.commandQueue)
                feval(obj.commandQueue{i},obj,'send');
            end
            obj.commandLock = true;
        end
        
        %  retrieveOutput
        %
        %  Read from Arduino the buffer of outputs of the commands in queue
        function retrieveOutput(obj)
            obj.commandLock = false;
            obj.resultBuffer = struct([]);
            for i=1:length(obj.commandQueue)
                obj.resultBuffer(i).command = obj.commandQueue{i};
                obj.resultBuffer(i).output = feval(obj.commandQueue{i},obj,'receive');
            end
            obj.commandQueue = cell(0);
        end
        
        %  recoverResult
        %
        %  Recover the output of a specific command from the retrieved
        %  result buffer
        function output = recoverResult(obj,varargin)
            
            %  Returns all outputs corresponding to the specified command;
            %  if there is none, then output will be empty
            output = [obj.resultBuffer(strcmp(varargin{1},{obj.resultBuffer.command})).output];
        end
    end
    
    %  Following are static methods defined in separate files.
    methods (Static)
        p = getAdcData(p)
        p = getEventsData(p)
        p = setAdcChannelMapping(p)
        p = setEventsChannelMapping(p)
    end
end