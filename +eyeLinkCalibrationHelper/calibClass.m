classdef calibClass < handle
    %calibClass object for handling data needed for EyeLink calibration
    %
    %  To create a calibClass object with name value pairs
    %  obj = calibClass(p,[name],[value],...)
    
    
    %
    %  Some notes on using EyeLink with PLDAPS
    %
    %  Default fields for eyeLinkControlStruct
    %
    %           buffereventlength: 30
    %          buffersamplelength: 31
    %          calibration_matrix: []
    %                collectQueue: 1
    %          custom_calibration: 0
    %     custom_calibrationScale: 0.2500
    %                     saveEDF: 0
    %                         use: 1
    %                 useAsEyepos: 1
    %                  useRawData: 0
    %
    %  During initial object creation, obj.eyeLinkControlStruct should be
    %  set to p.trial.eyelink.setup, which had been set with
    %  EyeLinkInitDefaults.
    %
    %  Automatic sequencing appears to be activated by default, but settings on
    %  the EyeLink GUI side can override this.
    %
    %  Determine which eye is being used and then set the eyeIdx accordingly
    %  p.trial.eyelink.EYE_USED and p.trial.eyelink.eyeIdx (1 for left, 2 for
    %  right).
    %
    %  Events ocurring with EyeLink during frame cycle
    %
    %  Start trial prepare
    %  get time from eyelink and tell eyelink that a new trial is starting
    %
    %  Start trial
    %  prepare fields in p.trial.eyelink which will be filled later like
    %  samples and events and the drained flag, clears the buffer (read queued
    %  data until there is nothing left in the buffer).
    %
    %  Get queue  -- get data from eyelink
    %  Iterate as long as we have not drained the buffer.  Capture the samples
    %  and the events with Eyelink('GetQueuedData'); p.trial.eyelink.samples is
    %  an array with columns corresponding to time samples.  The number of rows
    %  is large.  This contains both the raw data and also the calibrated data.
    %  In addition, it contains data for both eyes.  In this function, we need
    %  p.trial.eyelink.eyeIdx to determine which row we will pull from to get
    %  the eye position.  If you somehow messed this up, for example by
    %  switching eyes during the experiment, looks like we could be hosed.  We
    %  stash the eye position in p.trial.eyeX and p.trial.eyeY for later use by
    %  the overlay to show the eye position.
    %
    %  eyeX and eyeY are in pixels.
    
    properties
        autoReward = true;
        reward = 0.1;
        
        eyeLinkControlStruct
        
        windowPtr
        bgColor
        
        targetOn = true;
        
        dotWidth = 20;
        dotColor = [1 0 0];
        dotPeriod = 2;
        dotPulseWidth = 1;

        rewardFunction
        
        ifi
        flipTime = GetSecs;
        timeStamp = GetSecs;
        
        displayFunction = @(obj) eyeLinkCalibrationHelper.simpleDot(obj);
        
        currentXpos
        currentYpos
    end
    
    methods
        
        %  Class constructor
        function obj = calibClass(p,varargin)
            
            %  Set eyeLink control structure
            obj.eyeLinkControlStruct = p.trial.eyelink.setup;
            obj.bgColor = p.trial.display.bgColor;
            obj.ifi = p.trial.display.ifi;
            obj.windowPtr = p.trial.display.ptr;
            
            %  Set properties based on defaults, if any.
            if(isField(p.trial,'eyeLinkCalibrationHelper'))
                defaultFields = fieldnames(p.trial.eyeLinkCalibrationHelper);
                for i=1:numel(defaultFields)
                    if(isprop(obj,defaultFields{i}))
                        obj.(defaultFields{i}) = p.trial.eyeLinkCalibrationHelper.(defaultFields{i});
                    end
                end
            end
            
            %  Set properties based on arguments
            for i=1:2:nargin-1
                if(isprop(obj,varargin{i}))
                    obj.(varargin{i}) = varargin{i+1};
                else
                    error('%s is not a valid property of %s',varargin{i},mfilename('class'));
                end
            end    
            
            obj.rewardFunction = @(amount) p.functionHandles.rewardManagerObj.give(amount);
        end
        
        %  clearTarget
        %
        %  function to clear screen at next refresh
        function clearTarget(obj)
            Screen('FillRect',obj.windowPtr,obj.bgColor);
            obj.flipTime = Screen('Flip',obj.windowPtr, obj.flipTime + 0.5*obj.ifi);
        end
        
        %  drawTarget
        %
        %  function to draw target at next refresh
        function drawTarget(obj)
            if(ischar(obj.displayFunction))
                obj.(obj.displayFunction);
            else
                feval(obj.displayFunction,obj);
            end
            obj.flipTime = Screen('Flip',obj.windowPtr,obj.flipTime + 0.5*obj.ifi);
        end
    end
end