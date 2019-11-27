classdef AnalysisRuntime < handle
    %ANALYSISRUNTIME Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % Info
        fileName = '';
        frameRate = 0;
        
        % ROI analysis
        roiTrk = {};
        roiTrg = {};
        
        avgBaseline;    % mean baseline image
        thisFr;         % incoming frame
        lastFr;         % last frame
        bdFr;           % difference to mean baseline (baseline diff.)
        mdFr;           % difference to last frame (motion diff.)
        
        % Behavior logging
        rtMode = 'freerun'      % runtime modes include 'freerun'(default), 'trials'
        trialProceed = true;    % flag for pausing the session (effective only in 'trials' mode)
        logVideo = false;       % fixed video logging switch for entire session
        epochIdx = 1;           % index of the current epoch
        frIdx = 0;              % index of current frame within the epoch
        frPool                  % frame pool for this epoch
        maxEpoch = 1000;        % max trial/epoch number
        bTable                  % behavioral result table
        
        % Measurement logging
        nSets = 100;
        setSize = 30000;        % each set stores data of 5min 100Hz video
        setIdx = 0;             % current index of data set to log
        elementIdx = 0;         % current index of element to log in the current data set
        timeArray;              % stores time stamps
        epoIndArray;            % stores indices of epoch/trial that the data points belong to
        trigDataArray;          % raw intensity data of triggering ROI
        trigEventArray;         % same as trigDataArray except only effective triggering is logged
        trackDataArray;         % stores coordinates of tracking
    end
    
    methods
        function this = AnalysisRuntime(anaCfg)
            % Specify file name for saving
            formatOut = 'yyyy-mm-dd-HH-MM-SS';
            this.fileName = fullfile(anaCfg.saveFolderPath, datestr(now,formatOut));
            
            % Initialize parameters
            this.avgBaseline = anaCfg.avgBaseline;
            this.lastFr = double(this.avgBaseline);
            this.thisFr = double(this.avgBaseline);
            
            % Find which ROIs require tracking and trigger, respectively
            [ roiIndTrg, roiIndTrk ] = anaCfg.GetRoiTypeInd();
            this.roiTrg = anaCfg.CopyRoi(roiIndTrg);
            this.roiTrk = anaCfg.CopyRoi(roiIndTrk);
            
            % Preallocate space for data
            this.timeArray = cell(this.nSets,1);
            this.epoIndArray = cell(this.nSets,1);
            this.trigDataArray = cell(this.nSets,1);
            this.trigEventArray = cell(this.nSets,1);
            this.trackDataArray = cell(this.nSets,1);
            this.MakeNewSet();
            
            vn = { 'Drop'; 'Remain' };
            this.bTable = table(NaN(this.maxEpoch,1), NaN(this.maxEpoch,1), 'VariableNames', vn);
        end
        
        
        function MakeNewSet(this)
            if this.setIdx < this.nSets
                this.setIdx = this.setIdx + 1;
                this.elementIdx = 0;
                this.timeArray{this.setIdx} = NaN(this.setSize,1);
                this.epoIndArray{this.setIdx} = zeros(this.setSize,1);
                this.trigDataArray{this.setIdx} = NaN(this.setSize,length(this.roiTrg));
                this.trigEventArray{this.setIdx} = NaN(this.setSize,length(this.roiTrg));
                this.trackDataArray{this.setIdx} = NaN(this.setSize,length(this.roiTrk)*2);
            end
        end
        
        
        
        
        function LogTimeStamp(this, timeStamp, fr)
            if this.elementIdx == this.setSize
                this.MakeNewSet();
            end
            this.elementIdx = this.elementIdx + 1;
            this.timeArray{this.setIdx}(this.elementIdx) = timeStamp;
            
            if ~isempty(this.roiTrg)
                this.bdFr = double(fr) - double(this.avgBaseline);
            end
            
            if ~isempty(this.roiTrk)
                this.lastFr = this.thisFr;
                this.thisFr = double(fr);
                this.mdFr = abs(this.thisFr - this.lastFr);
            end
        end
        
        function tsVect = GetPastTimeStamp(this, nPt)
            beginIdx = this.elementIdx - nPt + 1;
            beginIdx = max(beginIdx,1);
            tsVect = this.timeArray{this.setIdx}(beginIdx : this.elementIdx);
            tsVect = [ NaN(nPt - length(tsVect),1); tsVect ];
        end
        
        
        
        
        function isFull = LogFrame(this, fr)
            % Check for epoch end
            isFull = this.frIdx >= size(this.frPool,3);
            if ~isFull
                % Log the epoch number
                this.epoIndArray{this.setIdx}(this.elementIdx) = this.epochIdx;
                this.frIdx = this.frIdx + 1;
                this.frPool(:,:,this.frIdx) = fr;
            end
        end
        
        
        
        
        function trigBools = LogTrigger(this)
            trigBools = zeros(length(this.roiTrg), 1); % Initialize trigger status
            for i = 1 : length(this.roiTrg)
                % Calculate average change of pixel intensity
                diffRoi = this.bdFr(this.roiTrg{i}.mask);
                trigVal = mean(diffRoi(:));
                trigBools(i) = this.roiTrg{i}.Decide(trigVal);
                % Log raw instensity value and that with event
                this.trigDataArray{this.setIdx}(this.elementIdx,i) = trigVal;
                if trigBools(i)
                    this.trigEventArray{this.setIdx}(this.elementIdx,i) = trigVal;
                end
            end
        end
        
        function tVect = GetPastTrigger(this, roiIdx, nPt)
            beginIdx = this.elementIdx - nPt + 1;
            beginIdx = max(beginIdx,1);
            tVect = this.trigDataArray{this.setIdx}(beginIdx:this.elementIdx, roiIdx);
            tVect = [ NaN(nPt - length(tVect),1); tVect ];
        end
        
        function eVect = GetPastTrigEvent(this, roiIdx, nPt)
            beginIdx = this.elementIdx - nPt + 1;
            beginIdx = max(beginIdx,1);
            eVect = this.trigEventArray{this.setIdx}(beginIdx:this.elementIdx, roiIdx);
            eVect = [ NaN(nPt - length(eVect),1); eVect ];
        end
        
        
        
        
        function LogTracking(this)
            for i = 1 : length(this.roiTrk)
                [ r, c ] = this.roiTrk{i}.Track(this.mdFr);
                this.trackDataArray{this.setIdx}(this.elementIdx,i*2-1) = r;
                this.trackDataArray{this.setIdx}(this.elementIdx,i*2) = c;
            end
        end
        
        function tVect = GetPastTrackVal(this, roiIdx, nPt)
            beginIdx = this.elementIdx - nPt + 1;
            beginIdx = max(beginIdx,1);
            tVect = this.trackDataArray{this.setIdx}...
                (beginIdx:this.elementIdx, (roiIdx-1)*2+axisIdx);
            tVect = [ NaN(nPt - length(tVect),1); tVect ];
        end
        
        function tVect = GetPastTrackPos(this, roiIdx, axisIdx, nPt)
            beginIdx = this.elementIdx - nPt + 1;
            beginIdx = max(beginIdx,1);
            tVect = this.trackDataArray{this.setIdx}...
                (beginIdx:this.elementIdx, (roiIdx-1)*2+axisIdx);
            tVect = [ NaN(nPt - length(tVect),1); tVect ];
        end
        
        
        
        
        function LogPelletState(this, isRemain)
            this.bTable.Remain(this.epochIdx) = isRemain;
        end
        
        function LogDropping(this)
            this.bTable.Drop(this.epochIdx) = this.frIdx;
        end
        
        function bs = GetPerformance(this, nPt)
            bs.epochIdx = this.epochIdx;
            bs.dropVect = this.bTable.Drop;
            bs.dropVectNorm = bs.dropVect / size(this.frPool,3);
            bs.remainVect = this.bTable.Remain;
            bs.remainVect(bs.remainVect == 0) = NaN;
            bs.hitVect = NaN(this.maxEpoch,1);
            bs.missVect = NaN(this.maxEpoch,1);
            bs.failVect = NaN(this.maxEpoch,1);
            for i = 1:bs.epochIdx
                if isnan(bs.dropVect(i)) && isnan(bs.remainVect(i))
                    bs.hitVect(i) = 1;
                elseif isnan(bs.dropVect(i)) && ~isnan(bs.remainVect(i))
                    bs.missVect(i) = 1;
                elseif ~isnan(bs.dropVect(i))
                    bs.failVect(i) = 1;
                end
            end
            bs.hitNum = sum(~isnan(bs.hitVect));
            bs.failNum = sum(~isnan(bs.failVect));
            bs.missNum = sum(~isnan(bs.missVect));
            bs.hitRate = bs.hitNum / bs.epochIdx;
            bs.failRate = bs.failNum / bs.epochIdx;
            bs.missRate = bs.missNum / bs.epochIdx;
            
            if nargin > 1
                beginIdx = bs.epochIdx - nPt + 1;
                beginIdx = max(beginIdx,1);
                bs.plotInd = beginIdx : (beginIdx + nPt - 1);
            end
        end
        
        function [ dx, dy ] = GetPastDrop(this, nPt)
            beginIdx = this.epochIdx - nPt + 1;
            beginIdx = max(beginIdx,1);
            dy = this.bTable.Drop(beginIdx:this.epochIdx);
            dy = dy / size(this.frPool, 3);
            dy = [ dy; NaN(nPt - length(dy),1) ];
            dx = beginIdx : (beginIdx + nPt - 1);
        end
        
        function [ rx, ry ] = GetPastRemain(this, nPt)
            beginIdx = this.epochIdx - nPt + 1;
            beginIdx = max(beginIdx,1);
            ry = this.bTable.Remain(beginIdx:this.epochIdx);
            ry(find(ry == 0)) = NaN;
            ry = [ ry; NaN(nPt - length(ry),1) ];
            rx = beginIdx : (beginIdx + nPt - 1);
        end
        
        function [ sx, sy ] = GetPastSuccess(this, nPt)
            [ sx, dy ] = this.GetPastDrop(nPt);
            dy(find(isnan(dy))) = 0;
            [ ~, ry ] = this.GetPastRemain(nPt);
            ry(find(isnan(ry))) = 0;
            sy = double(~dy & ~ry);
            sy(find(~sy)) = NaN;
            
            if this.epochIdx < nPt
                sy = sy(1:this.epochIdx);
                sy = [ sy; NaN(nPt - length(sy),1) ];
            end
        end
        
        function [ fx, fy ] = GetPastFailure(this, nPt)
            [ fx, sy ] = this.GetPastSuccess(nPt);
            sy(find(isnan(sy))) = 0;
            fy = double(~sy);
            fy(find(~fy)) = NaN;
            
            if this.epochIdx < nPt
                fy = fy(1:this.epochIdx);
                fy = [ fy; NaN(nPt - length(fy),1) ];
            end
        end
        
        function hy = GetSuccessRate(this)
            [ ~, sy ] = this.GetPastSuccess(1000);
            numHit = double(length(find(~isnan(sy))));
            hy = numHit / double(this.epochIdx);
        end
        
        
        
        
        
        function ExportData(this)
            obj = this;
            save([ this.fileName '.mat' ], 'obj');
        end
        
        function FinishEpoch(this)
            if strcmp(this.rtMode, 'trials') % make sure no problem occurs when called accidentally
                isFull = this.frIdx >= size(this.frPool,3);
                if isFull
                    if this.logVideo
                        writerObj = VideoWriter([ this.fileName, '-', num2str(this.epochIdx) ], 'Grayscale AVI');
                        writerObj.FrameRate = round(this.frameRate);
                        open(writerObj);
                        for i = 1 : this.frIdx
                           writeVideo(writerObj, this.frPool(:,:,i));
                        end
                        close(writerObj);
                    end
                    
                    this.frIdx = 0;
                    this.epochIdx = this.epochIdx + 1;
                else
                    % Subtract epoch number by one because this epoch was not finished
                    this.epochIdx = this.epochIdx - 1;
                end
                this.frPool = zeros(size(this.frPool), 'uint8');
            end
        end
        
        
        
        
        function fid = GetFrameIndex(this)
            fid = (this.setIdx-1) * this.setSize + this.elementIdx;
        end
        
        function b = IfRefresh(this, targetFrameRate)
            refreshPeriod = ceil(this.frameRate / targetFrameRate);
            b = ~mod(this.GetFrameIndex, refreshPeriod);
        end
    end
    
end

