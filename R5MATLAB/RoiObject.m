classdef RoiObject < matlab.mixin.Copyable
    %ROIOBJECT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        x = [];         % x coordinates of ROI contour
        y = [];         % y coordinates of ROI contour
        mask = [];      % binary(logical) mask of ROI
        c = 'r';        % color of contour when ROI is displayed
    end
    
    methods
        function this = RoiObject(varargin)
            p = inputParser;
            addParameter(p, 'Color', this.c);
            parse(p, varargin{:});
            this.c = p.Results.Color;
        end
        
        
        
        function SelectNew(this, varargin)
            p = inputParser;
            addParameter(p, 'Color', this.c);
            addParameter(p, 'Image', [], @isnumeric);
            
            parse(p, varargin{:});
            this.c = p.Results.Color;
            img = p.Results.Image;
            
            if isempty(img)
                [ this.mask, this.x, this.y ] = roipoly;
            else
                [ this.mask, this.x, this.y ] = roipoly(img);
            end
            
            this.ShowContour('Color', this.c);
        end
        
        
        
        function Modify(this, varargin)
            if ~isempty(this.x)
                p = inputParser;
                addParameter(p, 'Color', this.c);
                addParameter(p, 'Index', []);
                addParameter(p, 'Image', [], @isnumeric);

                parse(p, varargin{:});
                this.c = p.Results.Color;
                idx = p.Results.Index;
                img = p.Results.Image;
                
                this.ShowContour('Color', this.c, 'Image', img, 'Index', idx);
                if isempty(img)
                    [ row, col ] = size(this.mask);
                    [ this.mask, this.x, this.y ] = roipoly(row, col, this.x, this.y);
                else
                    [ this.mask, this.x, this.y ] = roipoly(img, this.x, this.y);
                end
                this.ShowContour('Color', this.c, 'Image', img, 'Index', idx);
            else
                msgbox('You do not have a ROI to modify. Please obj.SelectNew() first.');
            end
        end
        
        
        
        function ShowContour(this, varargin)
            p = inputParser;
            addParameter(p, 'Color', this.c);
            addParameter(p, 'Index', []);
            addParameter(p, 'Image', [], @isnumeric);
            
            parse(p, varargin{:});
            color = p.Results.Color;
            idx = p.Results.Index;
            img = p.Results.Image;
            
            if ~isempty(img)
                imshow(img);
            end
            
            hold on
            plot(this.x, this.y, 's', 'LineStyle', '-', 'MarkerSize', 2, 'Color', color, 'MarkerEdgeColor', color);
            if ~isempty(idx)
                text(max(this.x), max(this.y), num2str(idx), 'Color', color);
            end
            hold off
        end
        
        
        
        function ShowMask(this, newFig)
            if nargin < 2
                newFig = true;
            end
            if newFig
                figure;
            end
            imshow(this.mask);
        end
        
        
        
        
        
        
        function SelectNew_Obsolete(this, varargin)
            p = inputParser;
            addParameter(p, 'Color', 'r');
            addParameter(p, 'Shape', 'rectangle', @ischar);
            
            parse(p, varargin{:});
            shape = p.Results.Shape;
            this.c = p.Results.Color;
            
            switch shape
                case 'rectangle'
                    hROI = imrect;
                case 'ellipse'
                    hROI = imellipse;
                case 'polygon'
                    hROI = impoly;
                case 'freehand'
                    hROI = imfreehand;
            end
            
            hROI.setColor(this.c);
            if strcmp(shape, 'polygon') || strcmp(shape, 'freehand')
                hROI.setClosed(true);
            end
            
            wait(hROI);
            contour = getPosition(hROI);
            if strcmp(shape, 'rectangle')
                contour = this.Rect2Contour(contour);
            end
            this.y = contour(:,1);
            this.x = contour(:,2);
            this.mask = createMask(hROI);
            
            this.OldShow('Color', this.c);
        end
        
        
        
        function contour = Rect2Contour(~, rectangle)
            minX = rectangle(1);
            maxX = rectangle(1) + rectangle(3);
            minY = rectangle(2);
            maxY = rectangle(2) + rectangle(4);
            
            contour = [ minX, minY; minX, maxY; maxX, maxY; maxX, minY; minX, minY ];
        end
        
    end
end

