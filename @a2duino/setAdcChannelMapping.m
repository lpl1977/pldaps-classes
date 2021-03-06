function p = setAdcChannelMapping(p)
%a2duino.setAdcChannelMapping
%
%  p.trial.a2duino.setAdcChannelMapping generates the subscripted
%  references to write a2duino analog data into the adc field
%
%  Shamelessly (and lovingly) copied from corresponding pldaps function.
%
%  Lee Lovejoy
%  February 2017
%  ll2833@columbia.edu

S.type='.';
S.subs='trial';
if ischar(p.trial.a2duino.adc.channelMapping)
    p.trial.a2duino.adc.channelMapping={p.trial.a2duino.adc.channelMapping};
end
if length(p.trial.a2duino.adc.channelMapping)==1
    p.trial.a2duino.adc.channelMapping=repmat(p.trial.a2duino.adc.channelMapping,[1,length(p.trial.a2duino.adc.scheduledChannelList)]);
end
maps=unique(p.trial.a2duino.adc.channelMapping);
p.trial.a2duino.adc.channelMappingSubs=cell(size(maps));
p.trial.a2duino.adc.channelMappingChannels=cell(size(maps));
p.trial.a2duino.adc.channelMappingChannelInds=cell(size(maps));
for imap=1:length(maps)
    p.trial.a2duino.adc.channelMappingChannelInds{imap}=strcmp(p.trial.a2duino.adc.channelMapping,maps(imap));
    p.trial.a2duino.adc.channelMappingChannels{imap}=p.trial.a2duino.adc.scheduledChannelList(p.trial.a2duino.adc.channelMappingChannelInds{imap});
    levels=textscan(maps{imap},'%s','delimiter','.');
    levels=levels{1};
    if maps{imap}(1)=='.'
        levels(1)=[];
    end   
    Snew=repmat(S,[1 length(levels)]);
    [Snew.subs]=deal(levels{:});
    S2=S;
    S2.type='()';
    S2.subs={1:length(p.trial.a2duino.adc.channelMappingChannelInds{imap}), 1};
    p.trial.a2duino.adc.channelMappingSubs{imap}=[S Snew S2];
end
p.trial.a2duino.adc.dataSampleCount=0;
end