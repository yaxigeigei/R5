classdef AnalysisConfig < handle
    %ANALYSISCONFIG Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        saveFolderPath = '';
        numFrBaseline = 60;
        vidBaseline = [];
        avgBaseline = [];
        roiSet = {};
    end
    
    methods
        function this = AnalysisConfig()
            
        end
        
        
        function [ roiIndTrg, roiIndTrk ] = GetRoiTypeInd(this)
            roiIndTrg = [];
            roiIndTrk = [];
            for i = 1 : length(this.roiSet)
                className = class(this.roiSet{i});
                if strcmp(className, 'RoiTrigger')
                    roiIndTrg(end+1) = i;
                end
                if strcmp(className, 'RoiTracking')
                    roiIndTrk(end+1) = i;
                end
            end
        end
        
        
        function cpRoi = CopyRoi(this, ind)
            cpRoi = cell(length(ind),1);
            for i = 1 : length(ind)
                cpRoi{i} = copy(this.roiSet{ind(i)});
            end
        end
        
        
        function ShowBaseline(this)
            if ~isempty(this.avgBaseline)
                imshow(this.avgBaseline);
            end
        end
        
        
        function ShowROI(this, h)
            % On baseline image
            if ~isempty(this.roiSet)
                for i = 1 : length(this.roiSet)
                    this.roiSet{i}.ShowContour('Index', i);
                end
            end
            % On main window
            if nargin > 1
                [ roiIndTrg, ~ ] = GetRoiTypeInd(this);
                roiInfo = {};
                for i = roiIndTrg
                    roiInfo = [ roiInfo; this.roiSet{i}.infoTable(1,:) ];
                end
                if ~isempty(roiInfo)
                    set(h, 'Data', table2cell(roiInfo));
                    tempRoi = RoiTrigger();
                    set(h, 'ColumnName', tempRoi.variableNames);
                end
            end
        end
        
        
        function AcquireBaseline(this, cam)
            % Keep trying to close the camera until it is really closed
            while isrunning(cam)
                stop(cam);
                pause(0.1);
            end
            
            % Set video input thisect properties for this application.
            triggerconfig(cam, 'manual');
            cam.FramesPerTrigger = 1;
            cam.FrameGrabInterval = 1;
            cam.TriggerRepeat = inf;
            cam.FramesAcquiredFcn = { };
            cam.StopFcn = { };
            cam.DiskLogger = [];
            cam.LoggingMode = 'memory';
            
            % Start acquiring frames.
            start(cam);
            trigger(cam);
            this.vidBaseline = zeros([ size(getdata(cam)), this.numFrBaseline ], 'uint8');
            for i = 1 : this.numFrBaseline
                trigger(cam);
                this.vidBaseline(:,:,i) = getdata(cam);
                imshow(this.vidBaseline(:,:,i));
                drawnow;     % update figure window
            end
            this.avgBaseline = uint8(mean(this.vidBaseline, 3));
            stop(cam);
        end
        
    end
    
end

