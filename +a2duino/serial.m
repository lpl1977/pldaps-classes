classdef serial
    %serialObj class to hold serial connection object for a2duino package
    
    properties
        portName = '/dev/ttyACM0';
        baud = 230400;
        inputBufferSize = 2048;
        isConnected
        connection
    end
    
    methods
        %  Class constructor
        function obj = serial(varargin)
        
            %  Set properties based on name value pairs
            for i=1:2:nargin
                if(isprop(obj,varargin{i}))
                    obj.(varargin{i}) = varargin{i+1};
                end
            end
            
            %  Create serial port object
            obj.connection = serial(obj.portName,'baud',obj.baud);
            obj.connection.InputBufferSize = obj.inputBufferSize;
        end
    end    
end

