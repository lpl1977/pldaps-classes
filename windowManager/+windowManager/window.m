classdef window < handle
    %window object for managing windows for position tracking
    %
    %  To initialize with name value pairs:
    %  obj = window('property name',[value],...)
    %
    %  To add or change a window
    %  obj.add([window tag],[rect])
    %
    %  To disable a specific window
    %  obj.disable([tag])
    %
    %  To disable all windows
    %  obj.disable('all')
    %
    %  To enable a specific window
    %  obj.enable([tag])
    %
    %  To enable all windows
    %  obj.enable('all')
    %
    %  To update windows with the current position
    %  obj.updateWindows([pos])
    %
    %  To check if position is in a specific window (should have updated
    %  windows first)
    %  obj.in([tag])
    %
    %  To check if position is in any window
    %  obj.in
    %
    %  To display windows to screen
    %  obj.disp
    %
    %  Lee Lovejoy
    %  January 2017
    %  ll2833@columbia.edu
    %
    %  Updates:
    %   lpl July 19, 2017 -- change windowRect from cell array to array
    %   lpl July 26, 2017 -- merge in display management
    %  October 31, 2017 lpl give function handle for position; revisions to
    %  graphical appearance; some function simplification--get rid of
    %  enabled versus disabled windows and color changes for windows, etc.
    %  Also, converted to a subsidiary class for the windowManager system.
    
    
    properties
        list
        rects
        occupied
        
        positionFunc
        
        displayAreaSize
        displayAreaCenter
        horizontalDisplayRange = [-1 1];
        verticalDisplayRange = [-1 1];
        useInvertedVerticalAxis = true;
        
        windowColor
        trajectoryColor
        currentColor
        borderColor
        
        windowPtr
        
        trajectoryRecord
        maxTrajectorySamples = 60;
        trajectorySampleCount = 0;
        trajectoryDotWidth = 2;
        currentDotWidth = 8;
        currentPosition
        
        showDisplay = true;
        showDisplayAreaOutline = true;
        showDisplayAreaAxes = true;
        showTrajectoryTrace = false;
        showCurrentPosition = true;
    end
    
    methods
        
        %  Class constructor
        function obj = window(varargin)
            for i=1:2:nargin
                if(isprop(obj,varargin{i}))
                    obj.(varargin{i}) = varargin{i+1};
                else
                    error('%s is not a valid property of %s',varargin{i},mfilename('class'));
                end
            end
            obj.showDisplayAreaOutline = obj.showDisplayAreaOutline && ~isempty(obj.borderColor);
            obj.showTrajectoryTrace = obj.showTrajectoryTrace && ~isempty(obj.trajectoryColor);
            obj.trajectoryRecord = NaN(2,obj.maxTrajectorySamples);
        end
        
        %  add
        %
        %  Function to add a window to the list of windows or change an
        %  existing window
        function obj = add(obj,varargin)
            
            name = varargin{1};
            rect = varargin{2};
            ix = strcmpi(name,obj.list);
            if(~any(ix))
                
                %  Window not defined, add it to the end of the list
                obj.list = [obj.list {name}];
                obj.rects = [obj.rects rect(:)];
            else
                if(~isempty(rect))
                    obj.rects(:,ix) = rect(:);
                end
            end
        end
        
        %  in
        %
        %  Return true if the specified window is occupied.
        function outcome = in(obj,name)
            outcome = obj.occupied(strcmpi(name,obj.list));
        end
        
        %  disp
        %
        %  write window information to stdout
        function disp(obj)
            fieldWidth = 0;
            for i=1:length(obj.list)
                fieldWidth = max(fieldWidth,length(obj.list{i}));
            end
            for i=1:length(obj.list)
                fprintf('%*s:  [%s]\n',fieldWidth,obj.list{i},sprintf('% g',obj.rects(:,i)));
            end
        end
        
        %  update
        %
        %  Function to check which of any windows the position currently
        %  occupies.
        function obj = update(obj)
            
            %  Check position against windows
            pos = feval(obj.positionFunc);
            
            for i=1:numel(obj.occupied)
                obj.occupied(i) = true;
                for j=1:length(pos)
                    obj.occupied(i) = obj.occupied(i) & pos(j) >= obj.rects(2*j-1,i) & pos(j) < obj.rects(2*j,i);
                end
            end
            
            %  update trajectory record if in use
            if(obj.showTrajectoryTrace)
                ix = mod(obj.trajectorySampleCount,obj.maxTrajectorySamples)+1;
                obj.trajectoryRecord(:,ix) = pos(:)-obj.displayAreaCenter(:);
                obj.trajectorySampleCount = obj.trajectorySampleCount+1;
                obj.currentPosition = pos(:)-obj.displayAreaCenter(:);
            end
        end
        
        %  Flush trajectory record
        function flushTrajectoryRecord(obj)
            obj.trajectoryRecord(:) = NaN;
        end
        
        %  draw
        %
        %  Draw the windows and trajectory to the console display
        function draw(obj)
            
%             %  Draw in windows
%             windowRects = obj.rects;
%             if(obj.useInvertedVerticalAxis)
%                 windowRects(2,:) = -windowRects(2,:);
%                 windowRects(4,:) = -windowRects(4,:);
%             end
%             windowRects([1 3],:) = (windowRects([1 3],:)-mean(obj.horizontalDisplayRange))*obj.displayAreaSize(1)/diff(obj.horizontalDisplayRange);
%             windowRects([1 3],:) = windowRects([1 3],:) + obj.displayAreaCenter(1);
%             windowRects([2 4],:) = (windowRects([2 4],:)-mean(obj.verticalDisplayRange))*obj.displayAreaSize(2)/diff(obj.verticalDisplayRange);
%             windowRects([2 4],:) = windowRects([2 4],:) + obj.displayAreaCenter(2);
%             
%             %  Draw in windows
%             Screen('FrameRect',obj.windowPtr,obj.windowColor,windowRects,1);


% if(size(obj.rects,1)==1)
%     windowRects = obj.rects([1 3 2 4]);
%     windowRects(3) = windowRects(3)-windowRects(1);
%     windowRects(4) = windowRects(4)-windowRects(2);
% else
%     windowRects = obj.rects(:,[1 3 2 4]);
%     windowRects(:,3) = windowRects(:,3)-windowRects(:,1);
%     windowRects(:,4) = windowRects(:,4)-windowRects(:,2);
% end
windowRects = obj.rects([1 3 2 4],:);

Screen('FrameRect',obj.windowPtr,obj.windowColor,windowRects,1);
            %  Trajectory and current position
            if(obj.showTrajectoryTrace)
                Screen('DrawDots',obj.windowPtr,obj.trajectoryRecord,obj.trajectoryDotWidth,obj.trajectoryColor,obj.displayAreaCenter,1);
                Screen('DrawDots',obj.windowPtr,obj.currentPosition,obj.currentDotWidth,obj.currentColor,obj.displayAreaCenter,1);
            end
        end
        
        %  Update display
        function updateDisplay(obj)
            
            %  Horizontal and vertical axes
            if(obj.showDisplayAreaOutline && obj.showDisplayAreaAxes)
                axesLines = [-1 1 0 0 ; 0 0 -1 1];
                axesLines(1,:) = 0.5*obj.displayAreaSize(1)*axesLines(1,:);
                axesLines(2,:) = 0.5*obj.displayAreaSize(2)*axesLines(2,:);
                Screen('LineStipple',obj.windowPtr,1);
                Screen('DrawLines',obj.windowPtr,axesLines,1,obj.borderColor,obj.displayAreaCenter);
                Screen('LineStipple',obj.windowPtr,0);
            end
            
            %  Outline of display area window
            if(obj.showDisplayAreaOutline)
                baseRect = [0 0 obj.displayAreaSize(1)+10 obj.displayAreaSize(2)+10];
                centeredRect = CenterRectOnPointd(baseRect,obj.displayAreaCenter(1),obj.displayAreaCenter(2));
                Screen('FrameRect',obj.windowPtr,obj.borderColor,centeredRect,3);
            end
            
            %  Draw in windows
            windowRects = obj.rects;
            if(obj.useInvertedVerticalAxis)
                windowRects(2,:) = -windowRects(2,:);
                windowRects(4,:) = -windowRects(4,:);
            end
            windowRects([1 3],:) = (windowRects([1 3],:)-mean(obj.horizontalDisplayRange))*obj.displayAreaSize(1)/diff(obj.horizontalDisplayRange);
            windowRects([1 3],:) = windowRects([1 3],:) + obj.displayAreaCenter(1);
            windowRects([2 4],:) = (windowRects([2 4],:)-mean(obj.verticalDisplayRange))*obj.displayAreaSize(2)/diff(obj.verticalDisplayRange);
            windowRects([2 4],:) = windowRects([2 4],:) + obj.displayAreaCenter(2);
            
            %  Draw in windows
            Screen('FrameRect',obj.windowPtr,obj.windowColor,windowRects,1);
            
            %  Trajectory and current position
            if(obj.showTrajectoryTrace)
                Screen('LineStipple',obj.windowPtr,1);
                Screen('DrawLines',obj.windowPtr,obj.trajectoryRecord,1,obj.trajectoryColor,obj.displayAreaCenter);
                Screen('LineStipple',obj.windowPtr,0);
                Screen('DrawDots',obj.windowPtr,obj.trajectoryRecord,obj.trajectoryDotWidth,obj.trajectoryColor,obj.displayAreaCenter,1);
            end
            if(obj.showCurrentPosition)
                Screen('DrawDots',obj.windowPtr,[obj.xPos obj.yPos]',obj.currentDotWidth,obj.currentColor,obj.displayAreaCenter,1);
            end
        end
    end
end
