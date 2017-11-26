classdef prototype
    %stateControl.prototype basic properties of a task state
    %
    %  Prototype of a task state entry for the stateControl object.
    %
    %  Lee Lovejoy
    %  November 2017
    %  ll2833@columbia.edu
    
    properties (SetAccess=private)
        state
        entryTime = [];
        exitTime = [];
        duration = Inf;
    end
    
    methods
        
        %  Class constructor
        function obj = prototype(varargin)
            
            %  Set properties from user input
            for i=1:2:nargin-1
                if(isprop(obj,varargin{i}))
                    obj.(varargin{i}) = varargin{i+1};
                end
            end      
        end
        
        %  struct
        %
        %  Overloaded function name; convert to struct
        function output = struct(obj)
            props = properties(obj);
            for i=1:numel(props)
                output.(props{i}) = obj.(props{i});
            end
        end
    end    
end

