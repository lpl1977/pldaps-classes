function p = getEventsData(p)
%a2duino.getEventsData get events data from the a2duino result buffer
%
% p = a2duino.getEventsData(p)
%
%  Shamelessly (and lovingly) copied from pds.datapixx.adc.getData
%
%  Lee Lovejoy
%  February 2017
%  ll2833@columbia.edu

%  Recover events data from the result buffer
a2duinoOutput = p.functionHandles.a2duinoObj.recoverResult('readEventListener0');

%  a2duinoOutput may be an array of structures if there were multiple calls
%  to getEventListener0 before the results were retrieved, so iterate
for i=1:length(a2duinoOutput)
    if(a2duinoOutput(i).numEvents > 0)
        starti=p.trial.a2duino.events.dataSampleCount+1;
        endi=p.trial.a2duino.events.dataSampleCount+a2duinoOutput(i).numEvents;
        inds=starti:endi;
        p.trial.a2duino.events.dataSampleCount=endi;
        iSub = p.trial.a2duino.events.channelMappingSubs{1};
        iSub(end).subs{2}=inds;
        p=subsasgn(p,iSub,a2duinoOutput(i).events);
    end
end
end
