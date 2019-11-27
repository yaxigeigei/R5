classdef SerialObject < handle
    %SERIALOBJECT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        serialObj;
    end
    
    methods
        function this = SerialObject(portNum, varargin)
            p = inputParser;
            addParameter(p, 'BaudRate', 115200, @isnumeric);
            addParameter(p, 'GuiHandle', []);
            addParameter(p, 'Listen', false, @islogical);
            
            parse(p, varargin{:});
            baudRate = p.Results.BaudRate;
            h = p.Results.GuiHandle;
            isListen = p.Results.Listen;
            
            this.serialObj = serial(portNum, 'BaudRate', baudRate);
            try
                % Open serial communication
                fopen(this.serialObj);
                if isListen
                    % Setup asynchronous read for ByteAvailable callback
                    readasync(this.serialObj);
                    % Setup ByteAvailable callback for processing incoming strings
                    this.serialObj.BytesAvailableFcnMode = 'terminator';
                    this.serialObj.BytesAvailableFcn = { @this.ReadReport, h };
                end
                if ~isempty(h)
                    % Change button name for disconnection
                    set(h.comButton, 'String', 'Disconnect');
                end
            catch
            end
        end
        
        
        
        function Send(this, cmd, ifDisp, handles)
            if nargin < 4
                ifDisp = false;
            end
            
            try
                % Send command
                fprintf(this.serialObj, cmd);
                
                % If display is required
                if ifDisp
                    history = cellstr(get(handles.historyListbox, 'String'));
                    history{end+1} = [ '>> ', cmd ];
                    set(handles.historyListbox, 'String', history);
                    set(handles.historyListbox, 'Value', length(history));
                end
            catch
                this.Close();
                disp('Failed to send - serial port closed');
            end
        end
        
        
        
        
        function Dispatch(this, handles, trigBools)
            trigIdx = find(trigBools);
            for i = 1 : length(trigIdx)
                switch trigIdx(i)
                    case 1
                        this.Send('5f', false, handles);
                    otherwise
                end
            end
        end
        
        
        
        
        
        function ReadReport(serialObj, event, h)
            incomingStr = fscanf(serialObj);
            printInput = false;
            try
                if length(incomingStr) > 2
                    switch incomingStr(1)
                        case 'd'
                            if isappdata(h.output, 'anaRt')
                                anaRt = getappdata(h.output, 'anaRt');
                                anaRt.LogDropping();
                            end
                        otherwise
                            printInput = true;
                    end
                else
                    printInput = true;
                end

                if printInput
                    history = get(h.historyListbox, 'String');
                    history{end+1} = strtrim(incomingStr);
                    set(h.historyListbox, 'String', history);
                    set(h.historyListbox, 'Value', length(history));
                end
            catch
                this.Close(h);
            end
        end


        
        
        
        function Close(this, handles)
            try
                % Close serial communication and clear memory
                fclose(this.serialObj);
                delete(this.serialObj);
                if nargin > 1
                    % Restore button name
                    set(handles.connectButton, 'String', 'Connect');
                end
            catch
            end
        end
        
        
    end
    
end

