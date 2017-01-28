classdef windowManager < handle
    %windowManager object for managing windows for position tracking
    %
    %  To initialize with name value pairs:
    %  obj = windowManager
    %
    %  To add or change a window
    %  obj.addWindow([window tag],[rect])
    %
    %  To remove a specific window
    %  obj.removeWindow([tag])
    %
    %  To remove all windows
    %  obj.removeWindow('all')
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
    %  Lee Lovejoy
    %  January 2017
    %  ll2833@columbia.edu

    
    properties (SetAccess = private)
        currentWindow
        windows
    end
    
    properties (Hidden, SetAccess = private)
        windowList
    end
    
    methods
        
        %  Class constructor
        %
        %  Create window manager object.
        function obj = windowManager(varargin)
            
            %  If user is supplying fields, set properties
            for i=1:2:nargin
                if(isprop(obj,varargin{i}))
                    obj.(varargin{i}) = varargin{i+1};
                else
                    error('%s is not a valid property of %s',varargin{i},mfilename);
                end
            end
        end
        
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
            end
            obj.windows.(name).name = name;
            obj.windows.(name).rect = rect;
        end
        
        %  removeWindow
        %
        %  Function to remove some or all windows from the list of windows
        function obj = removeWindow(obj,varargin)
            
            %  Check arguments
            if(strcmpi(varargin{1},'all'))
                obj.windows = [];
                obj.windowList = [];
            else
                name = varargin{1};
                ix = strcmpi(name,obj.windowList);
                if(any(ix))
                    obj.windows = rmfield(obj.windows,obj.windowList{ix});
                    obj.windowList = obj.windowList(~ix);
                end
            end
        end
           
        %  updateWindows
        %
        %  Function to check which of any windows the position is currently
        %  in
        function obj = updateWindows(obj,varargin)
            
            if(nargin==2)
                pos = varargin{1};
                ix = false(length(obj.windowList),1);
                for i=1:length(obj.windowList)
                    rect = obj.windows.(obj.windowList{i}).rect;
                    ix(i) = pos(1) >= rect(1) && pos(1) <= rect(3) && pos(2) >= rect(2) && pos(2) <= rect(4);
                end
                if(any(ix))
                    obj.currentWindow = obj.windowList(ix);
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
            
            if(nargin==2)
                name = varargin{1};
            else
                name = [];
            end            
            if(~isempty(name))
                outcome = any(strcmpi(name,obj.currentWindow));
            else
                outcome = ~isempty(obj.currentWindow);
            end
        end
        
    end
end
