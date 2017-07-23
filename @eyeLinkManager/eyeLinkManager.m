classdef eyeLinkManager < handle
    %eyeLinkManager helper for EyeLink and calibration
    
    properties
        autoReward = true;
        reward = 0.1;
        eyeLinkControlStructure

        windowPtr
        bgColor
        
        targetProperties
        targetOn = false;
        
        rewardFunction
        
        ifi
        flipTime
        timeStamp = GetSecs;
        
        displayFunction
        currentXpos
        currentYpos
        
        xPos = [959 115 115 959 1803 959 115 1803 1803];
        yPos = [539 539 91 987 987 91 987 539 91];  
    end
    
    methods
        
        %  Class constructor
        function obj = eyeLinkManager(varargin)
            
            %  Set properties
            for i=1:2:nargin-1
                if(isprop(obj,varargin{i}))
                    obj.(varargin{i}) = varargin{i+1};
                else
                    error('%s is not a valid property of %s',varargin{i},mfilename('class'));
                end
            end
        end
        
        interface(obj)
        displayTargets(obj)
        fixationTrainer(obj)
        
        %  clearTarget
        %
        %  function to clear screen at next refresh
        function clearTarget(obj)
            Screen('FillRect',obj.windowPtr,obj.bgColor);
            if(isempty(obj.flipTime))
                obj.flipTime = Screen('Flip',obj.windowPtr);
            else
                obj.flipTime = Screen('Flip',obj.windowPtr, obj.flipTime + 0.5*obj.ifi);
            end
        end
        
        %  drawTarget
        %
        %  function to draw target at next refresh
        
        function drawTarget(obj,varargin)
            if(ischar(obj.displayFunction))
                obj.(obj.displayFunction);
            else
                feval(obj.displayFunction,varargin{:});
            end
            if(isempty(obj.flipTime))
                obj.flipTime = Screen('Flip',obj.windowPtr);
            else
                obj.flipTime = Screen('Flip',obj.windowPtr,obj.flipTime + 0.5*obj.ifi);
            end
        end
        
        %  Default drawing functions
        
        %  simpleDot
        %
        %  Displays a dot
        function simpleDot(obj)
            Screen('FillRect',obj.windowPtr,obj.bgColor);
            if(obj.targetOn)
                Screen('DrawDots',obj.windowPtr,...
                    [obj.currentXpos; obj.currentYpos],...
                    obj.targetProperties.dotWidth,obj.targetProperties.dotColor,[],2);
            end
        end
        
        function flickeringDot(obj)
            if(obj.targetOn && GetSecs - obj.timeStamp >= obj.targetProperties.pulseWidth)
                obj.targetOn = false;
            elseif(GetSecs - obj.timeStamp >= obj.targetProperties.period)
                obj.targetOn = true;
                obj.timeStamp = GetSecs;
            end            
            obj.simpleDot;            
        end
    end
end