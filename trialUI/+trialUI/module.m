function settings = module(p,state)
%trialUI.module state dependent steps for PLDAPS trialUI object
%
%  Return configuration settings for module:
%  settings = trialUI.module
%
%  This is a PLDAPS module for the openreception branch.  This initializes
%  and updates the trialUI object.
%
%  NB:  Generally speaking, we want to poll data from the trial user
%  interface before anything else, so order -Inf.
%
%  Lee Lovejoy
%  December 2017
%  ll2833@columbia.edu

if(nargin==0)

    %  Generate the settings structure for the module
    moduleName = 'moduleTrialUI';
    settings.(moduleName).use = true;
    settings.(moduleName).stateFunction.name = 'trialUI.module';
    settings.(moduleName).stateFunction.order = -Inf;
    settings.(moduleName).stateFunction.acceptsLocationInput = false;
    settings.(moduleName).stateFunction.requestedStates = struct('experimentPostOpenScreen',true,'trialSetup',true,'frameUpdate',true);    
else
    
    %  Execute the state dependent components    
    switch state
        case p.trial.pldaps.trialStates.experimentPostOpenScreen

            %  Initialize the trialUI object  
            %p.functionHandles.trialUIObj = trialUI;          
            fprintf('****************************************************************\n');
            fprintf('Using trialUI module\n');
            fprintf('****************************************************************\n');            
        
        case p.trial.pldaps.trialStates.trialSetup
            
            %  Make sure that keyboard input is available to the UI
            ListenChar(1);
            
        case p.trial.pldaps.trialStates.frameUpdate
        
            %  Update the trial structure from the trialUI object
            %p.functionHandles.trialUIObj.update(p);
    end
end
end
