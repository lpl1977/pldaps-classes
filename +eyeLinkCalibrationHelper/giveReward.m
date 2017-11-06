function giveReward(amount)
%eyeLinkCalibrationHelper.giveReward give a reward during the calibration

channel = 3;
ttlAmp = 3;
sampleRate = 1000;

bufferData = [ttlAmp*ones(1,round(amount*sampleRate)) 0];
maxFrames = length(bufferData);
if(~Datapixx('IsReady'))
    Datapixx('Open');
end
Datapixx('WriteDacBuffer',bufferData,0,channel);
Datapixx('SetDacSchedule',0,sampleRate,maxFrames,channel);
Datapixx StartDacSchedule;
Datapixx RegWrRd;
end

