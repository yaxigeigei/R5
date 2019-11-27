classdef RoiTrigger < RoiObject
    %ROITRIGGERING Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        infoTable = table();
        variableNames = { 'Threshold', 'Mode', 'Repeat', 'NumPass', 'Dependency', 'Role' };
        defaultVals = { 50, 'supra', inf, 0, 0, 'activator' };
        
        maxDecision = inf;
        decisionCount = 0;
    end
    
    methods
        function this = RoiTrigger()
            this@RoiObject('Color', 'r');
            this.infoTable = cell2table(this.defaultVals, 'VariableNames', this.variableNames);
        end
        
        function AddRule(this)
            newTable = cell2table(this.defaultVals, 'VariableNames', this.variableNames);
            this.infoTable = [ this.infoTable; newTable ];
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
        
        function SaveFirstRule(this, newInfo)
            nPass = this.infoTable.NumPass(1);
            for i = [ 1, 3, 4, 5 ]
                if ischar(newInfo{i})
                    newInfo{i} = str2double(newInfo{i});
                end
            end
            this.infoTable(1,:) = cell2table(newInfo, 'VariableNames', this.variableNames);
            this.infoTable.NumPass(1) = nPass;
        end
        
        function DeleteRule(this, idx)
            if size(this.infoTable,1) > 1
                this.infoTable(idx,:) = [ ];
            end
        end
        
        
        
        function [ dTrg, dDep, dTim, dRaw ] = Decide(this, trigVal)
            % Check threshold passing
            dRaw = false(size(this.infoTable,1),1);
            for i = 1 : length(dRaw)
                threshSign = sign(this.infoTable.Threshold(i));
                threshAbs = abs(this.infoTable.Threshold(i));
                dRaw(i) = threshSign == sign(trigVal) && abs(trigVal) > threshAbs;
                % Invert it if triggering at baseline (sign independent)
                if strcmp(this.infoTable.Mode{i}, 'sub')
                    dRaw(i) = ~dRaw(i);
                end
            end
            dTim = dRaw;
            
            % Check trigger number
            for i = 1 : length(dTim)
                if this.infoTable.NumPass(i) >= this.infoTable.Repeat(i)
                    dTim(i) = false;
                end
            end
            dDep = dTim;
            
            % Check dependency
            for i = 1 : length(dDep)
                if this.infoTable.Dependency(i)
                    depIdx = abs(this.infoTable.Dependency(i));
                    synergic = this.infoTable.Dependency(i) > 0;
                    if synergic && this.infoTable.NumPass(depIdx) >= this.infoTable.Repeat(depIdx)
                        dDep(i) = false;
                        this.infoTable.NumPass(i) = this.infoTable.Repeat(i);
                    end
                    if ~synergic && this.infoTable.NumPass(depIdx) < this.infoTable.Repeat(depIdx)
                        dDep(i) = false;
                    end
                end
                
                % Count trigger
                if dDep(i)
                    this.infoTable.NumPass(i) = this.infoTable.NumPass(i) + 1;
                end
            end
            
            % Summarize
            dTrg = max(dDep);
            
            % Check veto
            for i = 1 : length(dDep)
                if strcmp(this.infoTable.Role{i}, 'veto') && dDep(i)
                    dTrg = false;
                end
            end
            
            % Check auto-reset
            this.decisionCount = this.decisionCount + 1;
            if this.decisionCount >= this.maxDecision
                this.Reset();
            end
            
%             disp(this.infoTable.NumPass');
        end
        
        function Reset(this)
            this.decisionCount = 0;
            for i = 1 : size(this.infoTable,1)
                this.infoTable.NumPass(i) = 0;
            end
        end
    end
    
end

