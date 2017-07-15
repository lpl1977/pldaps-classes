function displayTargets(p)
%  eyeLinkManager.displayTargets Display targets for EyeLink
%
%  eyeLinkManager.displayTargets(p)
%
%  Called from inside eyeLinkManager.interface
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

%  Loop as long as EyeLink in a target mode.  Each iteration is a
%  frame cycle.  Press any key to quit
fprintf('Entered target mode.\n');
while bitand(Eyelink('CurrentMode'),p.trial.eyelink.setup.IN_TARGET_MODE)

    %  Query Eyelink for current target location
    [vis,nextXpos,nextYpos] = Eyelink('TargetCheck');
    
    %  Control display on target position and visibility
    if((targetVisible && ~vis) || currentXpos~=nextXpos || currentYpos~=nextYpos)
        
        %  If the target is currently visible but should not be, or is in
        %  the wrong spot, clear the screen.  We only reach this the first
        %  iteration after the target moves or becomes invisible.
        targetVisible = false;
        currentXpos = nextXpos;
        currentYpos = nextYpos;
        lastFlipTime = clearTarget(lastFlipTime);                    
        
        %  Here would be a reasonable place to add a reward.
        if(p.functionHandles.eyeLinkManagerObj.autoreward)
            pds.behavior.reward.give(p,p.functionHandles.eyeLinkManagerObj.reward);
            pds.audio.play(p,'reward',1);
        end
    elseif(~targetVisible && vis)        
        
        %  If the target is not currently visible but should be, draw it.
        %  We only reach this the first iteration after the target becomes
        %  visible.
        currentXpos = nextXpos;
        currentYpos = nextYpos;
        targetVisible = true;
        lastFlipTime = drawTarget(lastFlipTime);        
    elseif(targetVisible && vis)
        
        %  If the target is currently visible and should be, draw it into
        %  the frame again (need to do this so that we keep time).
        lastFlipTime = drawTarget(lastFlipTime);
    end
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