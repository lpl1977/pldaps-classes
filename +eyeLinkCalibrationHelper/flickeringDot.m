function flickeringDot(calibObj)
%eyeLinkCalibrationHelper.flickeringDot

Screen('FillRect',calibObj.windowPtr,calibObj.bgColor);
if(calibObj.targetOn && GetSecs - calibObj.timeStamp >= calibObj.dotPulseWidth)
    calibObj.targetOn = false;
elseif(GetSecs - calibObj.timeStamp >= calibObj.dotPeriod)
    calibObj.targetOn = true;
    calibObj.timeStamp = GetSecs;
end
if(calibObj.targetOn)
    Screen('DrawDots',calibObj.windowPtr,...
        [calibObj.currentXpos; calibObj.currentYpos],...
        calibObj.dotWidth,calibObj.dotColor,[],2);
end
end

