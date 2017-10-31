function settings = module(p,state)
%analogStick.module state dependent steps for analogStick object
%
%  Return configuration settings for module:
%  settings = analogStick.module
%
%  This is a PLDAPS module for the openreception branch.  This initializes
%  and updates analogStick object.
%
%  NB:  Generally speaking we want to update analog stick data prior to any
%  frame drawing or other updates, but after the default trial function has
%  been called (at order 0) because that is when digitized data is captured
%  from Datapixx.  Therefore set order so that updates occurr after default
%  module but prior to the custom trial function events (at order NaN).
%
%  Lee Lovejoy
%  October 2017
%  ll2833@columbia.edu

if(nargin==0)
    
    %  Generate the settings structure for the module
    stateFunction.order = 0;
    stateFunction.acceptsLocationInput = false;
    stateFunction.name = 'analogStick.module';
    requestedStates = {'experimentPostOpenScreen' 'frameUpdate'};
    moduleName = 'moduleAnalogStick';
    settings.(moduleName).stateFunction = stateFunction;
    settings.(moduleName).use = true;
    settings.(moduleName).requestedStates = requestedStates;
    
    %  Settings structure for analogStick
    temp = properties('analogStick');
    settings.analogStick = cell2struct(cell(size(temp)),temp,1);
else
    
    %  Execute the state dependent components
    switch state
        case p.trial.pldaps.trialStates.experimentPostOpenScreen
            moduleName = 'moduleAnalogStick';
            fprintf('****************************************************************\n');
            fprintf('%s will be called at priority %d\n',moduleName,p.trial.(moduleName).stateFunction.order);
            
            %  Initialize the analog stick object
            inputArgs = [fieldnames(p.trial.analogStick) struct2cell(p.trial.analogStick)]';
            p.functionHandles.analogStickObj = analogStick(p,inputArgs{:});
            fprintf('Initialized analog stick:\n');
            p.functionHandles.analogStickObj.disp;
            fprintf('****************************************************************\n');
            
        case p.trial.pldaps.trialStates.frameUpdate
            
            %  Update the analog stick object
            p.functionHandles.analogStickObj.update(p);
    end
end
end
