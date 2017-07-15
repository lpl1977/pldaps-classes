classdef eyeLinkManager
    %eyeLinkManager helper for EyeLink and calibration
    
    properties
        autoreward = true;
        reward = 0.1;
    end
    
    methods (Static)        
        interface(p)            
        displayTargets(p)
    end
    
end

