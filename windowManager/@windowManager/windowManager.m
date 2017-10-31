classdef windowManager < dynamicprops
    %windowManager object for containing windows for the window manager
    
    properties
        groupNames
    end
    
    methods
        function obj = createGroup(obj,varargin)
            for i=1:2:nargin
                if(strcmpi(varargin{i},'groupName'))
                    groupName = varargin{i+1};
                    break;
                end
            end
            varargin(i:i+1) = [];
            obj.addprop(groupName);
            obj.(groupName) = windowManager.window(varargin{:});
            obj.groupNames = [obj.groupNames {groupName}];
        end
        
        function update(obj)
            for i=1:length(obj.groupNames)
                obj.(obj.groupNames{i}).update;
            end
        end
    end
    
end

