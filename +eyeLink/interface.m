function interface(p)
%  eyeLink.interface EyeLink interface for PLDAPS
%
%  eyeLink.interface(p)
%
%  Note:  needs pldaps object to have been created, EyeLink connection to
%  be open, and DataPixx connection to be open.  Call from debug command
%  line or from module.  Depends on EyeLink control structure stored as
%  p.trial.eyelink.setup.
%
%  May be used for calibration, validation and drift correction.
%
%  Based on PLDAPS calibration routine.
%
%  Lee Lovejoy
%  June 2017
%  ll2833@columbia.edu

%  Make sure we start in setup mode on the EyeLink side
try
    Eyelink('StartSetup');
catch
    ListenChar(0);
    fprintf('WARNING:  Eyelink is not connected!\n');
    return;
end
Eyelink('WaitForModeReady',p.trial.eyelink.setup.waitformodereadytime);

%  Dump previous keystrokes and wait for user input
ListenChar(2);

%  We will need keyboard input to choose calibration mode; otherwise
%  control from EyeLink GUI.
complete = false;
while ~complete
    fprintf('****************************************************************\n');
    fprintf('Thank you for using this EyeLink Interface\n');
    fprintf('Please choose from the following options:\n');
    fprintf('q--quit to command line or return control to PLDAPS\n');
    fprintf('c--continue with EyeLink calibration, validation, or drift check\n');
    fprintf('****************************************************************\n');
    FlushEvents;
    if(strcmpi(GetChar,'q'))
        fprintf('You have chosen to quit the EyeLink interface.\n');
        fprintf('If you are in debug mode, type dbcont to continue with your session.\n');
        break;
    else
        fprintf('You have chosen to continue with the EyeLink Interface.\n');
        fprintf('Use EyeLink GUI to set options and then select\n');
        fprintf('Calibrate, Validate, or Drift Check from the Camera Setup menu.\n\n');
        fprintf('Once you are satisfied, press any key to contine.\n');
        KbWait([],2);
    end
    
    %  Wait as long as the user has EyeLink in Camera Setup mode.  Once user
    %  enters a mode requiring targets to be displayed, enter the target
    %  display helper.
    currentMode = p.trial.eyelink.setup.IN_SETUP_MODE;
    while bitand(currentMode,p.trial.eyelink.setup.IN_SETUP_MODE)
        currentMode = Eyelink('CurrentMode');
        if bitand(currentMode,p.trial.eyelink.setup.IN_TARGET_MODE)
            eyeLink.displayTargets(p);
            break;
        end
    end
end

%  Now that we've completed using EyeLink, start recording and move on
Eyelink('StartRecording');
Eyelink('WaitForModeReady',p.trial.eyelink.setup.waitformodereadytime);
ListenChar(0);
