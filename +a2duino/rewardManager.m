classdef rewardManager < handle
    %rewardManager class for reward management using a2duino
    %
    %  Lee Lovejoy
    %  February 2017
    %  ll2833@columbia.edu
    
    properties
        maxReleaseAttempts = 11;
        rewardType
    end
    
    properties (SetAccess = protected)
        releaseInProgress
        releaseFailed
    end
    
    properties (Hidden, SetAccess = private)
        a2duinoObj
    end
    
    methods
        
        %  Class constructor
        function obj = rewardManager(varargin)
            obj.a2duinoObj = varargin{1};
        end
        
        
        function obj = giveReward(obj,varargin)            
            obj.rewardType = varargin{1};
            switch lower(obj.rewardType)
                case 'pellet'
                    obj.a2duinoObj.startPelletRelease(obj.maxReleaseAttempts);
                    obj.releaseInProgress = true;
                    obj.a2duinoObj.addCommand('getPelletReleaseStatus');
            end
        end
        
        function output = checkRewardStatus(obj)
            if(obj.releaseInProgress)
                if(obj.a2duinoObj.checkResultBuffer('getPelletReleaseStatus'))
                    output = obj.a2duinoObj.recoverResult('getPelletReleaseStatus');
                    if(~output.releaseInProgress && ~output.releaseDetected)
                        obj.releaseFailed = true;
                        obj.releaseInProgress = false;
                    elseif(output.releaseDetected)
                        obj.releaseFailed = false;
                        obj.releaseInProgress = false;
                    end
                elseif(~obj.a2duinoObj.checkCommandQueue('getPelletReleaseStatus'))
                    obj.a2duinoObj.addCommand('getPelletReleaseStatus');
                end
            end
            
        end
    end
end