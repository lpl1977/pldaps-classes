classdef stateVariables < dynamicprops
    %stateVariables dynamic class to flexibly store state variables during
    %trial
    
    properties
    end
    
    methods
        
        %  Class constructor
        function obj = stateVariables(varargin)
            for i=1:2:nargin
                obj.addprop(varargin{i});
                obj.(varargin{i}) = varargin{i+1};
            end
        end
    end    
end