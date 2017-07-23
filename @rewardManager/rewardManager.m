classdef rewardManager
    %rewardManager Manage reward delivery between systems
    
    properties
        systemName
        systemParams
        giveFunc
        defaultReward
    end
    
    methods
        
        %  Class constructor
        function obj = rewardManager(varargin)
            
            %  Set properties
            for i=1:2:nargin-1
                if(isprop(obj,varargin{i}))
                    obj.(varargin{i}) = varargin{i+1};
                else
                    error('%s is not a valid property of %s',varargin{i},mfilename('class'));
                end
            end
            
            %  Set give function
            if(isempty(obj.giveFunc))
                switch lower(obj.systemName)
                    case 'datapixx'
                        obj.systemParams = cell2struct(obj.systemParams(2:2:end),obj.systemParams(1:2:end),2);
                        obj.giveFunc = @(releaseDuration) rewardManager.datapixxDefault(...
                            obj.systemParams.channel,obj.systemParams.ttlAmp,obj.systemParams.sampleRate,releaseDuration);
                end
            end
        end
        
        %  Function to give reward
        function give(obj,varargin)
            feval(obj.giveFunc,varargin{:});
        end
    end
    
    methods (Static)
        
        %  Default delivery function for datapixx (fluid)
        function datapixxDefault(channel,ttlAmp,sampleRate,releaseDuration)
            bufferData = [ttlAmp*ones(1,round(releaseDuration*sampleRate)) 0];
            maxFrames = length(bufferData);
            if(~Datapixx('IsReady'))
                Datapixx('Open');
            end
            Datapixx('WriteDacBuffer',bufferData,0,channel);
            Datapixx('SetDacSchedule',0,sampleRate,maxFrames,channel);
            Datapixx StartDacSchedule;
            Datapixx RegWrRd;
        end
    end
end

