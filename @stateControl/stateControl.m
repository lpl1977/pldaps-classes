classdef stateControl < handle
    %stateControl control common state variables for PLDAPS trials
    %
    %  NB:  depends on psychophysics toolbox
    %
    %  Lee Lovejoy
    %  January 2017
    %  ll2833@columbia.edu
    
    properties
        currentState
        nextState = 'start';
        stateDuration
    end
    
    properties (Dependent = true)
        timeInState
        timeInStateElapsed
    end
    
    properties (Hidden)
        stateEntryTime
        transitionLog = struct('state',[],'stateEntryTime',[]);
        numTransitions = 0;
    end
    
    methods
        
        %  Class constructor
        function obj = stateControl(varargin)
            if(nargin>0 && ischar(varargin{1}))
                obj.nextState = varargin{1};
            end
        end
        
        %  State transition control
        function outcome = firstEntryIntoState(obj)
            outcome = ~strcmpi(obj.nextState,obj.currentState);
            if(outcome)
                obj.currentState = obj.nextState;
                obj.stateEntryTime = GetSecs;
                obj.numTransitions = obj.numTransitions+1;
                obj.transitionLog.state{obj.numTransitions} = obj.nextState;
                obj.transitionLog.stateEntryTime(obj.numTransitions) = obj.stateEntryTime;
                obj.stateDuration = Inf;
            end
        end
        
        %  Time in state
        function outcome = get.timeInState(obj)
            if(~isempty(obj.stateEntryTime))
                outcome = GetSecs - obj.stateEntryTime;
            else
                outcome = 0;
            end
        end
        
        %  Check if time in state has elapsed
        function outcome = get.timeInStateElapsed(obj)
            outcome = obj.timeInState >= obj.stateDuration;
        end
    end
end
