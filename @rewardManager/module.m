function settings = module(p,state)
%rewardManager.module settings and state dependent steps for rewardManager
%
%  Return configuration settings for module:
%  settings = rewardManager.module
%
%  This is a PLDAPS module for the openreception branch.  This initializes
%  and updates analogStick object.
%
%  Lee Lovejoy
%  October 2017
%  ll2833@columbia.edu

if(nargin==0)
    
    %  Generate the settings structure for the module
    moduleName = 'moduleRewardManager';
    settings.(moduleName).use = true;
    settings.(moduleName).stateFunction.name = 'rewardManager.module';
    settings.(moduleName).stateFunction.order = -Inf;
    settings.(moduleName).stateFunction.acceptsLocationInput = false;
    settings.(moduleName).stateFunction.requestedStates = struct('experimentPostOpenScreen',true);
    
    %  Settings structure for analogStick
    temp = properties('rewardManager');
    settings.rewardManager = cell2struct(cell(size(temp)),temp,1);
else
    
    %  Execute the state dependent components
    switch state
        case p.trial.pldaps.trialStates.experimentPostOpenScreen
            
            %  Initialize the reward manager object
            if(isField(p.trial,'rewardManager'))
                inputArgs = [fieldnames(p.trial.rewardManager) struct2cell(p.trial.rewardManager)]';
                p.functionHandles.rewardManagerObj = rewardManager(p,inputArgs{:});
            else
                p.functionHandles.rewardManagerObj = rewardManager(p);
            end
            fprintf('****************************************************************\n');
            fprintf('Initialized reward manager:\n');
            disp(p.functionHandles.rewardManagerObj);
            fprintf('****************************************************************\n');
    end
end
end

