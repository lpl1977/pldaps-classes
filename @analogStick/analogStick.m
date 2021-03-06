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
    %  Default parameters are for the Datapixx based system
    %
    %  Subsequent revisions:
    %  lpl - July 2017 a display on the overlay
    
    properties
        dataSource = 'datapixx.adc';
        channels = 'channels';
        horizontalChannel = 0;
        verticalChannel = 1;
        movingAverage = 8;
        
        horizontalOffset = 2.5;
        horizontalGain = 0.5;
        verticalOffset = 2.5;
        verticalGain = 0.5;
        
        pCenter
        pWidth
        pHeight
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
        %  subject name
        %
        %  First argument is the pldaps object.  Remainder are name value
        %  pairs for setting properties
        function obj = analogStick(p,varargin)
            
            %  set contingent properties
            obj.pCenter = p.trial.display.ctr(1:2);
            obj.pWidth = p.trial.display.pWidth;
            obj.pHeight = p.trial.display.pHeight;
            
            %  If user is supplying fields, set properties
            for i=1:2:nargin-1
                if(isprop(obj,varargin{i}))
                    obj.(varargin{i}) = varargin{i+1};
                else
                    error('%s is not a valid property of %s',varargin{i},mfilename('class'));
                end
            end
            
            %  Load calibration file if there is a calibration file to be
            %  found for the specified subject
            filename = sprintf('~/Documents/MATLAB/settings/analogStickCalibration_%s.mat',lower(p.trial.session.subject));
            if(exist(filename,'file'))
                calibration = load(filename);
                obj.horizontalOffset = calibration.horizontalOffset;
                obj.horizontalGain = calibration.horizontalGain;
                obj.verticalOffset = calibration.verticalOffset;
                obj.verticalGain = calibration.verticalGain;
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
            if(~isempty(obj.horizontalChannel))
                obj.horizontalChannelID = find(subsref(p,S) == obj.horizontalChannel);
            end
            if(~isempty(obj.verticalChannel))
                obj.verticalChannelID = find(subsref(p,S) == obj.verticalChannel);
            end
            S(end).subs = 'dataSampleCount';
            obj.dataSampleCountChannelSubs = S;
            S(end).subs = 'data';
            S = [S ; S(end)];
            S(end).type = '()';
            obj.dataChannelSubs = @(x,y) setfield(S,{length(S)},'subs',{x,y});
        end
        
        %  checkConnection
        %
        %  Function to check whether or not the analog stick is connected
        %
        %  NB:  for now, written so each DAQ has its own case.  May be
        %  revised later
        function outcome = checkConnection(obj)
            if(strfind(lower(obj.dataSource),'datapixx'))
                V = Datapixx('GetAdcVoltages');
                hC = obj.horizontalChannel;
                vC = obj.verticalChannel;
                outcome = (isempty(hC) || abs(V(hC+1))<6) && (isempty(vC) || abs(V(vC+1))<6);
            elseif(strfind(lower(obj.dataSource),'a2duino'))
                outcome = true;
            end
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
        
%         %  resetAnalogStickDisplay
%         %
%         %  Function to reset the display of analog stick position on the
%         %  overlay
%         function resetAnalogStickDisplay(obj)            
%             obj.xyRecord = [];
%         end
        
%         %  updateDisplay
%         %
%         %  Function to update the overlay display with the current currsor
%         %  position
%         function updateDisplay(obj)
%             baseRect = [0 0 obj.displaySize obj.displaySize];
%             
%             centeredRect = CenterRectOnPoint(baseRect,obj.displayLocation(1),obj.displayLocation(2));
% 
%             axesLines = 0.5*obj.displaySize*[-1 1 0 0 ; 0 0 -1 1];
%             
%             Screen('LineStipple',obj.overlayPtr,1);
%             Screen('DrawLines',obj.overlayPtr,axesLines,1,obj.frameColor,obj.displayLocation);
%             
%             Screen('FrameRect',obj.overlayPtr,obj.frameColor,centeredRect,2);
%             
%             xy = 0.5*obj.displaySize*[obj.normalizedPosition(1) -obj.normalizedPosition(2)]';
%             obj.xyRecord = [obj.xyRecord xy];
%                         
%             Screen('DrawDots',obj.overlayPtr,obj.xyRecord,2,obj.historyColor,obj.displayLocation,1);
%             Screen('DrawDots',obj.overlayPtr,xy,8,obj.currentColor,obj.displayLocation,1);
%             
% %            Screen('DrawDots',obj.displayPtr,obj.displaySize*[obj.normalizedPosition(1) obj.normalizedPosition(2)],1,obj.historyColor,[],1);
% %            tempPtr = Screen('OpenOffScreenWindow',obj.overlayPtr,12*[1 1 1],[0 0 obj.displaySize obj.displaySize]);
% %            Screen('DrawDots',tempPtr,obj.displaySize*[obj.normalizedPosition(1) obj.normalizedPosition(2)],4,obj.currentColor,[],1);
% %            Screen('DrawTexture',obj.overlayPtr,obj.displayPtr,[],centeredRect);
% %            Screen('DrawTexture',obj.overlayPtr,tempPtr,[],centeredRect); 
% %            Screen('Close',tempPtr);
%        end        
    end
end
