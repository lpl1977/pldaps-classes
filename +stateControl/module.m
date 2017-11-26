function settings = module(p,state)
%stateControl.module state dependent steps for stateControl object
%
%  Return configuration settings for module:
%  settings = stateControl.module
%
%  This is a PLDAPS module for the openreception branch.  This initializes
%  and updates stateControl object.
%
%  This module should be called prior to the default trial function (which
%  normally would be at 0).  That way the default trial function's
%  CleanUpandSave routine will capture the state log into the data
%  structure.
%
%  Lee Lovejoy
%  November 2017
%  ll2833@columbia.edu

if(nargin==0)

    %  Generate the settings structure for the module
    moduleName = 'moduleStateControl';
    settings.(moduleName).use = true;
    settings.(moduleName).stateFunction.name = 'stateControl.module';
    settings.(moduleName).stateFunction.order = 0;
    settings.(moduleName).stateFunction.acceptsLocationInput = false;
    settings.(moduleName).stateFunction.requestedStates = struct('experimentPostOpenScreen',true,'trialSetup',true,'trialCleanUpandSave',true);    
else
    
    %  Execute the state dependent components    
    switch state
        case p.trial.pldaps.trialStates.experimentPostOpenScreen

            %  Initialize the state control object  
            p.functionHandles.stateControlObj = stateControl;          
            fprintf('****************************************************************\n');
            fprintf('Initialized state control module\n');
            fprintf('****************************************************************\n');            
            
        case p.trial.pldaps.trialStates.trialCleanUpandSave
            
            %  Record the frame transition log
            p.functionHandles.stateControlObj.trialCleanUpandSave;
    end
end

end

