function p = setEventsChannelMapping(p)
%a2duino.setEventsChannelMapping
%
%  p.trial.a2duino.setEventsChannelMapping generates the subscripted
%  references to write a2duino event data into the events field.  Note that
%  there is only one events channel in a2duino at this time
%
%  Lee Lovejoy
%  February 2017
%  ll2833@columbia.edu

S.type='.';
S.subs='trial';
if ischar(p.trial.a2duino.events.channelMapping)
    p.trial.a2duino.events.channelMapping={p.trial.a2duino.events.channelMapping};
end
map=p.trial.a2duino.events.channelMapping;
p.trial.a2duino.events.channelMappingSubs=cell(size(map));

levels=textscan(map{1},'%s','delimiter','.');
levels=levels{1};
if map{1}(1)=='.'
    levels(1)=[];
end
Snew=repmat(S,[1 length(levels)]);
[Snew.subs]=deal(levels{:});
S2=S;
S2.type='()';
S2.subs={1,1};
p.trial.a2duino.events.channelMappingSubs{1}=[S Snew S2];

p.trial.a2duino.events.dataSampleCount=0;
end