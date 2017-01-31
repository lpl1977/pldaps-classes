classdef adcSchedule
    %adcSchedule class to hold ADC schedule for a2duino package    
    
    properties
        samplingRate
        numScheduledChannels
        scheduledChannelList = [1 2];
        numScheduledFrames = 1000;
        onsetDelay = 0;
        useRingBuffer = true;
        numRequestedFrames = 1000;        
    end
    
    methods
        %  Class constructor
        function obj = adcSchedule(varargin)
            %  Set properties based on name value pairs
            for i=1:2:nargin
                if(isprop(obj,varargin{i}))
                    obj.(varargin{i}) = varargin{i+1};
                end
            end            
        end
        
        function obj = update(obj,varargin)
            %  Set properties based on name value pairs
            for i=1:2:nargin-1
                if(isprop(obj,varargin{i}))
                    obj.(varargin{i}) = varargin{i+1};
                end
            end                        
        end
    end
    
end

