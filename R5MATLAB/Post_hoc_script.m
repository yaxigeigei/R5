%% Read data

% User selects the .mat file of a session
[ anaRtName, folderName ] = uigetfile();

% Get the file name without extension
[ ~, fileNameNE, fileExt ] = fileparts(anaRtName);

% Use the name and wildcards to find all associated video
vidPaths = findfiles_all_subpath(fullfile(folderName, [ fileNameNE, '*.avi' ]));

% Sort video file paths in the cell array with ascending trial number
[ ~, vidNameNE, ~ ] = cellfun(@fileparts, vidPaths, 'UniformOutput', false);
vidInd = cellfun(@(x) x(length(fileNameNE)+2 : end), vidNameNE, 'UniformOutput', false);
vidInd = cellfun(@str2double, vidInd);
[ ~, vidOrder ] = sort(vidInd);
vidPaths = vidPaths(vidOrder);

% Load data
anaRd = AnalysisReader(fullfile(folderName, anaRtName), vidPaths);


%% Video examination with tracking

% 8     fr:180-220 few points
% 9     fr:220-300 reach and hold
% 10    fr:2-300 hold and retract
trialIdx = 8;

frb = 2;
fre = 300;

anaRd.LoadVideo(trialIdx, 'play', true, 'figNum', 1, 'frameRate', 10, ...
    'frameBegin', frb, 'frameEnd', fre);

% anaRd.PlayCurrentVideo('figNum', 1, 'frameRate', 2, 'frameBegin', 180, 'frameEnd', 220);
% anaRd.PlotTracking('figNum', 2, 'frameBegin', frb, 'frameEnd', fre);


%% Retracking

cfgName = 'cfg_analysis.mat';
load(fullfile(folderName, cfgName));

% dVid = diff(int16(vid), 1, 3);
% dVid = uint8(abs(dVid));
% dVid(dVid < 50) = 0;
% implay(dVid);

anaCfg2 = anaCfg;
anaCfg2.roiInfo{1,4} = 50;
anaCfg2.roiInfo{1,5} = 150;
anaRt2 = AnalysisRuntime(anaCfg2);
for fr = frs:fre
    anaRt2.LogTimeStamp(0, vid(:, :, fr-frs+1));
    anaRt2.LogTracking();
end
anaRd2 = AnalysisReader(anaRt2);


%% Manual Curation

[ ~, vects, points ] = StackManualReg(vid);

figure(3)
plot3(frs:fre, anaRdr.trackData(1:fre-frs+1,2), anaRdr.trackData(1:fre-frs+1,1), 'ro-');
hold on;
plot3(frs:fre, points(1:fre-frs+1,1), points(1:fre-frs+1,2), 'bo-');
set(gca, 'ZDir', 'reverse', 'YDir', 'reverse');
ylim([ anaRdr.anaRt.roiContours{2}(1,1)-50 anaRdr.anaRt.roiContours{2}(3,1) ]);
zlim([ anaRdr.anaRt.roiContours{2}(1,2) anaRdr.anaRt.roiContours{2}(3,2) ]);
grid on
hold off


%% 

tempArray = NaN(1000, 2);
for i = 1 : size(tempArray,1)
    if ~isempty(obj.bTable.Drop{i})
        tempArray(i,1) = obj.bTable.Drop{i};
    end
    if ~isempty(obj.bTable.Remain{i})
        tempArray(i,2) = obj.bTable.Remain{i};
    end
end
obj.bTable.Drop = tempArray(:,1);
obj.bTable.Remain = tempArray(:,2);

save(obj.fileName, 'obj');



