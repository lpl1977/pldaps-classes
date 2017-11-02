classdef windowGroup < handle
    %windowGroup object for managing a group of windows for position tracking
    %
    %  To initialize with name value pairs:
    %  obj = windowGroup('property name',[value],...)
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
        windows
        
        positionFunc
        
        displayAreaSize
        displayAreaCenter
        displayAreaBorder
        displayAreaAxes
        
        horizontalDataRange = [-1 1];
        verticalDataRange = [-1 1];
        dataOrigin = [0 0];
        
        useInvertedVerticalAxis = false;
        
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
        
        showDisplayAreaOutline = true;
        showDisplayAreaAxes = true;
        showTrajectoryTrace = false;
        showCurrentPosition = true;
    end
    
    methods
        
        %  Class constructor
        function obj = windowGroup(varargin)
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
            
            %  Calculate boundaries of display area
            baseRect = [0 0 obj.displayAreaSize(1)+4 obj.displayAreaSize(2)+4];
            obj.displayAreaBorder = CenterRectOnPointd(baseRect,obj.displayAreaCenter(1),obj.displayAreaCenter(2));
                        
            %  Calculate position of area axes
            obj.displayAreaAxes = [obj.horizontalDataRange obj.dataOrigin([1 1]) ; obj.dataOrigin([2 2]) obj.verticalDataRange];
            obj.displayAreaAxes(1,:) = (obj.displayAreaAxes(1,:)-obj.dataOrigin(1))*obj.displayAreaSize(1)/diff(obj.horizontalDataRange);
            if(obj.useInvertedVerticalAxis)
                obj.displayAreaAxes(2,:) = -(obj.displayAreaAxes(2,:)-obj.dataOrigin(2))*obj.displayAreaSize(2)/diff(obj.verticalDataRange); 
            else
                obj.displayAreaAxes(2,:) = (obj.displayAreaAxes(2,:)-obj.dataOrigin(2))*obj.displayAreaSize(2)/diff(obj.verticalDataRange); 
            end            
        end
        
        %  add
        %
        %  Function to add a window to the list of windows or change an
        %  existing window
        function obj = add(obj,varargin)
            
            name = varargin{1};
            rect = varargin{2};
            ix = strcmpi(name,obj.list);
            
            %  Convert rect to window in screen coordinates
            window = rect([1 3 2 4]);
            window([1 3]) = (window([1 3])-obj.dataOrigin(1))*obj.displayAreaSize(1)/diff(obj.horizontalDataRange) + obj.displayAreaCenter(1);
            if(obj.useInvertedVerticalAxis)
                window([2 4]) = -(window([2 4])-obj.dataOrigin(2))*obj.displayAreaSize(2)/diff(obj.verticalDataRange) + obj.displayAreaCenter(2); 
            else
                window([2 4]) = (window([2 4])-obj.dataOrigin(2))*obj.displayAreaSize(2)/diff(obj.verticalDataRange) + obj.displayAreaCenter(2); 
            end
            
            %  Populate lists
            if(~any(ix))
                
                %  Window not defined, add it to the end of the list
                obj.list = [obj.list {name}];
                obj.rects = [obj.rects rect(:)];
                obj.occupied = [obj.occupied ; false];
                obj.windows = [obj.windows fix(window(:))];
            else
                if(~isempty(rect))
                    obj.rects(:,ix) = rect(:);
                    obj.windows(:,ix) = fix(window(:));
                    obj.occupied(ix) = false;
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
                fprintf('\t%*s:  [%s]\n',fieldWidth,obj.list{i},sprintf('% g',obj.rects(:,i)));
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
            
            %  Update current position and trajectory record
            pos(1) = (pos(1)-obj.dataOrigin(1))*obj.displayAreaSize(1)/diff(obj.horizontalDataRange);
            if(obj.useInvertedVerticalAxis)
                pos(2) = -(pos(2)-obj.dataOrigin(2))*obj.displayAreaSize(2)/diff(obj.verticalDataRange);
            else
                pos(2) = (pos(2)-obj.dataOrigin(2))*obj.displayAreaSize(2)/diff(obj.verticalDataRange);
            end            
            obj.currentPosition = pos(:);
            ix = mod(obj.trajectorySampleCount,obj.maxTrajectorySamples)+1;
            obj.trajectoryRecord(:,ix) = pos(:);
            obj.trajectorySampleCount = obj.trajectorySampleCount+1;
        end
        
        %  flush trajectory record
        function flushTrajectoryRecord(obj)
            obj.trajectoryRecord = NaN(2,obj.maxTrajectorySamples);
        end
        
        %  draw
        %
        %  Draw the windows and trajectory to the console display
        function draw(obj)
            
            %  Axes and outline of display area
            if(obj.showDisplayAreaAxes)
                Screen('LineStipple',obj.windowPtr,1,1,logical([0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1]));
                Screen('DrawLines',obj.windowPtr,obj.displayAreaAxes,1,obj.borderColor,obj.displayAreaCenter);
                Screen('LineStipple',obj.windowPtr,0);                
            end
            if(obj.showDisplayAreaOutline)
                Screen('FrameRect',obj.windowPtr,obj.borderColor,obj.displayAreaBorder,2);
            end
            
            %  Draw in windows
            Screen('FrameRect',obj.windowPtr,obj.windowColor,obj.windows,1);

            %  Trajectory and current position
            if(obj.showTrajectoryTrace)
                Screen('DrawDots',obj.windowPtr,obj.trajectoryRecord,obj.trajectoryDotWidth,obj.trajectoryColor,obj.displayAreaCenter,1);
            end
            if(obj.showCurrentPosition)
                Screen('DrawDots',obj.windowPtr,obj.currentPosition,obj.currentDotWidth,obj.currentColor,obj.displayAreaCenter,1);
            end
        end
    end
end
