function calibrationInterface(obj)
%  eyeLinkManager.calibrationInterface
%
%  May be used for calibration, validation and drift correction.  Control
%  operation from the EyeLink GUI.
%
%  Lee Lovejoy
%  July 23, 2017
%  ll2833@columbia.edu

%  Make sure EyeLink is connected; if not, return.
if(Eyelink('IsConnected')~=1)
    fprintf('WARNING:  EyeLink is not connected!\n');
    fprintf('****************************************************************\n');
    return;
else
    fprintf('Calibration interface:  use EyeLink GUI to proceed.\n');
    fprintf('NOTE:  placing EyeLink in record mode will quit this interface.\n');
end

%  Start in Camera Setup, where we can control operation from EyeLink GUI
Eyelink('StartSetup');
Eyelink('WaitForModeReady',obj.eyeLinkControlStructure.waitformodereadytime);

%  Proceed once user has all keys released
KbWait([],1);
ListenChar(2);

%  Start with a clear screen.
obj.clearTarget;

%  From setup mode wait for user to use EyeLink GUI to start calibration
keyName = [];
while(~strcmpi(keyName,'q') && bitand(Eyelink('CurrentMode'),obj.eyeLinkControlStructure.IN_SETUP_MODE))
    
    %  Check mode on EyeLink side
    if(bitand(Eyelink('CurrentMode'),obj.eyeLinkControlStructure.IN_TARGET_MODE))
        
        %  User has switched into a target mode:  calibration, drift check,
        %  or validation.
        
        %  Prepare target state control
        obj.currentXpos = Inf;
        obj.currentYpos = Inf;        
        
        %  Loop as long as EyeLink is in a target mode.  Each iteration of
        %  this while loop is a frame cycle.
        targetOnScreen = false;
        obj.currentXpos = [];
        obj.currentYpos = [];
        while(bitand(Eyelink('CurrentMode'),obj.eyeLinkControlStructure.IN_TARGET_MODE))
            
            %  Query Eyelink for current target location and visibility
            [makeTargetVisible,nextXpos,nextYpos] = Eyelink('TargetCheck');
            if(~targetOnScreen && makeTargetVisible)
                
                %  If the target is not visible but should be, turn it on
                targetOnScreen = true;
                fprintf('\tDisplay target %d %d... ',nextXpos,nextYpos);
            elseif((targetOnScreen && ~makeTargetVisible) || (~isempty(obj.currentXpos) && (obj.currentXpos~=nextXpos || obj.currentYpos~=nextYpos)))
                
                %  If the target is currently visible but should not be, or if the
                %  position of the target has changed, turn it off and update the
                %  position.
                targetOnScreen = false;
                
                %  Target only moves after position has been acquired, so reward
                %  him here.
                if(obj.autoReward)
                    feval(obj.rewardFunction,obj.reward);
                    fprintf('fixation accepted and reward given.\n');
                else
                    fprintf('fixation accepted.\n');
                end
            end
            obj.currentXpos = nextXpos;
            obj.currentYpos = nextYpos;
            obj.targetOn = obj.targetOn && targetOnScreen;
            if(targetOnScreen)
                obj.drawTarget;
            end
            
            [keyIsDown,~,keyCode] = KbCheck;
            keyName = KbName(keyCode);
            if(keyIsDown && strcmpi(keyName,'q'))
                
                %  We are quitting during target presentation, so switch us
                %  back to setup mode and break this iteration.
                Eyelink('StartSetup');
                Eyelink('WaitForModeReady',obj.eyeLinkControlStructure.waitformodereadytime);
                break;
            end
        end
    end
    
    %  Only reach the point upon departure from target mode.  Normally this
    %  would be because of returning to the setup screen, so most likely we
    %  will continue iterating through the main loop untill you change into
    %  record mode from the EyeLink GUI.
end
ListenChar;
fprintf('\n');
fprintf('Done with EyeLink interface.  Type dbcont to continue.\n');
fprintf('****************************************************************\n');
end