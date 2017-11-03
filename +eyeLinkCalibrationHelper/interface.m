function interface(p,varargin)
%  eyeLinkCalibrationHelper.interface
%
%  eyeLinkCalibrationHelper.interface(p,[name],[value],...)
%
%  p is the PLDAPS object
%  Name value pairs supersede defaults
%
%  May be used for calibration, validation and drift correction.  Control
%  operation from the EyeLink GUI.  There is no user control from keyboard.
%
%  Lee Lovejoy
%  July 23, 2017
%  ll2833@columbia.edu
%
%  Updates:
%  November 2017 use default settings from an eyeLinkCalibrationHelper
%  structure in p.trial.

%  Make sure EyeLink is connected; if not, return.
if(Eyelink('IsConnected')~=1)
    fprintf('WARNING:  EyeLink is not connected!\n');
    fprintf('****************************************************************\n');
    return;
else
    fprintf('Calibration interface:  use EyeLink GUI to proceed.\n');
    fprintf('Exit setup on EyeLink side to quit this interface.\n');
end

%  Create the calibClass object
calibObj = eyeLinkCalibrationHelper.calibClass(p,varargin{:});

%  Start in Camera Setup, where we can control operation from EyeLink GUI
Eyelink('StartSetup');
Eyelink('WaitForModeReady',calibObj.eyeLinkControlStruct.waitformodereadytime);

%  Start with a clear screen.
calibObj.clearTarget;

%  From setup mode wait for user to use EyeLink GUI to start calibration
while(bitand(Eyelink('CurrentMode'),calibObj.eyeLinkControlStruct.IN_SETUP_MODE))
    
    %  Check mode on EyeLink side
    if(bitand(Eyelink('CurrentMode'),calibObj.eyeLinkControlStruct.IN_TARGET_MODE))
        
        %  User has switched into a target mode:  calibration, drift check,
        %  or validation.
        
        %  Prepare target state control
        calibObj.currentXpos = Inf;
        calibObj.currentYpos = Inf;        
        
        %  Loop as long as EyeLink is in a target mode.  Each iteration of
        %  this while loop is a frame cycle.
        targetOnScreen = false;
        calibObj.currentXpos = [];
        calibObj.currentYpos = [];
        while(bitand(Eyelink('CurrentMode'),calibObj.eyeLinkControlStruct.IN_TARGET_MODE))
            
            %  Query Eyelink for current target location and visibility
            [makeTargetVisible,nextXpos,nextYpos] = Eyelink('TargetCheck');
            if(~targetOnScreen && makeTargetVisible)
                
                %  If the target is not visible but should be, turn it on
                targetOnScreen = true;
                calibObj.timeStamp = GetSecs;
                fprintf('Display target %d %d.\n',nextXpos,nextYpos);
            elseif((targetOnScreen && ~makeTargetVisible) || (~isempty(calibObj.currentXpos) && (calibObj.currentXpos~=nextXpos || calibObj.currentYpos~=nextYpos)))

                %  If the target is currently visible but should not be, or if the
                %  position of the target has changed, turn it off and update the
                %  position.
                targetOnScreen = false;
                
                %  Target only moves after position has been acquired, so reward
                %  him here.
                if(calibObj.autoReward)
                    feval(calibObj.rewardFunction,calibObj.reward);
                    fprintf('\tfixation accepted and reward given.\n');
                else
                    fprintf('\tfixation accepted.\n');
                end
            end
            calibObj.currentXpos = nextXpos;
            calibObj.currentYpos = nextYpos;
            calibObj.targetOn = calibObj.targetOn && targetOnScreen;
            if(targetOnScreen)
                calibObj.drawTarget;
            else
                calibObj.clearTarget;
            end
        end
        
        %  If you're not in target mode, make sure you've cleared the
        %  screen.
        calibObj.clearTarget;
        fprintf('To return to command line, EXIT SETUP on EyeLink.\n');
    end
    
    %  Only reach the point upon departure from target mode.  Normally this
    %  would be because of returning to the setup screen, so most likely we
    %  will continue iterating through the main loop untill you change into
    %  record mode from the EyeLink GUI.
end


fprintf('\n');
fprintf('Done with EyeLink calibration interface.\n');
fprintf('If you called manually during pause, type "dbcont" to continue.\n');
fprintf('If you called by module, PLDAPS should automatically resume.\n');
fprintf('****************************************************************\n');
end