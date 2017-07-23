function fixationTrainer(obj)
%  eyeLinkManager.fixationTrainer
%
%  Initial fixationg training
%
%  Lee Lovejoy
%  Jully 22, 2017
%  ll2833@columbia.edu

%  Make sure EyeLink is connected; if not, return.
if(Eyelink('IsConnected')~=1)
    fprintf('WARNING:  EyeLink is not connected!\n');
    fprintf('****************************************************************\n');
    return;
end
fprintf('Please leave EyeLink GUI in Camera Setup mode.\n');
Eyelink('StartSetup');
Eyelink('WaitForModeReady',obj.eyeLinkControlStructure.waitformodereadytime);

%  Proceed once user has all keys released
KbWait([],1);

%  Clear screen and start us at the first target
obj.clearTarget;
targetCounter = 0;
keyName = [];
ListenChar(2);
%  Iterate as long as we are in setup mode
while(bitand(Eyelink('CurrentMode'),obj.eyeLinkControlStructure.IN_SETUP_MODE))
    
    %  keyName is only empty between targets
    if(isempty(keyName))

        %  Update target position
        targetCounter = mod(targetCounter,length(obj.xPos))+1;
        obj.currentXpos = obj.xPos(targetCounter);
        obj.currentYpos = obj.yPos(targetCounter);
        
        %  Echo commands to screen and poll keyboard
        %  Press 'r' to give a Reward
        %  Press 'n' to move target to a new location
        %  Press 't' to Toggle target on or off
        %  Press 'q' to Quit
        fprintf('Display target %d of %d at %d %d.\n',targetCounter,length(obj.xPos),obj.currentXpos,obj.currentYpos);
        fprintf('Available commands:\n');
        fprintf('\ts -- Start showing target\n');
        fprintf('\tr -- give Reward\n');
        fprintf('\tn -- stop showing target and pick the Next location\n');
        fprintf('\tq -- Quit to command line\n');
        [~,keyCode] = KbWait([],3);
        keyName = KbName(keyCode);
        obj.targetOn = false;
    end
    
    %  Pick operation based on keyName
    switch keyName
        case 's'
            obj.targetOn = true;
            keyName = 'c';
        case 'r'
            feval(obj.rewardFunction,obj.reward);
            keyName = 'c';
        case 'n'
            obj.targetOn = false;
            keyName = [];
        case 'q'
            obj.targetOn = false;
            obj.clearTarget;
            break;
        otherwise
            %  Check for keypress
            [keyIsDown,~,keyCode] = KbCheck;
            if(keyIsDown)
                keyName = KbName(keyCode);
            end
    end
    
    %  Draw target    
    obj.drawTarget;    
end
ListenChar;
fprintf('****************************************************************\n');
end
