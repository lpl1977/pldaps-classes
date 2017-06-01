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
    
    properties
        conditions
        trialNumber = 0;
        trialList
        maxTrials
        numDecks = 1;
        trialTokens
        sequentialErrors
        sequentialCorrects
        inCorrectionLoop = false;
        correctionLoopPool
        correctionLoopTokens
        correctionLoopTrialNumber = 0;
        repeat = false;
        maxSequentialErrors
        minSequentialCorrects = 1;
    end
    
    properties (Dependent)
        trialIndex
    end
    
    methods
        
        %  Class constructor
        function obj = trialManager(varargin)
            for i=1:2:nargin
                obj.(varargin{i}) = varargin{i+1};
            end
            
            %  Replicate conditions for the total number of decks
            obj.conditions = repmat(obj.conditions,obj.numDecks,1);
            
            %  Prepare trial list
            obj.maxTrials = numel(obj.conditions);
            obj.trialList = randperm(obj.maxTrials);
            
            %  Prepare correct loop tracking
            obj.sequentialErrors = zeros(obj.maxTrials,1);
        end
        
        %  nextTrial
        %
        %  Give us the next trial please
        function condition = nextTrial(obj)
            if(~obj.inCorrectionLoop)
                if(~obj.repeat)
                    obj.trialNumber = obj.trialNumber + 1;
                else
                    obj.repeat = false;
                end
                condition = obj.conditions{obj.trialIndex};
            else
                obj.correctionLoopTrialNumber = obj.correctionLoopTrialNumber + 1;
                condition = obj.conditions{obj.correctionLoopPool(unidrnd(length(obj.correctionLoopPool)))};
            end
        end
        
        %  Get method for trialIndex
        function value = get.trialIndex(obj)
            value = obj.trialList(obj.trialNumber);
        end
        
        %  tokenize
        %
        %  given a list of specifiers, create a cell array of trial
        %  tokens based on the specifiers
        function obj = tokenize(obj,varargin)
            specifiers = varargin;
            obj.trialTokens = cell(numel(obj.conditions),1);
            for i=1:numel(obj.conditions)
                for j=1:numel(specifiers)
                    if(~isempty(obj.conditions{i}.(specifiers{j})))
                        if(~iscell(obj.conditions{i}.(specifiers{j})))
                            obj.trialTokens{i}{j} = obj.conditions{i}.(specifiers{j});
                        elseif(iscell(obj.conditions{i}.(specifiers{j})))
                            obj.trialTokens{i}{j} = obj.conditions{i}.(specifiers{j}){:};
                        end
                    end
                end
            end
        end        
        
        %  repeatTrial
        %
        %  set repeat flag
        function repeatTrial(obj)
            obj.repeat = true;
        end
        
        %  checkCorrectionLoopEntry
        %
        %  check for correction loop entry conditions
        function checkCorrectionLoopEntry(obj,correct)
            
            if(correct)
                
                %  Reset the sequential error counter
                obj.sequentialErrors(obj.trialIndex) = 0;                
            else
                
                %  Increment the sequential error counter
                obj.sequentialErrors(obj.trialIndex) = obj.sequentialErrors(obj.trialIndex)+1;
                
                %  Match level between current trial's tokens and those in the
                %  tokens list (including the current trial)
                maxLevel = length(obj.trialTokens{obj.trialIndex});
                matchLevels = maxLevel*ones(obj.maxTrials,1);
                for i=1:obj.maxTrials
                    while (matchLevels(i)>0 && ~isempty(setdiff(obj.trialTokens{obj.trialIndex}(1:matchLevels(i)),obj.trialTokens{i})));
                        matchLevels(i) = matchLevels(i)-1;
                    end
                end
                
                %  Check sequential error totals against the max by descending match level
                level = max(matchLevels);
                while(level>0 && ~obj.inCorrectionLoop)
                    ix = matchLevels==level;
                    obj.inCorrectionLoop = sum(obj.sequentialErrors(ix)) >= obj.maxSequentialErrors;
                    level = level-1;
                end
                if(obj.inCorrectionLoop)
                    obj.correctionLoopTokens = obj.trialTokens{obj.trialIndex}(1:level+1);
                    obj.correctionLoopPool = find(ix);
                    obj.sequentialErrors(ix) = 0;
                    obj.sequentialCorrects = 0;
                end
            end
        end
        
        %  checkCorrectionLoopExit
        %
        %  check for correction loop exit conditions
        function checkCorrectionLoopExit(obj,correct)
            
            if(correct)
                obj.sequentialCorrects = obj.sequentialCorrects + 1;
                
                if(obj.sequentialCorrects >= obj.minSequentialCorrects)
                    obj.inCorrectionLoop = false;
                    obj.correctionLoopTrialNumber = 0;
                end
            else
                obj.sequentialCorrects = 0;
            end
        end
        
        %  exitCorrectionLoop
        %
        %  Reset correction loop flag
        function exitCorrectionLoop(obj)
            obj.inCorrectionLoop = false;
            obj.correctionLoopTrialNumber = 0;
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
        %  provided then
        function shuffleRemainingTrials(obj,varargin)
            
            %  Determine which trials to shuffle
            ix = 1:obj.maxTrials >= obj.trialNumber;
            
            %  Apply shuffle to selected trials
            obj.trialList(ix) = Shuffle(obj.trialList(ix));
            
            %  We are starting new
            obj.trialIndex = obj.trialList(obj.trialNumber + 1);
        end
        
    end
    
end

