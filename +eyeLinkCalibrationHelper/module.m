function settings = module(p,~)
%eyeLinkCalibrationHelper.module state dependent steps for eyeLinkCalibrationHelper
%
%  Return configuration settings for module:
%  settings = eyeLinkCalibrationHelper.module
%
%  This is a PLDAPS module for the openreception branch.  This module
%  supports calibration of EyeLink during the experimentPostOpenScreen
%  state and provides a streamlined interface.
%
%  This module should not require a specific order during the
%  experimentPostOpenScreen state.
%
%  Lee Lovejoy
%  November 2017
%  ll2833@columbia.edu

if(nargin==0)

    %  Generate the settings structure for the module
    moduleName = 'moduleEyeLinkCalibrationHelper';
    settings.(moduleName).use = true;
    settings.(moduleName).stateFunction.name = 'eyeLinkCalibrationHelper.module';
    settings.(moduleName).stateFunction.order = Inf;
    settings.(moduleName).stateFunction.acceptsLocationInput = false;
    settings.(moduleName).stateFunction.requestedStates = struct('experimentPostOpenScreen',true);    
    
    %  Settings for EyeLink calibration helper
    temp = properties('eyeLinkCalibrationHelper');
    settings.eyeLinkCalibrationHelper = cell2struct(cell(size(temp)),temp,1);
    
else
    
    %  Execute the calibration
    
    fprintf('****************************************************************\n');
    fprintf('Starting EyeLink calibration helper\n');
    eyeLinkCalibrationHelper.interface(p);
    fprintf('EyeLink calibration complete\n');
    fprintf('****************************************************************\n');
end

