classdef RoiTracking < RoiObject
    %ROITRACKING Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        infoTable = table();
        variableNames = { 'Threshold', 'Tolerance', 'Direction' };
        defaultVals = { 50, 250, 'up' };
    end
    
    methods
        function this = RoiTracking()
            this@RoiObject('Color', 'b');
            this.infoTable = cell2table(this.defaultVals, 'VariableNames', this.variableNames);
        end
        
        function AddRule(this)
            
        end
        
        function SaveRule(this, newInfo)
            for i = [ 1, 3, 4, 5 ]
                for j = 1 : size(newInfo,1)
                    if ischar(newInfo{j,i})
                        newInfo{j,i} = str2double(newInfo{j,i});
                    end
                end
            end
            this.infoTable = cell2table(newInfo, 'VariableNames', this.variableNames);
        end
        
        function DeleteRule(this, idx)
            if size(this.infoTable,1) > 1
                this.infoTable(idx,:) = [ ];
            end
        end
        
        
        
        function [ r, c ] = Track(this, mdFr)
            r = NaN;
            c = NaN;
            diffRoi = abs(mdFr .* this.mask);
            [ rowInd, columnInd ] = ind2sub(size(diffRoi), find(diffRoi > this.infoTable.Threshold(1)));
            if length(columnInd) > this.infoTable.Tolerance(1)
                switch this.infoTable.Direction{1}
                    case 'up'
                        [ ~, sortedInd ] = sort(rowInd, 'ascend');
                    case 'down'
                        [ ~, sortedInd ] = sort(rowInd, 'descend');
                    case 'left'
                        [ ~, sortedInd ] = sort(columnInd, 'ascend');
                    otherwise
                        [ ~, sortedInd ] = sort(columnInd, 'descend');
                end
                tipInd = sortedInd(1:this.infoTable.Tolerance(1));
                r = mean(rowInd(tipInd));
                c = mean(columnInd(tipInd));
            end
        end
    end
    
end

