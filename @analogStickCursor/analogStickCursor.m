classdef analogStickCursor
    %analogStickCursor object for drawing cursor for analog stick
    
    properties
        cfh
        windowPointer
        visible = false;
    end
    
    properties (Hidden)
        defaultFeatures = struct(...
            'linewidth',6,...
            'height',20,...
            'color',[0 0 0]);
    end
        
    methods
        %  Class consturctor
        function obj = analogStickCursor(varargin)
            obj.windowPointer = varargin{1};
            if(nargin==1)
                obj.cfh = @obj.defaultCursor;
            else
                obj.cfh = varargin{2};
            end
        end
        
        %  Draw cursor
        function drawCursor(obj,varargin)
            if(obj.visible)
                screenPos = varargin{1};
                feval(obj.cfh,screenPos,varargin{2:end});
            end
        end
        
        %  Default cursor
        %
        %  Draw default cursor based on features in provided screen
        %  position        
        function defaultCursor(obj,screenPos)            
            w = obj.defaultFeatures.linewidth;
            h = obj.defaultFeatures.height;
            color = obj.defaultFeatures.color;            
            baseRect = [-w/2 -h/2 ; h/2 w/2 ; w/2 h/2 ; -h/2 -w/2];            
            centeredRect = CenterRectOnPoint(baseRect,screenPos(1),screenPos(2));            
            Screen('FillRect',obj.windowPointer,color,centeredRect);
        end
    end
    
end

