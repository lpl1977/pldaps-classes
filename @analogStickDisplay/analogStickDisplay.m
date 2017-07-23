classdef analogStickDisplay < handle
    %analogStickDisplay show analog stick position on overlay
    
    properties
        overlayPtr
        
        displaySize
        displayLocation
        
        historyColor
        currentColor
        frameColor
        
        xyRecord  
        
        windowList
        windowEnabled
        windowRect
        windowColor
    end
    
    methods
        
        %  Class constructor
        function obj = analogStickDisplay(varargin)
            for i=1:2:nargin-1
                if(isprop(obj,varargin{i}))
                    obj.(varargin{i}) = varargin{i+1};
                else
                    error('%s is not a valid property of %s',varargin{i},mfilename('class'));
                end
            end
        end
        
        %  clear record
        function clearRecord(obj)
            obj.xyRecord = [];
        end
        
        %  update display
        function updateDisplay(obj,normalizedPosition)

            %  Horizontal and vertical axes
            axesLines = 0.5*obj.displaySize*[-1 1 0 0 ; 0 0 -1 1];            
            Screen('LineStipple',obj.overlayPtr,1);
            Screen('DrawLines',obj.overlayPtr,axesLines,1,obj.frameColor,obj.displayLocation);
            Screen('LineStipple',obj.overlayPtr,0);            
            
            %  Outline of display area window
            baseRect = [0 0 obj.displaySize obj.displaySize];            
            centeredRect = CenterRectOnPointd(baseRect,obj.displayLocation(1),obj.displayLocation(2));
            Screen('FrameRect',obj.overlayPtr,obj.frameColor,centeredRect,3);
            
            %  Draw in windows if any are defined
            if(any(obj.windowEnabled))
                color = obj.windowColor(:,obj.windowEnabled);
                rect = obj.windowRect(:,obj.windowEnabled);
                Screen('FrameRect',obj.overlayPtr,color,rect,1);
            end
            
            %  Trajectory
            xy = 0.5*obj.displaySize*[normalizedPosition(1) -normalizedPosition(2)]';
            obj.xyRecord = [obj.xyRecord xy];                        
            Screen('DrawDots',obj.overlayPtr,obj.xyRecord,2,obj.historyColor,obj.displayLocation,1);
            Screen('DrawDots',obj.overlayPtr,xy,8,obj.currentColor,obj.displayLocation,1);
        end

        %  addWindow
        %
        %  Function to add a window to the list of windows (or update an
        %  existing window)
        function obj = addWindow(obj,varargin)
            
            name = varargin{1};
            rect = varargin{2};
            color = varargin{3};
            
            %  Transform rect into pixel coordinates (expected to be in
            %  normalized coordinates)
            
            rect = 0.5*obj.displaySize*rect;
            rect([1 3]) = rect([1 3]) + obj.displayLocation(1);
            rect([2 4]) = -rect([2 4]) + obj.displayLocation(2);
            
            ix = strcmpi(name,obj.windowList);
            if(~any(ix))
                
                %  Window not defined, add it to the end of the list
                obj.windowList = [obj.windowList {name}];
                obj.windowEnabled = logical([obj.windowEnabled true]);
                obj.windowRect = [obj.windowRect rect(:)];
                obj.windowColor = [obj.windowColor color(:)];
            else
                
                %  Window defined, so update the rect and color
                if(~isempty(rect))
                    obj.windowRect(:,ix) = rect(:);
                end
                if(~isempty(color))
                    obj.windowColor(:,ix) = color(:);
                end
            end            
        end
        
    end    
end

