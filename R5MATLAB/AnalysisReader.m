classdef AnalysisReader < handle
    %ANALYSISREADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        anaRt;
        trialTimeStamps = {};
        trialTrigData = {};
        trialTrackData = {};
        
        vidObjs;
        frameRange = {};
        vidIdx = 1;
        vid;
    end
    
    methods
        
        function this = AnalysisReader(anaRtPath, vidPaths)
            load(anaRtPath);
            this.anaRt = obj;
            this.OrganizeRawData();
            
            if nargin > 1
                this.vidObjs = cellfun(@VideoReader, vidPaths, 'UniformOutput', false);
            end
        end
        
        function OrganizeRawData(this)
            % Figure out where data ends
            for i = length(this.anaRt.timeArray):-1:1
                if ~isempty(this.anaRt.timeArray{i})
                    maxCell = i;
                    nanList = isnan(this.anaRt.timeArray{i});
                    maxElement = find(~nanList, 1, 'last');
                    break;
                end
            end
            
            % Preallocate data space
            cellLength = length(this.anaRt.timeArray{1});
            dataLength = cellLength * (maxCell - 1) + maxElement;
            allTimeStamps = zeros(dataLength, 1);
            allTrialInd = zeros(dataLength, 1);
            allTrigData = zeros(dataLength, length(this.anaRt.roiIndTrg));
            allTrackData = zeros(dataLength, length(this.anaRt.roiIndTrk)*2);
            
            % Fill in data
            for i = 1 : maxCell
                bIdx = (i-1)*cellLength + 1;
                if i ~= maxCell
                    eIdx = bIdx + cellLength - 1;
                    allTimeStamps(bIdx:eIdx) = this.anaRt.timeArray{i};
                    allTrialInd(bIdx:eIdx) = this.anaRt.epoIndArray{i};
                    allTrigData(bIdx:eIdx,:) = this.anaRt.trigEventArray{i};
                    allTrackData(bIdx:eIdx,:) = this.anaRt.trackDataArray{i};
                else
                    eIdx = bIdx + maxElement - 1;
                    allTimeStamps(bIdx:eIdx) = this.anaRt.timeArray{i}(1:maxElement);
                    allTrialInd(bIdx:eIdx) = this.anaRt.epoIndArray{i}(1:maxElement);
                    allTrigData(bIdx:eIdx,:) = this.anaRt.trigEventArray{i}(1:maxElement,:);
                    allTrackData(bIdx:eIdx,:) = this.anaRt.trackDataArray{i}(1:maxElement,:);
                end
            end
            
            % Further organize into trials
            ind = num2cell(1:this.anaRt.epochIdx)';
            this.trialTimeStamps = cellfun(@(x) allTimeStamps(find(allTrialInd == x)), ind, 'UniformOutput', false);
            this.trialTrigData = cellfun(@(x) allTrigData(find(allTrialInd == x), :), ind, 'UniformOutput', false);
            this.trialTrackData = cellfun(@(x) allTrackData(find(allTrialInd == x), :), ind, 'UniformOutput', false);
            
            % Set default playback frame range to full video
            this.frameRange = cellfun(@(x) (1:length(x))', this.trialTimeStamps, 'UniformOutput', false);
        end
        
        
        
        
        
        function LoadVideo(this, trialIdx, varargin)
            this.vidIdx = trialIdx;
            
            p = inputParser;
            addParameter(p, 'frameBegin', this.frameRange{trialIdx}(1), @isnumeric);
            addParameter(p, 'frameEnd', this.frameRange{trialIdx}(end), @isnumeric);
            addParameter(p, 'play', false, @islogical);
            addParameter(p, 'figNum', 0, @isnumeric);
            addParameter(p, 'frameRate', this.vidObjs{trialIdx}.FrameRate, @isnumeric);
            
            parse(p, varargin{:});
            frb = p.Results.frameBegin;
            fre = p.Results.frameEnd;
            frb = max(frb, 1);
            fre = min(fre, length(this.trialTimeStamps{trialIdx}));
            this.frameRange{trialIdx} = frb:fre;
            
            figNum = p.Results.figNum;
            ifPlay = p.Results.play;
            frRate = p.Results.frameRate;
            
            % Preallocate space for video data
            this.vid = zeros(this.vidObjs{trialIdx}.Height, this.vidObjs{trialIdx}.Width, ...
                    length(frb:fre), 'uint8');
            
            % Read video
            if ifPlay
                if figNum <= 0
                    figure;
                else
                    figure(figNum);
                end
                
                numTrack = 1;
                hImage = imagesc(repmat(this.anaRt.avgBaseline,1,1,3));
                hold on;
                hTrack = scatter(NaN(numTrack,1), NaN(numTrack,1), linspace(1,25,numTrack), linspace(1,10,numTrack), 'fill');
                hFrame = text(20, 30, num2str(0), 'Color', 'w', 'FontSize', 15);
                hTime = text(20, 60, num2str(0, '%7.3f s'), 'Color', 'w', 'FontSize', 15);
                hold off;
                axis off ij equal;
                
                for fr = frb:fre
                    tic;
                    this.vid(:,:,fr-frb+1) = read(this.vidObjs{trialIdx}, fr);
                    
                    set(hImage, 'CData', repmat(this.vid(:,:,fr-frb+1),1,1,3));
                    set(hTrack, 'XData', this.trialTrackData{this.vidIdx}(fr-numTrack+1:fr, 2));
                    set(hTrack, 'YData', this.trialTrackData{this.vidIdx}(fr-numTrack+1:fr, 1));
                    set(hFrame, 'String', num2str(fr));
                    set(hTime, 'String', num2str(this.trialTimeStamps{this.vidIdx}(fr), '%7.3f s'));
                    drawnow;
                    pause(max(1/frRate-toc, 0));
                end
            else
                for fr = frb:fre
                    this.vid(:,:,fr-frb+1) = read(this.vidObjs{trialIdx}, fr);
                end
            end
        end
        
        function PlayCurrentVideo(this, varargin)
            p = inputParser;
            addParameter(p, 'frameBegin', this.frameRange{this.vidIdx}(1), @isnumeric);
            addParameter(p, 'frameEnd', this.frameRange{this.vidIdx}(end), @isnumeric);
            addParameter(p, 'figNum', 0, @isnumeric);
            addParameter(p, 'frameRate', this.vidObjs{this.vidIdx}.FrameRate, @isnumeric);
            
            parse(p, varargin{:});
            frb = p.Results.frameBegin;
            fre = p.Results.frameEnd;
            frb = max(frb, this.frameRange{this.vidIdx}(1));
            fre = min(fre, this.frameRange{this.vidIdx}(end));
            
            frRate = p.Results.frameRate;
            figNum = p.Results.figNum;
            if figNum <= 0
                figure;
            else
                figure(figNum);
            end
            
            numTrack = 1;
            hImage = imagesc(repmat(this.anaRt.avgBaseline,1,1,3));
            hold on;
            hTrack = scatter(NaN(numTrack,1), NaN(numTrack,1), linspace(1,25,numTrack), linspace(1,10,numTrack), 'fill');
            hFrame = text(20, 30, num2str(0), 'Color', 'w', 'FontSize', 15);
            hTime = text(20, 60, num2str(0, '%7.3f s'), 'Color', 'w', 'FontSize', 15);
            hold off;
            axis off ij equal;
            
            for fr = frb:fre
                tic;
                set(hImage, 'CData', repmat(this.vid(:,:,fr-this.frameRange{this.vidIdx}(1)+1),1,1,3));
                set(hTrack, 'XData', this.trialTrackData{this.vidIdx}(fr-numTrack+1:fr, 2));
                set(hTrack, 'YData', this.trialTrackData{this.vidIdx}(fr-numTrack+1:fr, 1));
                set(hFrame, 'String', num2str(fr));
                set(hTime, 'String', num2str(this.trialTimeStamps{this.vidIdx}(fr), '%7.3f s'));
                drawnow;
                pause(max(1/frRate-toc, 0));
            end
        end
        
        
        
        
        
        function PlotTracking(this, varargin)
            p = inputParser;
            addParameter(p, 'trialIdx', this.vidIdx, @isnumeric);
            addParameter(p, 'frameBegin', this.frameRange{this.vidIdx}(1), @isnumeric);
            addParameter(p, 'frameEnd', this.frameRange{this.vidIdx}(end), @isnumeric);
            addParameter(p, 'figNum', 0, @isnumeric);
            
            parse(p, varargin{:});
            idx = p.Results.trialIdx;
            frb = p.Results.frameBegin;
            fre = p.Results.frameEnd;
            frb = max(frb, this.frameRange{this.vidIdx}(1));
            fre = min(fre, this.frameRange{this.vidIdx}(end));
            figNum = p.Results.figNum;
            if figNum <= 0
                figure;
            else
                figure(figNum);
            end
            
            plot3(this.trialTrackData{idx}(frb:fre,2), ...
                frb:fre, ...
                this.trialTrackData{idx}(frb:fre,1), ...
                'o-');
            set(gca, 'ZDir', 'reverse');
            xlim([ this.anaRt.roiContours{2}(1,1) this.anaRt.roiContours{2}(3,1) ]); % Range mismatch
            zlim([ this.anaRt.roiContours{2}(1,2) this.anaRt.roiContours{2}(3,2) ]);
            grid on
        end
        
    end
    
end

