classdef trialOutcome < dynamicprops
    %trialOutcome dynamic class to flexibly store trial outcome during
    %trial
    
    properties
    end
    
    methods
        
        %  Class constructor
        function obj = trialOutcome(varargin)
            for i=1:2:nargin
                obj.addprop(varargin{i});
                obj.(varargin{i}) = varargin{i+1};
            end
        end
        
        %  Convert to struct (overload struct)
        function output = struct(obj)
            fields = properties(obj);
            for i=1:numel(fields)
                output.(fields{i}) = obj.(fields{i});
            end
        end
    end    
end