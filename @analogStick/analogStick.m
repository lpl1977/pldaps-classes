classdef analogStick < handle
    %analogStick object for interfacing with analog stick
    %
    %  To initialize:
    %  obj = analogStick
    %  obj = analogStick([property name],[property value],...)
    %
    %  To update:
    %  obj.update(p)
    %
    %  Lee Lovejoy
    %  January 2017
    %  ll2833@columbia.edu
    %
    %  NB It is important that you not auto-update.  Call the update
    %  function in the frameUpdate state of the frame cycle.
    %
    %  Default properties are for Datapixx
    %
    %  Subsequent revisions:
    %  lpl - July 2017 a display on the overlay
    %  lpl - October 2017 remove screen display; remove explicit
    %  association with position and include transformation if required
    %  elsewhere; remove calibration and include if necessary elsewhere.
    
    properties
        dataSource = 'datapixx.adc';
        channels = 'channels';
        channelNumbers = 0;        
        movingAverage = 8;
    end
    
    properties (SetAccess = protected)
        normalizedPosition
        screenPosition
    end
    
    properties (Hidden)
        horizontalChannelID
        verticalChannelID
        
        dataSampleCountChannelSubs
        dataChannelSubs
        
        rawData = NaN;
        
        rawX = NaN;
        rawY = NaN;
        
        overlayPtr
        
        displaySize
        displayLocation
        
        historyColor
        currentColor
        frameColor
        
        xyRecord        
    end
    
    methods
        
        %  Class Constructor
        %
        %  First argument is the pldaps object.  Subsequent arguments are
        %  name and value pairs for setting properties.
        function obj = analogStick(p,varargin)
            
            %  If user is supplying fields, set properties
            for i=1:2:nargin-1
                if(isprop(obj,varargin{i}))
                    obj.(varargin{i}) = varargin{i+1};
                else
                    error('%s is not a valid property of %s',varargin{i},mfilename('class'));
                end
            end
                        
            %  Generate subreferences
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
            S(end).subs = 'dataSampleCount';
            obj.dataSampleCountChannelSubs = S;
            S(end).subs = 'data';
            S = [S ; S(end)];
            S(end).type = '()';
            obj.dataChannelSubs = @(x,y) setfield(S,{length(S)},'subs',{x,y});
        end
                
        %  update
        %
        %  Function to capture data from analog stick
        function obj = update(obj,p)
            
            %  Determine the most recent sample
            indx = subsref(p,obj.dataSampleCountChannelSubs);
            
            %  horizontal position
            if(~isempty(obj.horizontalChannel))
                obj.rawX = mean(subsref(p,obj.dataChannelSubs(obj.horizontalChannelID,indx-obj.movingAverage:indx)));
            end
            
            %  vertical position
            if(~isempty(obj.verticalChannel))
                obj.rawY = mean(subsref(p,obj.dataChannelSubs(obj.verticalChannelID,indx-obj.movingAverage:indx)));
            end
            
            %  Update normalized position
            obj.normalizedPosition(1) = min(1,max(-1,obj.horizontalGain*(obj.rawX-obj.horizontalOffset)));
            obj.normalizedPosition(2) = min(1,max(-1,obj.verticalGain*(obj.rawY-obj.verticalOffset)));
            
            %  Update screen position
            obj.screenPosition(1) = obj.pCenter(1) + obj.pWidth*obj.normalizedPosition(1)/2;
            obj.screenPosition(2) = obj.pCenter(2) - obj.pHeight*obj.normalizedPosition(2)/2;            
        end        
    end
end
