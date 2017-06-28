function displayTargets(p)
%  eyeLink.displayTargets Display targets for EyeLink
%
%  eyeLink.displayTargets(p)
%
%  Called from inside eyeLink.interface
%
%  Based on PLDAPS calibration routine.
%
%  Lee Lovejoy
%  June 2017
%  ll2833@columbia.edu

%  Whenever EyeLink changes the target position, clear the old target and
%  display a new target.  Option to give monkey a little reward between
%  targets.  Note also that I am timing based on the VBL timestamp so I can
%  use animated stimuli

%  Prepare display timing control
ifi = p.trial.display.ifi;
lastFlipTime = clearTarget;

%  Prepare state control
targetVisible = false;
clearTarget;
currentXpos = Inf;
currentYpos = Inf;

%  Loop as long as user has EyeLink in a target mode.  Each iteration is a
%  frame cycle.  Press any key to quit
fprintf('Display targets.  Press any key to quit.\n');
KbWait([],1);
currentMode = p.trial.eyelink.setup.IN_TARGET_MODE;
while bitand(currentMode,p.trial.eyelink.setup.IN_TARGET_MODE)

    %  Quit if the user presses a key
    if(KbCheck)
        break;
    end
        
    %  Query Eyelink for current target location
    [vis,nextXpos,nextYpos] = Eyelink('TargetCheck');
    
    if((targetVisible && ~vis) || currentXpos~=nextXpos || currentYpos~=nextYpos)
        
        %  If the target is currently visible but should not be, or is in
        %  the wrong spot, clear the screen.
        targetVisible = false;
        currentXpos = nextXpos;
        currentYpos = nextYpos;
        lastFlipTime = clearTarget(lastFlipTime);
        
        %  We only reach this if the target changed position, so
        %  potentially give the monkey a reward here.
        Beeper;
        
    elseif(~targetVisible && vis)
        
        %  If the target is not currently visible but should be, draw it
        currentXpos = nextXpos;
        currentYpos = nextYpos;
        targetVisible = true;
        lastFlipTime = drawTarget(lastFlipTime);
        fprintf('\tDrew target at (%d,%d)\n',currentXpos,currentYpos);
    elseif(~targetVisible && ~vis)
        
        %  If the target is not currently visible and should not be, flip a
        %  clear screen
        lastFlipTime = clearTarget(lastFlipTime);
    else
        
        %  If the target is currently visible and should be, draw it (need
        %  to do this so that we keep time).
        lastFlipTime = drawTarget(lastFlipTime);
    end
    
    %  check current mode
    currentMode = Eyelink('CurrentMode');
end

%  We're done, so make sure the screen is blank
clearTarget;

%  Nested function to clear the display on request
    function flipTime = clearTarget(flipTime)
        %  Make sure there is nothing on the screen
        if p.trial.display.useOverlay==1
            Screen('FillRect',p.trial.display.overlayptr,p.trial.display.bgColor);
        else
            Screen('FillRect',p.trial.display.ptr,p.trial.display.bgColor);
        end
        if(nargin==0)
            flipTime = Screen('Flip',p.trial.display.ptr);
        else
            flipTime = Screen('Flip',p.trial.display.ptr, flipTime + 0.5*ifi);
        end
    end

%  Nested function to draw the target
    function flipTime = drawTarget(flipTime)
        if p.trial.display.useOverlay==1
            tempcolor = dv.trial.display.clut.targetgood;
            Screen('FillRect', p.trial.display.overlayptr,0);
            Screen('Drawdots',p.trial.display.overlayptr,[currentXpos; currentYpos],p.trial.stimulus.fixdotW,tempcolor,[],2);
        else
            tempcolor = [1 0 0]';
            Screen('Drawdots',p.trial.display.ptr,[currentXpos; currentYpos],20,tempcolor,[],2);
        end
        if(nargin==0)
            flipTime = Screen('Flip',p.trial.display.ptr);
        else
            flipTime = Screen('Flip',p.trial.display.ptr,flipTime + 0.5*ifi);
        end
    end
end