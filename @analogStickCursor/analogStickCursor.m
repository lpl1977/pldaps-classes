classdef analogStickCursor
    %analogStickCursor object for drawing cursor for analog stick
    
    properties
        cfh
        windowPointer
        visible = false;
    end
    
    properties (Hidden)
        defaultFeatures = struct(...
            'armWidth',10,...
            'height',40,...
            'fillColor',[0 0 0 1],...
            'borderColor',[0 0 0 1],...
            'borderWidth',6);
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
                if(nargin>2 && isa(varargin{2},'function_handle'))
                    feval(varargin{2},screenPos,varargin{3:end});
                else
                    feval(obj.cfh,screenPos,varargin{2:end});
                end
            end
        end
        
        %  Default cursor
        %
        %  Draw default cursor based on default features and provided
        %  screen position; optional arguments will supercede defaults
        function defaultCursor(obj,screenPos,varargin)
            features = obj.defaultFeatures;
            for i=1:2:nargin-2
                if(isfield(features,varargin{i}))
                    features.(varargin{i}) = varargin{i+1};
                end
            end
            
            w = features.armWidth+features.borderWidth;
            h = features.height+features.borderWidth;
            color = features.borderColor;
            baseRect = [-w/2 -h/2 ; h/2 w/2 ; w/2 h/2 ; -h/2 -w/2];            
            centeredRect = CenterRectOnPoint(baseRect,screenPos(1),screenPos(2));            
            Screen('FillRect',obj.windowPointer,color,centeredRect);            
            
            w = features.armWidth;
            h = features.height;
            color = features.fillColor;                               
            baseRect = [-w/2 -h/2 ; h/2 w/2 ; w/2 h/2 ; -h/2 -w/2];            
            centeredRect = CenterRectOnPoint(baseRect,screenPos(1),screenPos(2));            
            Screen('FillRect',obj.windowPointer,color,centeredRect);
        end
    end
end

