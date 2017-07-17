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
                        obj.giveFunc = @rewardManager.datapixx;
                        obj.systemParams = cell2struct(obj.systemParams(2:2:end),obj.systemParams(1:2:end),2);
                end
            end
        end
        
        %  Function to give reward
        function give(obj,varargin)
            feval(obj.giveFunc,obj,varargin{:});
        end
        
        %  Default delivery function for datapixx (fluid)
        function obj = datapixx(obj,varargin)
            releaseDuration = varargin{1};
            bufferData = [obj.systemParams.ttlAmp*ones(1,round(releaseDuration*obj.systemParams.sampleRate)) 0];
            maxFrames = length(bufferData);
            if(~Datapixx('IsReady'))
                Datapixx('Open');
            end
            Datapixx('WriteDacBuffer',bufferData,0,obj.systemParams.channel);
            Datapixx('SetDacSchedule',0,obj.systemParams.sampleRate,maxFrames,obj.systemParams.channel);
            Datapixx StartDacSchedule;
            Datapixx RegWrRd;
        end
    end
    
end

