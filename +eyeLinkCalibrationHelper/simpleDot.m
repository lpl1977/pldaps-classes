function simpleDot(calibObj)
%eyeLinkCalibrationHelper.simpleDot

Screen('FillRect',calibObj.windowPtr,calibObj.bgColor);
Screen('DrawDots',calibObj.windowPtr,...
    [calibObj.currentXpos; calibObj.currentYpos],...
    calibObj.dotWidth,calibObj.dotColor,[],2);
end

