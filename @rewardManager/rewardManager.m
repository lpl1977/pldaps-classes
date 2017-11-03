classdef rewardManager < handle
    %rewardManager object for managing reward systems
    %
    %  To initialize with property name-value pairs:
    %  obj = rewardManager([property name],[property value],...)
    %
    %  To give reward
    %  obj = rewardManager.give(amount)
    %
    %  Lee Lovejoy
    %  November 2017
    %  ll2833@columbia.edu
    
    properties
        system = 'datapixx';
        channel = 3;
        ttlAmp = 3;
        sampleRate = 1000;
        giveFunc
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
                switch lower(obj.system)
                    case 'datapixx'
                        obj.giveFunc = @(amount) rewardManager.datapixxGive(obj.channel,obj.ttlAmp,obj.sampleRate,amount);
                end
            end
        end
        
        %  Function to give reward
        function give(obj,varargin)
            if(nargin==2)
                feval(obj.giveFunc,varargin{1});
            end
        end
    end
    
    methods (Static)
        
        settings = module(p,state)
        
        %  Functions to give reward
        function datapixxGive(channel,ttlAmp,sampleRate,amount)
            bufferData = [ttlAmp*ones(1,round(amount*sampleRate)) 0];
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

