classdef trialManager < handle
    %trialManager trial tracking, correction loops, and run termination
    %
    %  Lee Lovejoy
    %  ll2833@columbia.edu
    %  February 2017
    
    %  Some notes:
    %
    %  trialNumber is the current trial number and is an index into the
    %  index list (trialIndex) which references elements of the
    %  p.conditions cell array
    %
    %  trialTokens is a cell array the same length as trialIndex; each
    %  element is a list of specifiers for that trial.  The list is
    %  searchable to obtain an element of trialIndex
    
    properties %(Access = protected)
        trialNumber = 0;
        repetitionNumber = 0;
        trialIndex
        trialList
        maxTrials
        maxRepetitions
        trialTokens
        repeatProbability = 0;
    end
    
    methods
        
        %  Class constructor
        function obj = trialManager(varargin)
            for i=1:2:nargin
                obj.(varargin{i}) = varargin{i+1};
            end
            obj.trialIndex = 1;            
            obj.trialList = 1:obj.maxTrials;
        end     
                
        %  indexTrialSpecifiers
        %
        %  given a cell array of conditions, create a cell array of trial
        %  specifiers which we can search to obtain a trial index
        function obj = indexTrialSpecifiers(obj,conditions,specifiers)
                obj.trialTokens = cell(length(conditions),1);
                for i=1:length(obj.trialTokens)
                    obj.trialTokens{i} = cell(length(specifiers),1);
                    for j=1:length(specifiers)
                        obj.trialTokens{i}{j} = conditions{i}.(specifiers{j});
                    end
                end
            end
        
        %  update
        %
        %  Update the trial and block count
        function update(obj,varargin)
            obj.trialNumber = obj.trialNumber + 1;
            obj.trialIndex = obj.trialList(obj.trialNumber+1);
            obj.repetitionNumber = 0;
        end
        
        %  checkRunTerminationCriteria
        %
        %  Compare trial count to run termination criteria; if met, then
        %  set outcome to the pldaps termination code for
        %  p.trial.pldaps.quit:
        %  0--continue
        %  1--pause
        %  2--quit
        function outcome = checkRunTerminationCriteria(obj)
            if(obj.trialNumber==obj.maxTrials)
                outcome = 2;
            else
                outcome = 0;
            end
        end
        
        %  shuffleRemainingTrials
        %
        %  shuffle remaining trials; if additional inputs
        %  provided then shuffle trials specified
        function shuffleRemainingTrials(obj,varargin)
            
            %  Determine which trials to shuffle
            ix = 1:obj.maxTrials >= obj.trialNumber;
            
            %  Apply shuffle to selected trials
            obj.trialList(ix) = Shuffle(obj.trialList(ix));
            
            %  We are starting new
            obj.repetitionNumber = 0;
            obj.trialIndex = obj.trialList(obj.trialNumber + 1);
        end 

        %  repeatTrial
        %
        %  Return boolean indicating whether or not to repeat triail
        function outcome = repeatTrial(obj)
            outcome = logical(binornd(1,obj.repeatProbability)) && obj.repetitionNumber < obj.maxRepetitions;
            if(outcome)
                obj.repetitionNumber = obj.repetitionNumber + 1;
            end
        end
        
    end
    
end

