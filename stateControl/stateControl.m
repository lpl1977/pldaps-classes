classdef stateControl < handle
    %stateControl track and update task state
    %
    %  To create a new state control object:
    %  obj = stateControl
    %
    %  To setup for the next trial with name value pairs
    %  obj.trialSetup([name],[value],...)
    %
    %  To check if this is the first entry into the state; if so, this
    %  returns true and records the entry time:
    %  obj.firstEntryIntoState
    %
    %  To transition to the next task state with name value pairs; at the
    %  very least the 'state' property must be set.  Options included
    %  'state' and 'duration'.
    %  obj.nextState([name],[value],...)
    %
    %  To capture the exit time of the last state
    %  obj.trialCleanUpandSave(p)
    %
    %  To get the current task state:
    %  obj.state
    %
    %  To get how much time has elapsed since state entry
    %  obj.elapsedTime
    %
    %  To get time remaining
    %  obj.remainingTime
    %
    %  To use task state duration as a conditional, use remainingTime, for
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
    
    properties (SetAccess = private)
        state
        duration
        entryTime
    end
    
    properties (Dependent = true)
        firstEntryIntoState
        elapsedTime
        remainingTime
    end
        
    methods        
        
        %  trialSetup
        %
        %  Initialize for new trial
        function obj = trialSetup(obj)
            obj.duration = Inf;
        end
        
        %  trialCleanUpandSave
        %
        %  Capture the exit time of the last state.
        function trialCleanUpandSave(obj)
            obj.entryTime = GetSecs;
        end
        
        %  nextState
        %
        %  Specify the next state.
        function nextState(obj,varargin)
            obj.duration = Inf;
            obj.entryTime = [];
            
            %  Set remaining properties from user input
            for i=1:2:nargin-1
                if(isprop(obj,varargin{i}))
                    obj.(varargin{i}) = varargin{i+1};
                end
            end
        end   
        
        %  Get method for firstEntryIntoState
        %
        %  Check for initial state entry and start timers if so
        function outcome = get.firstEntryIntoState(obj)            
            outcome = isempty(obj.entryTime);
            if(outcome)
                obj.entryTime = GetSecs;
            end
        end
        
        %  Get method for elapsedTime
        function outcome = get.elapsedTime(obj)
            if(isempty(obj.entryTime))
                outcome = 0;
            else
                outcome = GetSecs - obj.entryTime;
            end
        end
        
        %  Get method for remainingTime
        function outcome = get.remainingTime(obj)
            outcome = obj.duration - obj.elapsedTime;
        end
    end
end
