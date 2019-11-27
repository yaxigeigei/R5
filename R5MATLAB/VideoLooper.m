classdef VideoLooper < handle
    %VIDEOLOOPER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        numDisp = 150;
        frameRate;
        frameCounter = 0;
    end
    
    methods
        function this = VideoLooper()
        end
        
        function Preview(this, handles)
            % Initialize plots
            % Image
            anaCfg = getappdata(handles.output, 'anaCfg');
            axes(handles.axes3);
            phs.Image = image(anaCfg.avgBaseline);
            axis off
            % ROI
            hold(handles.axes3, 'on');
            anaCfg.ShowROI();
            hold(handles.axes3, 'off');
            
            % Get global variables
            cam = getappdata(handles.output, 'cam');
            % Prepare camera
            stoppreview(cam);
            src = getselectedsource(cam);
            % Get frame rate
            try % assume it is a Gige Vision camera
                this.frameRate = src.AcquisitionFrameRateAbs;
            catch % otherwise try generic camera
                this.frameRate = str2double(src.FrameRate);
            end
            triggerconfig(cam, 'manual');
            cam.FramesPerTrigger = inf;
            cam.TriggerRepeat = 1;
            cam.FrameGrabInterval = 1;
            cam.FramesAcquiredFcnCount = 1;
            cam.FramesAcquiredFcn = { @this.PreviewFramesCallback, phs };
            cam.StopFcn = { @this.PreviewStopCallback, handles, phs };
            cam.DiskLogger = [];
            cam.LoggingMode = 'memory';
            % Start camera
            start(cam);
            trigger(cam);
        end
        
        function PreviewFramesCallback(this, cam, event, phs)
            frRemain = cam.FramesAvailable;
            newFrame = getdata(cam, frRemain); % read all frame from buffer
            set(phs.Image, 'CData', newFrame(:,:,1)); % only display the first one
            this.frameCounter = this.frameCounter + 1;
        end
        
        function PreviewStopCallback(this, cam, event, handles, phs)
            this.frameCounter = 0;
            anaCfg = getappdata(handles.output, 'anaCfg');
            set(phs.Image, 'CData', anaCfg.avgBaseline); % only display the first one
        end
        
        
        
        
        
        function Start(this, handles)
            % Get global variables
            cam = getappdata(handles.output, 'cam');
            stoppreview(cam);
            src = getselectedsource(cam);
            
            % Create analysis runtime object based on analysis configuration object
            anaCfg = getappdata(handles.output, 'anaCfg');
            anaRt = AnalysisRuntime(anaCfg);
            % Read user settings on the GUI
            epochTime = str2double(get(handles.epochTimeEdit, 'String'));
            anaRt.logVideo = get(handles.saveMovCheckbox,'Value');
            % Get frame rate
            try % assume it is a Gige Vision camera
                anaRt.frameRate = src.AcquisitionFrameRateAbs;
            catch % otherwise try generic camera
                anaRt.frameRate = str2double(src.FrameRate);
            end
            this.frameRate = anaRt.frameRate;
            if epochTime > 0 && epochTime <= 1800 % trial duration must be greater than 0 and less than 30min
                anaRt.rtMode = 'trials';
                anaRt.frPool = zeros([ size(anaRt.avgBaseline), round(anaRt.frameRate * epochTime) ], 'uint8');
            else % otherwise go with 'freerun' mode
                set(handles.epochTimeEdit, 'String', 'inf');
                anaRt.rtMode = 'freerun';
            end
            % Save anaRt as global variable
            setappdata(handles.output, 'anaRt', anaRt);
            
            % Initialize Plots
            % Frame rate
            phs.FrameRate = plot(handles.axes1, NaN(this.numDisp-1,1));
            axis tight;
            % Trigger
            if ~isempty(anaRt.roiTrg)
                phs.TrigData = plot(handles.axes2, zeros(this.numDisp, length(anaRt.roiTrg)));
                % handles.axes2.ColorOrderIndex = 1; % only works in MATLAB 2015a
                hold(handles.axes2, 'on');
                phs.TrigEvent = plot(handles.axes2, NaN(this.numDisp, length(anaRt.roiTrg)), 'o');
                % handles.axes2.ColorOrderIndex = 1; % only works in MATLAB 2015a
                trigThresh = zeros(length(anaRt.roiTrg),1);
                phs.TrigThresh = plot(handles.axes2, [1, this.numDisp], [ trigThresh, trigThresh ]);
                % handles.axes2.ColorOrderIndex = 1; % only works in MATLAB 2015a
                hold(handles.axes2, 'off');
                axis tight;
            end
            % Tracking
            numTrack = 25;
            phs.Image = imagesc(repmat(anaRt.avgBaseline,1,1,3), 'Parent', handles.axes3);
            hold(handles.axes3, 'on');
            for i = 1 : length(anaRt.roiTrk)
                phs.Track(i) = scatter(handles.axes3, NaN(numTrack,1), NaN(numTrack,1), ...
                    linspace(1,50,numTrack), linspace(1,10,numTrack), 'fill');
            end
            axis off ij equal;
            % ROI boundary
            anaCfg.ShowROI();
            hold(handles.axes3, 'off');
            
            % Prepare camera
            triggerconfig(cam, 'manual');
            cam.FramesPerTrigger = inf;
            cam.TriggerRepeat = 1;
            cam.FrameGrabInterval = 1;
            cam.FramesAcquiredFcnCount = 1;
            cam.FramesAcquiredFcn = { @this.AcqFramesCallback, handles, phs };
            cam.StopFcn = { @this.AcqStopCallback, handles };
            cam.DiskLogger = [];
            cam.LoggingMode = 'memory';
            if anaRt.logVideo && strcmp(anaRt.rtMode, 'freerun')
                cam.LoggingMode = 'disk&memory';
                cam.DiskLogger = VideoWriter(anaRt.fileName, 'Grayscale AVI');
            end
            
            % Start camera
            start(cam);
            trigger(cam);
        end
        
        function AcqFramesCallback(this, cam, event, handles, phs)
            % Get the global variables
            anaRt = getappdata(handles.output, 'anaRt');
            
            % Update tuning
            if anaRt.IfRefresh(5) % retrieve info from GUI #times per second
                if ~isempty(anaRt.roiTrg) % make sure there is a ROI
                    trgInfo = get(handles.roiTable, 'Data'); % retrieve info from GUI table control
                    for i = 1 : length(anaRt.roiTrg)
                        anaRt.roiTrg{i}.SaveFirstRule(trgInfo(i,:));
                    end
                end
            end
            
            % Retrieve frame
            [ newFrame, timestamp ] = getdata(cam, 1); % read one (the oldest) frame from buffer
            if this.IfRefresh(15) % refresh #times per second
                set(handles.frInBuffText, 'String', num2str(cam.FramesAvailable)); % show #remaining frames in buffer
            end
            
            % Data logging and computing
            anaRt.LogTimeStamp(timestamp, newFrame);        % Log time stamp and new frame
            trigBools = anaRt.LogTrigger();                 % Compute, log and get triggering states
            anaRt.LogTracking();                            % Compute and log tracking
            
            % Feedback control
            serialObj = getappdata(handles.output, 'serialObj');
            serialObj.Dispatch(handles, trigBools); % send triggers into action
            
            % Handle epoches
            if strcmp(anaRt.rtMode, 'trials') % only process trials when it's in 'trials' mode
                isFull = anaRt.LogFrame(newFrame); % save new frame into frame pool, return true if the pool is full
                if isFull % if the pool is full (i.e. it was the last frame of the epoch)
                    % Stop camera
                    stop(cam);
                    % Take back the food a bit
                    serialObj.Send('-300f');
                    
                    % Log pellet presence/absence
                    pelletTrigIdx = 1;
                    if ~isempty(anaRt.roiTrg) % make sure the triggering ROI is not empty
                        trigVal = anaRt.GetPastTrigger(pelletTrigIdx,1);
                        [ ~, ~, ~, dRaw ] = anaRt.roiTrg{pelletTrigIdx}.Decide(trigVal);
                        anaRt.LogPelletState(~dRaw(1)); % log pellet status
                    end
                    
                    % In case the mouse knocked the pellet down at the very end of the trial
                    pause(3); % wait for any pellet to completely drop down (will be logged automatically)
                    set(handles.historyListbox, 'String', { }); % clear GUI components to reduce rendering
                    
                    % Get trail results and plot
                    bs = anaRt.GetPerformance(60);  % # is the number of trials to plot at the same time
                    stem(handles.axes4, bs.plotInd, bs.hitVect(bs.plotInd), 'g', 'Marker', 'none');
                    hold(handles.axes4, 'on');
                    stem(handles.axes4, bs.plotInd, bs.failVect(bs.plotInd), 'r', 'Marker', 'none');
                    stem(handles.axes4, bs.plotInd, bs.missVect(bs.plotInd), 'Color', [ .5 .5 .5 ], 'Marker', 'none');
                    plot(handles.axes4, bs.plotInd, bs.dropVectNorm(bs.plotInd), 'kv');
                    plot(handles.axes4, bs.plotInd, bs.remainVect(bs.plotInd), 'ko');
                    set(handles.axes4, 'XLim', [ bs.plotInd(1)-1, bs.plotInd(end)+1 ]);
                    hold(handles.axes4, 'off');
                    % Update statistics
                    set(handles.hitText, 'String', [ num2str(round(bs.hitRate*100)), '%  ', num2str(bs.hitNum) ]); 
                    set(handles.failText, 'String', [ num2str(round(bs.failRate*100)), '%  ', num2str(bs.failNum) ]); 
                    set(handles.missText, 'String', [ num2str(round(bs.missRate*100)), '%  ', num2str(bs.missNum) ]); 

                    % Finish this epoch 
                    anaRt.FinishEpoch(); % Update/reset epoch status, export video when required
                    % Check for pending pause
                    while ~anaRt.trialProceed
                        pause(0.1);
                    end
                    % Start next epoch
                    for i = 1 : length(anaRt.roiTrg)
                        anaRt.roiTrg{i}.Reset();
                    end
                    start(cam);
                    trigger(cam);
                end
            end
            
            % Update Plots
            if cam.FramesAvailable < 3 % update plot only when little frames have yet to be processed
                if anaRt.IfRefresh(1) % refresh frame rate plot #times per second
                    set(phs.FrameRate, 'YData', 1./diff(anaRt.GetPastTimeStamp(this.numDisp))); % frame rate calculated from time stamps
                end

                if anaRt.IfRefresh(15) % refresh triggering plot #times per second
                    for i = 1 : length(anaRt.roiTrg)
                        set(phs.TrigThresh(i), 'YData', repmat(anaRt.roiTrg{i}.infoTable.Threshold(1),1,2));
                        set(phs.TrigData(i), 'YData', anaRt.GetPastTrigger(i,this.numDisp));
                        set(phs.TrigEvent(i), 'YData', anaRt.GetPastTrigEvent(i,this.numDisp));
                    end
                end

                if anaRt.IfRefresh(30) % refresh image and tracking plot #times per second
                    numTrack = 25; % #data points in each the tracking trajectory
                    set(phs.Image, 'CData', repmat(newFrame,1,1,3));
                    for i = 1 : length(anaRt.roiTrk)
                        set(phs.Track(i), 'XData', anaRt.GetPastTrackPos(i,2,numTrack));
                        set(phs.Track(i), 'YData', anaRt.GetPastTrackPos(i,1,numTrack));
                    end
                end
            elseif cam.FramesAvailable > 50 % if unprocessed frames keep accumulating
                stop(cam);
                cam.FramesAcquiredFcn = { }; % clear frame capture callback
                cam.StopFcn = { }; % clear camera stop callback
                
                anaRt.FinishEpoch();
                anaRt.ExportData(); % export acquried data
                
                set(handles.startButton, 'String', 'Start'); % reset GUI button
                set(handles.frInBuffText, 'String', ''); % reset GUI label

                msgbox(sprintf([ 'The speed of this computer may not support the current workload\n' ...
                    'Try reduing the frame rate or analysis complexity\n' ...
                    'or upgrading your computer...' ]), 'Not Enough Resource');
            end
            
            % Save changes to analysis runtime object
            setappdata(handles.output, 'anaRt', anaRt);
        end
        
        
        
        function AcqStopCallback(this, cam, event, handles)
            % Reset frame counter
            this.frameCounter = 0;
        end
        
        
        
        
        function b = IfRefresh(this, targetFrameRate)
            refreshPeriod = ceil(this.frameRate / targetFrameRate);
            b = ~mod(this.frameCounter, refreshPeriod);
        end
    end
    
end

