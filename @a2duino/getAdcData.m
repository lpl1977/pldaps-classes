function p = getAdcData(p)
%a2duino.getAdcData  get adc data from the a2duino result buffer
%
% p = a2duino.getAdcData(p)
%
%  Shamelessly (and lovingly) copied from pds.datapixx.adc.getData
%
%  Lee Lovejoy
%  February 2017
%  ll2833@columbia.edu

%  Recover adc data from the result buffer
a2duinoOutput = p.functionHandles.a2duinoObj.recoverResult('getAdcBuffer');

%  a2duinoOutput may be an array of structures if there were multiple calls
%  to getAdcBuffer before the results were retrieved, so iterate
for i=1:length(a2duinoOutput)
    
    starti=p.trial.a2duino.adc.dataSampleCount+1;
    endi=p.trial.a2duino.adc.dataSampleCount+length(a2duinoOutput(i).timeBase);
    inds=starti:endi;
    p.trial.a2duino.adc.dataSampleCount=endi;
    
    p.trial.a2duino.adc.dataSampleTimes(inds)=a2duinoOutput(i).timeBase;
    
    nMaps=length(p.trial.a2duino.adc.channelMappingChannels);
    for imap=1:nMaps
        iSub = p.trial.a2duino.adc.channelMappingSubs{imap};
        iSub(end).subs{2}=inds;
        
        p=subsasgn(p,iSub,a2duinoOutput(i).bufferData(p.trial.a2duino.adc.channelMappingChannelInds{imap},:));
    end
end
end
