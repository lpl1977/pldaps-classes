function settings = settings
%eyeLinkCalibrationHelper.settings
%
%  Return configuration settings for eyeLinkCalibration Helper interface:
%  settings = eyeLinkCalibrationHelper.settings
%
%  Lee Lovejoy
%  November 2017
%  ll2833@columbia.edu

%  Settings for EyeLink calibration helper
temp = properties('eyeLinkCalibrationHelper');
settings.eyeLinkCalibrationHelper = cell2struct(cell(size(temp)),temp,1);
