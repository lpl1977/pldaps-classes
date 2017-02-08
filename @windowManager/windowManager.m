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

    
    properties (SetAccess = private)
        currentWindow
    end
    
    properties (Hidden, SetAccess = private)
        windowList = cell(0);
        windowEnabled = false(0);
        windowRect = cell(0);
    end
    
    methods

        %  addWindow
        %
        %  Function to add a window to the list of windows or change an
        %  existing window
        function obj = addWindow(obj,varargin)
            
            name = varargin{1};
            rect = varargin{2};
            ix = strcmpi(name,obj.windowList);
            if(~any(ix))
                
                %  Window not defined, add it to the end of the list
                obj.windowList{end+1} = name;
                obj.windowEnabled(end+1) = true;
                obj.windowRect{end+1} = rect;
            else
                obj.windowRect{ix} = rect;
            end
        end
        
        %  enableWindow
        %
        %  Function to enable a disabled window
        function obj = enableWindow(obj,varargin)
            if(strcmpi(varargin{1},'all'))
                obj.windowEnabled = true(size(obj.windowEnabled));
            else
                name = varargin{1};
                if(~any(strcmpi(name,obj.windowList)))
                    warning('window %s is not defined\n',name);
                else
                    ix = strcmpi(name,obj.windowList);
                    if(any(ix))
                        obj.windowEnabled(ix) = true;
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
                name = varargin{1};
                if(~any(strcmpi(name,obj.windowList)))
                    warning('window %s is not defined\n',name);
                else
                    ix = strcmpi(name,obj.windowList);
                    if(any(ix))
                        obj.windowEnabled(ix) = false;
                    end
                end
            end
        end
        
        %  updateWindows
        %
        %  Function to check which of any enabled windows the position is
        %  currently in
        function obj = updateWindows(obj,varargin)            
            if(nargin==2)
                pos = varargin{1};
                ix = false(size(obj.windowEnabled));
                for i=1:length(obj.windowList)
                    rect = obj.windowRect{i};
                    ix(i) = pos(1) >= rect(1) && pos(1) <= rect(3) && pos(2) >= rect(2) && pos(2) <= rect(4);
                end
                if(any(ix & obj.windowEnabled))
                    obj.currentWindow = obj.windowList(ix & obj.windowEnabled);
                else
                    obj.currentWindow = [];
                end
            end
        end
        
        %  in window
        %
        %  Check if the cursor is in the specified window; if the argument
        %  is empty, return whether or not the cursor is in any window
        function outcome = inWindow(obj,varargin)            
            if(nargin>1)
                name = varargin{1};
            else
                name = [];
            end            
            if(~isempty(name))
                if(~any(strcmpi(name,obj.windowList)))
                    outcome = false;
                    warning('window %s is not defined\n',name);
                else
                    outcome = any(strcmpi(name,obj.currentWindow));
                end
            else
                outcome = ~isempty(obj.currentWindow);
            end
        end
        
        %  displayWindows
        %
        %  write window information to stdout
        function displayWindows(obj)
            fieldWidth = 0;
            for i=1:length(obj.windowList)
                fieldWidth = max(fieldWidth,length(obj.windowList{i}));
            end
            for i=1:length(obj.windowList)
                fprintf('\t%*s:  [%6.3f %6.3f %6.3f %6.3f] ',fieldWidth,obj.windowList{i},obj.windowRect{i});
                if(obj.windowEnabled(i))
                    fprintf('(enabled)\n');
                else
                    fprintf('(disabled)\n');
                end
            end
        end
    end
end
