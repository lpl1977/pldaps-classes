classdef stateControl < handle
    %stateControl control common state variables for tasks
    %
    %  To create a new state control object:
    %  obj = stateControl
    %
    %  To change the default start state and duration for all trials:
    %  obj = stateControl('initialState',[name],'initialDuration',[duration]);
    %
    %  To setup for the next trial with name value pairs
    %  obj.trialSetup([name],[value],...)
    %
    %  To check if this is the first entry into the state; if so, this
    %  returns true and records the entry time:
    %  obj.firstEntryIntoState
    %
    %  To transition to the next state with name value pairs; at the very
    %  least the 'state' property must be set.  Options included 'state'
    %  and 'duration'.
    %  obj.nextState([name],[value],...)
    %
    %  To capture the state log into p.trial at the end of the trial
    %  obj.trialCleanUpandSave(p)
    %
    %  To get the current state:
    %  obj.currentState
    %
    %  To determine how much time has elapsed
    %  obj.elapsedTime
    %
    %  To get time remaining
    %  obj.remainingTime
    %
    %  To use state duration as a conditional, use remainingTime, for
    %  example if(obj.remainingTime <= 0) ...
    %
    %  NB:  depends on psychophysics toolbox function GetSecs
    %
    %  Lee Lovejoy
    %  January 2017
    %  ll2833@columbia.edu
    %
    %  November 2017 revise for modular trial function; export data to
    %  p.trial so will be in p.data.
    
    properties (Hidden, SetAccess = private)
        initialState = 'start';
        initialDuration = Inf;
        stateLog
        numStates
    end
    
    properties (Dependent = true)
        elapsedTime
        remainingTime
        currentState
    end
        
    methods
        
        %  Class constructor
        function obj = stateControl(varargin)            
            
            %  Set properties from user input
            for i=1:2:nargin-1
                if(isprop(obj,varargin{i}))
                    obj.(varargin{i}) = varargin{i+1};
                end
            end
        end
        
        %  trialSetup
        %
        %  Initialize for new trial
        function obj = trialSetup(obj,varargin)                        
            obj.numStates = 1;
            if(nargin>1)
                obj.stateLog = {stateControl.prototype(varargin{:})};
            else
                obj.stateLog = {stateControl.prototype('state',obj.initialState,'duration',obj.initialDuration)};
            end
        end
        
        %  trialCleanUpandSave
        %
        %  Convert stateLog into an array of structs
        function output = trialCleanUpandSave(obj,p)
            output = cell(size(obj.stateLog));
            for i=1:numel(output)
                output{i} = obj.stateLog{i}.struct;
            end        
            if(nargin>1)
                p.trial.stateTransitionLog = output;
            end
        end
        
        %  firstEntryIntoState
        %
        %  Check for initial state entry and start timers if so
        function outcome = firstEntryIntoState(obj)            
            outcome = isempty(obj.stateLog{obj.numStates}.entryTime);
            if(outcome)
                obj.stateLog{obj.numStates}.entryTime = GetSecs;
            end
        end
        
        %  nextState
        %
        %  Create the next state to trigger transition.  Arguments passed
        %  directly to prototype class constructor.
        function nextState(obj,varargin)
            obj.numStates = obj.numStates+1;
            obj.stateLog{obj.numStates} = stateControl.prototype(varargin{:});
        end
        
        %  Get method for current state
        function outcome = get.currentState(obj)
            outcome = obj.stateLog{obj.numStates}.state;
        end
        
        %  Get method for elapsedTime
        function outcome = get.elapsedTime(obj)
            outcome = GetSecs - obj.stateLog{obj.numStates}.entryTime;
        end
        
        %  Get method for remainingTime
        function outcome = get.remainingTime(obj)
            outcome = obj.stateLog{obj.numStates}.duration - obj.elapsedTime;
        end
    end
end
