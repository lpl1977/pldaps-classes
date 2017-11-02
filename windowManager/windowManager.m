classdef windowManager < dynamicprops
    %windowManager object for containing windows for the window manager
    %
    %  To create a group with name value pairs
    %  obj.createGroup(obj,'groupName',[group name],[name],[value])
    %
    %  To update all groups
    %  obj.update
    %
    %  To draw all groups
    %  obj.draw
    %
    %  To display all group windows to screen
    %  obj.disp
    %
    %  Lee Lovejoy
    %  ll2833@columbia.edu
    %  November 2017
    
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
            obj.(groupName) = windowManager.windowGroup(varargin{:});
            obj.groupNames = [obj.groupNames {groupName}];
        end
        
        function update(obj)
            for i=1:length(obj.groupNames)
                obj.(obj.groupNames{i}).update;
            end
        end
        
        function draw(obj)
            for i=1:length(obj.groupNames)
                obj.(obj.groupNames{i}).draw;
            end
        end
        
        function disp(obj)
            fprintf('****************************************************************\n');
            for i=1:length(obj.groupNames)
                fprintf('Windows for %s:\n',obj.groupNames{i});
                obj.(obj.groupNames{i}).disp;
            end
            fprintf('****************************************************************\n');
        end
    end
    
end

