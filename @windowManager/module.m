function settings = module(p,state)
%windowManager.module state dependent steps for windowManager object
%
%  Return configuration settings for module:
%  settings = windowManager.module
%
%  This is a PLDAPS module for the openreception branch.  This initializes
%  and updates windowManager object.
%
%  NB:  Generally speaking, we want to update the window manager after
%  digitized data is captured from Datapixx (order -Inf, when default trial
%  function should be called), after corresponding position sources are
%  updated, but before the custom trial function events (order NaN).
%
%  Lee Lovejoy
%  October 2017
%  ll2833@columbia.edu

if(nargin==0)

    %  Generate the settings structure for the module
    stateFunction.order = 20;
    stateFunction.acceptsLocationInput = false;
    className = mfilename('class');
    fileName = mfilename;
    stateFunction.name = strcat(className,'.',fileName);    
    moduleName = strcat('module',strcat(upper(className(1)),className(2:end)));
    requestedStates = {'experimentPostOpenScreen' 'frameUpdate'};    
    settings.(moduleName).stateFunction = stateFunction;
    settings.(moduleName).use = true;
    settings.(moduleName).requestedStates = requestedStates;
else
    
    %  Execute the state dependent components    
    switch state
        case p.trial.pldaps.trialStates.experimentPostOpenScreen
            className = mfilename('class');
            moduleName = strcat('module',strcat(upper(className(1)),className(2:end)));
            fprintf('****************************************************************\n');
            fprintf('%s will be called at priority %d\n',moduleName,p.trial.(moduleName).stateFunction.order);
            
%             %  Initialize the window manager object
%             p.functionHandles.windowManagerObj = windowManager;
%             fprintf('Initialized window manager\n');
%             fprintf('****************************************************************\n');            
        
        case p.trial.pldaps.trialStates.frameUpdate
        
            %  Update the window manager object
            p.functionHandles.windowManagerObj.update;
    end
end
end
