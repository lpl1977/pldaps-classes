function calibrationInterface(obj)
%  eyeLinkManager.calibrationInterface
%
%  May be used for calibration, validation and drift correction.  Control
%  operation from the EyeLink GUI.
%
%  Lee Lovejoy
%  July 23, 2017
%  ll2833@columbia.edu

%  Some notes on using EyeLink with PLDAPS
%
%  Default fields for eyeLinkControlStructure
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
%  During initial object creation, obj.eyeLinkControlStructure should be
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

%  Make sure EyeLink is connected; if not, return.
if(Eyelink('IsConnected')~=1)
    fprintf('WARNING:  EyeLink is not connected!\n');
    fprintf('****************************************************************\n');
    return;
else
    fprintf('Please use EyeLink GUI to proceed.\n');
    fprintf('When finished press any key to exit.\n');
end

%  Start in Camera Setup, where we can control operation from EyeLink GUI
Eyelink('StartSetup');
Eyelink('WaitForModeReady',obj.eyeLinkControlStructure.waitformodereadytime);

%  Proceed once user has all keys released
KbWait([],1);

%  From setup mode wait for user to use EyeLink GUI to start calibration
while bitand(Eyelink('CurrentMode'),obj.eyeLinkControlStructure.IN_SETUP_MODE);
    
    %  Check mode on EyeLink side
    currentMode = Eyelink('CurrentMode');
    if bitand(currentMode,obj.eyeLinkControlStructure.IN_TARGET_MODE)
        
        %  User has switched into a target mode:  calibration, drift check,
        %  or validation.
        
        %  Prepare target state control
        obj.targetOn = false;
        obj.currentXpos = Inf;
        obj.currentYpos = Inf;
        
        %  Start with a clear screen.
        obj.clearTarget;
        
        %  Loop as long as EyeLink is in a target mode.  Each iteration is a
        %  frame cycle.  Press any key to quit
        while bitand(Eyelink('CurrentMode'),obj.eyeLinkControlStructure.IN_TARGET_MODE)
            
            %  Query Eyelink for current target location and visibility
            [vis,nextXpos,nextYpos] = Eyelink('TargetCheck');
            if(~obj.targetOn && vis)
                
                %  If the target is not visible but should be, turn it on
                obj.targetOn = true;
                fprintf('\tDisplay target at %d %d\n',nextXpos,nextYpos);
            elseif((obj.targetOn && ~vis) || obj.currentXpos~=nextXpos || obj.currentYpos~=nextYpos)
                
                %  If the target is currently visible but should not be, or if the
                %  position of the target has changed, turn it off and update the
                %  position.
                obj.targetOn = false;
                
                %  Target only moves after position has been acquired, so reward
                %  him here.
                if(obj.autoReward)
                    feval(obj.rewardFunction,obj.reward);
                    fprintf('\tFixation accepted and reward given.\n');
                else
                    fprintf('\tFixation accepted.\n');
                end
            end
            obj.currentXpos = nextXpos;
            obj.currentYpos = nextYpos;
            obj.drawTarget;            
        end
        
        %  We're done, so make sure the screen is blank
        obj.clearTarget;
        
        %  Only reach the point upon departure from target mode.  Normally
        %  this would be because of returning to the setup screen, so most
        %  likely we will continue iterating through the main loop        
    end
    
    if(KbCheck)
        break;
    end
end
fprintf('Done with EyeLink interface and resuming EyeLink record mode.\n');
fprintf('****************************************************************\n');
Eyelink('StartRecording');
Eyelink('WaitForModeReady',obj.eyeLinkControlStructure.waitformodereadytime);
end