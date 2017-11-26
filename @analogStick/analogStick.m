classdef analogStick < handle
    %analogStick object for accessing digitized data from analog stick
    %
    %  To initialize with property name-value pairs:
    %  obj = analogStick([property name],[property value],...)
    %
    %  To update:
    %  obj.update(p)
    %
    %  To access average position from analog stick captured in most recent
    %  frame cycle:
    %  obj.position
    %
    %  Lee Lovejoy
    %  October 2017
    %  ll2833@columbia.edu
    %
    %  NB:
    %  1.  Call class constructor any time during or after the trial state
    %  experimentPostOpenScreen.  The Datapixx ADC is initialized after
    %  experimentPreOpenScreen but before experimentPostOpenScreen.
    %
    %  2.  experimentSetupFile will have been called prior to
    %  experimentPreOpenScreen, so we must use a PLDAPS module or
    %  initialize in the trial function.
    %
    %  3.  Call for update in the frameUpdate state of the frame cycle
    %
    %  Default properties are for Datapixx
    
    properties (SetAccess = private)
        model = 'APEM HF10Y10 single axis';
        dataSource = 'datapixx.adc';
        channels = 'channels';
        channelNumbers = 1;        
        movingAverage = 8;                
        position = NaN;
    end
    
    properties (Hidden, SetAccess = private)
        channelIndices
        dataSampleCountChannelSubs
        dataChannelSubs
    end
    
    methods (Static)
        settings = module(p,state)
    end
    
    methods
        
        %  Class Constructor
        %
        %  First argument is pldaps object and subsequent arguments are
        %  name and value pairs for setting properties.
        function obj = analogStick(p,varargin)
            
            %  Set properties from user input
            for i=1:2:nargin-2
                if(isprop(obj,varargin{i}))
                    obj.(varargin{i}) = varargin{i+1};
                else
                    error('%s is not a valid property of %s',varargin{i},mfilename('class'));
                end
            end
            
            %  Generate subreferences into PLDAPS object
            S.type = '.';
            S.subs = 'trial';
            fields = textscan(obj.dataSource,'%s','delimiter','.');
            fields=fields{1};
            S = repmat(S,length(fields)+2,1);
            for i=1:length(fields)
                S(i+1).type = '.';
                S(i+1).subs = fields{i};
            end
            S(end).subs = obj.channels;
            for i=1:numel(obj.channelNumbers)
                obj.channelIndices(i) = find(subsref(p,S) == obj.channelNumbers(i));
            end
            S(end).subs = 'dataSampleCount';
            obj.dataSampleCountChannelSubs = S;
            S(end).subs = 'data';
            S = [S ; S(end)];
            S(end).type = '()';
            obj.dataChannelSubs = @(x,y) setfield(S,{length(S)},'subs',{x,y});
        end
                
        %  update
        %
        %  Get position from digitized data
        function obj = update(obj,p)
            
            %  Determine the most recent sample
            indx = subsref(p,obj.dataSampleCountChannelSubs);
            
            %  Capture position data
            for i=1:numel(obj.channelNumbers)
                obj.position(i) = mean(subsref(p,obj.dataChannelSubs(obj.channelIndices(i),indx-obj.movingAverage:indx))); 
                obj.position(i) = min(max(obj.position(i),0),5);
            end            
        end        
        
        %  disp
        %
        %  display some of the property values to stdout
        function disp(obj)    
            fprintf('\t         model:  %s\n',obj.model);
            fprintf('\t    dataSource:  %s\n',obj.dataSource);
            fprintf('\tchannelNumbers:  %s\n',sprintf('%d ',obj.channelNumbers));
            fprintf('\t movingAverage:  %d\n',obj.movingAverage);
        end
    end
end
