classdef windowManager < handle
    %windowManager object for managing windows for position tracking
    %
    %  To initialize with name value pairs:
    %  obj = windowManager
    %
    %  To add or change a window
    %  obj.addWindow([window tag],[rect])
    %
    %  To disable a specific window
    %  obj.disableWindow([tag])
    %
    %  To disable all windows
    %  obj.disableWindow('all')
    %
    %  To enable a specific window
    %  obj.enableWindow([tag])
    %
    %  To enable all windows
    %  obj.enableWindow('all')
    %
    %  To update windows with the current position
    %  obj.updateWindows([pos])
    %
    %  To check if position is in a specific window (should have updated
    %  windows first)
    %  obj.inWindow([tag])
    %
    %  To check if position is in any window
    %  obj.inWindow
    %
    %  To display windows to screen
    %  obj.displayWindows
    %
    %  Lee Lovejoy
    %  January 2017
    %  ll2833@columbia.edu
    %
    %  Updates:
    %   lpl July 19, 2017 -- change windowRect from cell array to array
    %   lpl July 26, 2017 -- merge in display management
    
    
    properties (SetAccess = private)
        currentWindows
    end
    
    properties (SetAccess = private)
        windowList
        windowEnabled
        windowRect
    end
    
    properties
        displayAreaSize
        displayAreaCenter
        horizontalDisplayRange = [-1 1];
        verticalDisplayRange = [-1 1];
        useInvertedVerticalAxis = true;
        
        activeWindowColor
        enabledWindowColor
        disabledWindowColor
        trajectoryColor
        currentColor
        borderColor
        
        windowPtr
        
        trajectoryRecord
        xPos
        yPos
        maxTrajectorySamples = 400;
        
        trajectoryDotWidth = 2;
        currentDotWidth = 8;
        
        showDisplay = true;
        showDisplayAreaOutline = true;
        showDisplayAreaAxes = true;
        showTrajectoryTrace = true;
        showDisabledWindows = true;
        showCurrentPosition = true;
        
        useLogicalWindowing = true;
    end
        
    methods
        
        %  Class constructor
        function obj = windowManager(varargin)
            for i=1:2:nargin-1
                if(isprop(obj,varargin{i}))
                    obj.(varargin{i}) = varargin{i+1};
                else
                    error('%s is not a valid property of %s',varargin{i},mfilename('class'));
                end
            end           
            obj.showDisplayAreaOutline = obj.showDisplayAreaOutline && ~isempty(obj.borderColor);
            obj.showTrajectoryTrace = obj.showTrajectoryTrace && ~isempty(obj.trajectoryColor);
            obj.showDisabledWindows = obj.showDisabledWindows && ~isempty(obj.disabledWindowColor);
        end
        
        %  addWindow
        %
        %  Function to add a window to the list of windows or change an
        %  existing window
        function obj = addWindow(obj,varargin)
            
            name = varargin{1};
            rect = varargin{2};
            if(nargin<4)
                enabled = true;
            else
                enabled = varargin{3};
            end
            ix = strcmpi(name,obj.windowList);
            if(~any(ix))
                
                %  Window not defined, add it to the end of the list
                obj.windowList = [obj.windowList {name}];
                obj.windowEnabled = logical([obj.windowEnabled enabled]);
                obj.windowRect = [obj.windowRect rect(:)];
            else
                if(~isempty(rect))
                    obj.windowRect(:,ix) = rect(:);
                    obj.windowEnabled(ix) = enabled;
                end
            end
        end
        
        %  enableWindow
        %
        %  Function to enable a disabled window
        function obj = enableWindow(obj,varargin)
            if(strcmpi(varargin{1},'all'))
                obj.windowEnabled = true(size(obj.windowEnabled));
            else
                for i=1:nargin-1
                    ix = strcmpi(varargin{i},obj.windowList);
                    if(any(ix))
                        obj.windowEnabled(ix) = true;
                    else
                        warning('window %s not previously defined',varargin{i});
                    end
                end
            end
        end
        
        %  disableWindow
        %
        %  Function to disable some or all windows from the list of windows
        function obj = disableWindow(obj,varargin)
            if(strcmpi(varargin{1},'all'))
                obj.windowEnabled = false(size(obj.windowEnabled));
            else
                for i=1:nargin-1
                    ix = strcmpi(varargin{i},obj.windowList);
                    if(any(ix))
                        obj.windowEnabled(ix) = false;
                    else
                        warning('window %s not previously defined',varargin{i});
                    end
                end
            end
        end
        
        %  updateWindows
        %
        %  Function to check which of any windows the position currently
        %  occupies.
        function obj = updateWindows(obj,varargin)
            pos = varargin{1};
            ix = pos(1) >= obj.windowRect(1,:) & pos(1) <= obj.windowRect(3,:) & pos(2) >=  obj.windowRect(2,:) & pos(2) <= obj.windowRect(4,:);
            if(any(ix))
                obj.currentWindows = obj.windowList(ix & obj.windowEnabled);
            else
                obj.currentWindows = [];
            end
        end
           
        %  updateTrajectory
        %
        %  Function to update the trajectory for display
        function obj = updateTrajectory(obj,varargin)
            pos = varargin{1};
            if(obj.useInvertedVerticalAxis)
                pos(2) = -pos(2);
            end
            obj.xPos = (pos(1)-mean(obj.horizontalDisplayRange))*obj.displayAreaSize(1)/diff(obj.horizontalDisplayRange);
            obj.yPos = (pos(2)-mean(obj.verticalDisplayRange))*obj.displayAreaSize(2)/diff(obj.verticalDisplayRange);            
            xy = [obj.xPos obj.yPos]';
            if(isempty(obj.trajectoryRecord))
                obj.trajectoryRecord = xy;
            elseif(abs(obj.trajectoryRecord(1,end)-xy(1))>=1 || abs(obj.trajectoryRecord(2,end)-xy(2))>=1)
                if(size(obj.trajectoryRecord,2)>=2*obj.maxTrajectorySamples-1)
                    obj.trajectoryRecord = [obj.trajectoryRecord(:,3:end) xy xy];
                else
                    obj.trajectoryRecord = [obj.trajectoryRecord xy xy];
                end
            end
        end
        
        %  in window
        %
        %  Return true if the specified window is occupied or if logical
        %  windowing is disabled. Return a logical vector if multiple
        %  windows are specified.  If no window is specified then return
        %  whether or not any enabled window is occupied.
        function outcome = inWindow(obj,varargin)
            if(~obj.useLogicalWindowing)
                outcome = true;
            elseif(nargin==1)
                outcome = ~isempty(obj.currentWindows);
            else
                outcome = false(nargin-1,1);
                for i=1:nargin-1
                    outcome(i) = any(strcmpi(varargin{i},obj.currentWindows));
                end
            end
        end
        
        %  displayWindows
        %
        %  write window information to stdout or output status of selected
        %  windows
        function [rect,status] = displayWindows(obj,varargin)
            if(nargin>1)
                tempWindowList = varargin{:};
            else
                tempWindowList = obj.windowList;
            end
            if(nargout==0)
                fieldWidth = 0;
                for i=1:length(obj.windowList)
                    if(any(strcmpi(obj.windowList{i},tempWindowList)))
                        fieldWidth = max(fieldWidth,length(obj.windowList{i}));
                    end
                end
                for i=1:length(obj.windowList)
                    if(any(strcmpi(obj.windowList{i},tempWindowList)))
                        if(max(obj.horizontalDisplayRange)<=1)
                            fprintf('%*s:  [%6.3f %6.3f %6.3f %6.3f] ',fieldWidth,obj.windowList{i},obj.windowRect(:,i));
                        else
                            fprintf('%*s:  [%6.1f %6.1f %6.1f %6.1f] ',fieldWidth,obj.windowList{i},obj.windowRect(:,i));
                        end
                        if(obj.windowEnabled(i))
                            if(obj.inWindow(obj.windowList{i}))
                                fprintf('(enabled, active)\n');
                            else
                                fprintf('(enabled, not active)\n');
                            end
                        else
                            fprintf('(disabled)\n');
                        end
                    end
                end
            else
                [~,~,ix] = intersect(tempWindowList,obj.windowList);
                rect = obj.windowRect(:,ix);
                status = obj.windowEnabled(ix);
            end
        end
        
        %  Flush trajectory record
        function flushTrajectoryRecord(obj)
            obj.trajectoryRecord = [];
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
            windowRects = obj.windowRect;
            if(obj.useInvertedVerticalAxis)
                windowRects(2,:) = -windowRects(2,:);
                windowRects(4,:) = -windowRects(4,:);
            end
            windowRects([1 3],:) = (windowRects([1 3],:)-mean(obj.horizontalDisplayRange))*obj.displayAreaSize(1)/diff(obj.horizontalDisplayRange);
            windowRects([1 3],:) = windowRects([1 3],:) + obj.displayAreaCenter(1);
            windowRects([2 4],:) = (windowRects([2 4],:)-mean(obj.verticalDisplayRange))*obj.displayAreaSize(2)/diff(obj.verticalDisplayRange);
            windowRects([2 4],:) = windowRects([2 4],:) + obj.displayAreaCenter(2);
            
            %  First draw in disabled windows
            if(obj.showDisabledWindows)
                disabledWindowColors = repmat(obj.disabledWindowColor(:),1,sum(~obj.windowEnabled));
                disabledWindowRects = windowRects(:,~obj.windowEnabled);
            end
            
            %  Second draw in enabled windows
            enabledWindowColors = repmat(obj.enabledWindowColor(:),1,sum(obj.windowEnabled));
            enabledWindowRects = windowRects(:,obj.windowEnabled);
            
            %  Lastly draw in active windows
            [~,~,ix] = intersect(obj.currentWindows,obj.windowList);
            activeWindowColors = repmat(obj.activeWindowColor(:),1,length(ix));
            activeWindowRects = windowRects(:,ix);
            
            Screen('FrameRect',obj.windowPtr,...
                [disabledWindowColors enabledWindowColors activeWindowColors],...
                [disabledWindowRects enabledWindowRects activeWindowRects],1);
            
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
