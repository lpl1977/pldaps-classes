function interface(p)
%  eyeLinkManager.interface EyeLink interface for PLDAPS
%
%  eyeLinkManager.interface(p)
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

%  Some notes on PLDAPS and EyeLink
%
%  Default fields for p.trial.eyelink:
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
%  During initial setup, the following fields are set:
%  p.trial.eyelink.setup is set with EyeLinkInitDefaults
%  p.trial.eyelink.edfFile is set to the date
%  p.trial.eyelink.edfFileLocation is set to pwd (?)
%  p.trial.eyelink.setup.window is set to the display ptr
%  p.trial.eyelink.setup.displayCalResults to 1
%  p.trial.eyelink.setup.eyeimgsize to 50
%  After this, update the defaults
%  Creates and opens the EDF file
%  Feedback is read from Eyelink
%  p.trial.eyelink.trackerversion and .trackermode get set
%  automatic sequencing appears to be activated
%  ** Determine which eye is being used and then set the eyeIdx accordingly
%  p.trial.eyelink.EYE_USED and p.trial.eyelink.eyeIdx (1 for left, 2 for
%  right).
%  Start recording
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
%  iterate as long as we have not drained teh buffer.  Capture the samples
%  and the events with Eyelink('GetQueuedData'); not setting eye
%  p.trial.eyelink.samples is an array with columns corresponding to time
%  samples.  The number of rows is large.  This contains both the raw data
%  and also the calibrated data.  In addition, it contains data for both
%  eyes.  In this function, we need p.trial.eyelink.eyeIdx to determine
%  which row we will pull from to get the eye position.  If you somehow
%  messed this up, for example by switching eyes during the experiment,
%  looks like we could be hosed.  We stash the eye position in p.trial.eyeX
%  and p.trial.eyeY for later use by the overlay to show the eye position.
%  NOTE:  We are looking for eyeX and eyeY to be IN PIXELS.


fprintf('****************************************************************\n');
fprintf('eyeLinkManager\n\n');

%  Make sure EyeLink is connected; if not, return.
if(Eyelink('IsConnected')~=1)
    fprintf('WARNING:  EyeLink is not connected!\n');
    fprintf('****************************************************************\n');
    return;
else
    fprintf('Please use EyeLink GUI to proceed.\n');
    fprintf('When finished press any key to exit.\n');
end

%  Start in Camera Setup
Eyelink('StartSetup');
Eyelink('WaitForModeReady',p.trial.eyelink.setup.waitformodereadytime);

%  Proceed once user has all keys released
KbWait([],1);

%  As long as we are in setup mode, wait for user to input next step.
while bitand(Eyelink('CurrentMode'),p.trial.eyelink.setup.IN_SETUP_MODE);
    
    currentMode = Eyelink('CurrentMode');    
    if bitand(currentMode,p.trial.eyelink.setup.IN_TARGET_MODE)
        
        %  Eyelink is in target mode, so go to target display
        eyeLinkManager.displayTargets(p);
    end
    
    if(KbCheck)
        break;
    end    
end    
Eyelink('StartRecording');
Eyelink( 'WaitForModeReady', p.trial.eyelink.setup.waitformodereadytime );
end