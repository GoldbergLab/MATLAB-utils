classdef VideoAnnotator < VideoBrowser
    % VideoAnnotator A VideoBrowser subclass for creating, editing, and
    %   exporting labeled frame-range annotations on a video.
    %
    %   Usage:
    %       1. Drag on the navigation axes to select a frame range
    %          (existing VideoBrowser FrameSelection behavior).
    %       2. Press Enter to convert the selection into one or more
    %          annotations, prompting for text for each contiguous
    %          range.
    %       3. Click an annotation bar to select it; right-click for
    %          a context menu (Edit text / Edit range / Delete).
    %       4. With an annotation selected: Enter edits its text,
    %          Delete removes it, Escape deselects it.
    %       5. Ctrl+I imports annotations from CSV; Ctrl+E exports.
    %
    %   CSV format: three columns named StartFrame, EndFrame, Text.

    properties (SetObservable)
        Annotations = struct('StartFrame', {}, 'EndFrame', {}, 'Text', {})
    end
    properties
        AnnotationColor          = [0.2, 0.8, 0.4, 0.4]   % RGBA face for unselected annotations
        AnnotationSelectedColor  = [1.0, 0.6, 0.2, 0.7]   % RGBA face for the selected annotation
        AnnotationHeightFraction = 0.25                   % Fraction of nav-axes height taken by the annotation bar
    end
    properties (Access = protected)
        AnnotationRects        matlab.graphics.primitive.Rectangle  % flat list, layout (annotation, axes)
        AnnotationTexts        matlab.graphics.primitive.Text       % flat list, parallel to AnnotationRects
        AnnotationContextMenus matlab.ui.container.ContextMenu      % per-annotation, owned so they can be cleaned up
        AnnotationRows         double = []                          % cached row index per annotation (overlap layout)
        SelectedAnnotation     double = []
        FrameSelectionLayerListener  event.listener                 % keeps annotations on top of FrameSelection redraws
    end
    methods
        function obj = VideoAnnotator(varargin)
            obj@VideoBrowser(varargin{:});
            % Selection-highlight rectangles in the base class are drawn
            % into the same axes as our annotations and would otherwise
            % paint over them; restack on every FrameSelection change.
            obj.FrameSelectionLayerListener = addlistener(obj, ...
                'FrameSelection', 'PostSet', ...
                @(~,~)obj.bringAnnotationsToFront());
        end

        function delete(obj)
            if ~isempty(obj.FrameSelectionLayerListener) && isvalid(obj.FrameSelectionLayerListener)
                delete(obj.FrameSelectionLayerListener);
            end
            obj.clearAnnotationGraphics();
            % Super destructor runs automatically after this returns.
        end

        % --- Public API ---

        function addAnnotation(obj, startFrame, endFrame, text)
            arguments
                obj VideoAnnotator
                startFrame (1,1) double {mustBePositive, mustBeInteger}
                endFrame   (1,1) double {mustBePositive, mustBeInteger}
                text       (1,:) char = ''
            end
            if startFrame > endFrame
                tmp = startFrame; startFrame = endFrame; endFrame = tmp;
            end
            startFrame = max(1, startFrame);
            if obj.getNumFrames() > 0
                endFrame = min(obj.getNumFrames(), endFrame);
            end
            ann = struct('StartFrame', startFrame, 'EndFrame', endFrame, 'Text', text);
            obj.Annotations(end+1) = ann;
            obj.drawAnnotations();
        end

        function deleteAnnotation(obj, idx)
            if idx < 1 || idx > numel(obj.Annotations); return; end
            obj.Annotations(idx) = [];
            if isequal(obj.SelectedAnnotation, idx)
                obj.SelectedAnnotation = [];
            elseif ~isempty(obj.SelectedAnnotation) && obj.SelectedAnnotation > idx
                obj.SelectedAnnotation = obj.SelectedAnnotation - 1;
            end
            obj.drawAnnotations();
        end

        function editAnnotationText(obj, idx)
            if idx < 1 || idx > numel(obj.Annotations); return; end
            answer = inputdlg('Annotation text:', 'Edit annotation', [1, 60], ...
                {obj.Annotations(idx).Text});
            if isempty(answer); return; end
            obj.Annotations(idx).Text = answer{1};
            obj.drawAnnotations();
        end

        function editAnnotationRange(obj, idx)
            if idx < 1 || idx > numel(obj.Annotations); return; end
            answer = inputdlg({'Start frame:', 'End frame:'}, ...
                'Edit annotation range', [1, 30; 1, 30], ...
                {num2str(obj.Annotations(idx).StartFrame), ...
                 num2str(obj.Annotations(idx).EndFrame)});
            if isempty(answer); return; end
            s = round(str2double(answer{1}));
            e = round(str2double(answer{2}));
            if isnan(s) || isnan(e)
                warndlg('Invalid frame number.', 'Edit annotation range');
                return;
            end
            if s > e; tmp = s; s = e; e = tmp; end
            s = max(1, s);
            if obj.getNumFrames() > 0
                e = min(obj.getNumFrames(), e);
            end
            obj.Annotations(idx).StartFrame = s;
            obj.Annotations(idx).EndFrame   = e;
            obj.drawAnnotations();
        end

        function selectAnnotation(obj, idx)
            % Lightweight visual-only selection: avoid recreating rects so
            % that any in-flight context menu stays anchored.
            if isequal(obj.SelectedAnnotation, idx); return; end
            obj.SelectedAnnotation = idx;
            obj.updateAnnotationStyles();
        end

        function deselectAnnotation(obj)
            if isempty(obj.SelectedAnnotation); return; end
            obj.SelectedAnnotation = [];
            obj.updateAnnotationStyles();
        end

        function exportAnnotations(obj, filepath)
            arguments
                obj VideoAnnotator
                filepath (1,:) char = ''
            end
            if isempty(filepath)
                if ~isempty(obj.VideoPath)
                    defaultName = [obj.VideoPath, '.csv'];
                else
                    defaultName = 'annotations.csv';
                end
                [f, p] = uiputfile({'*.csv', 'CSV files (*.csv)'}, ...
                    'Export annotations', defaultName);
                if isequal(f, 0); return; end
                filepath = fullfile(p, f);
            end
            n = numel(obj.Annotations);
            if n == 0
                T = table('Size', [0, 3], ...
                    'VariableTypes', {'double', 'double', 'string'}, ...
                    'VariableNames', {'StartFrame', 'EndFrame', 'Text'});
            else
                T = table([obj.Annotations.StartFrame]', ...
                          [obj.Annotations.EndFrame]', ...
                          string({obj.Annotations.Text})', ...
                          'VariableNames', {'StartFrame', 'EndFrame', 'Text'});
            end
            writetable(T, filepath, 'QuoteStrings', true);
            fprintf('Exported %d annotation(s) to %s\n', n, filepath);
        end

        function importAnnotations(obj, filepath, mode)
            % importAnnotations(obj, filepath, mode)
            %   filepath: path to CSV, or empty to prompt the user
            %   mode:     'replace' (default) or 'append'
            arguments
                obj VideoAnnotator
                filepath (1,:) char = ''
                mode     (1,:) char {mustBeMember(mode, {'replace', 'append'})} = 'replace'
            end
            if isempty(filepath)
                [f, p] = uigetfile({'*.csv', 'CSV files (*.csv)'}, 'Import annotations');
                if isequal(f, 0); return; end
                filepath = fullfile(p, f);
            end
            T = readtable(filepath, 'TextType', 'string');
            requiredCols = {'StartFrame', 'EndFrame', 'Text'};
            missingCols  = setdiff(requiredCols, T.Properties.VariableNames);
            if ~isempty(missingCols)
                error('VideoAnnotator:badCSV', ...
                    'CSV is missing required column(s): %s', strjoin(missingCols, ', '));
            end
            nFrames = obj.getNumFrames();
            newAnns = struct('StartFrame', {}, 'EndFrame', {}, 'Text', {});
            for k = 1:height(T)
                s = double(T.StartFrame(k));
                e = double(T.EndFrame(k));
                if isnan(s) || isnan(e); continue; end
                s = round(s); e = round(e);
                if s > e; tmp = s; s = e; e = tmp; end
                s = max(1, s);
                if nFrames > 0
                    e = min(nFrames, e);
                end
                txt = T.Text(k);
                if ismissing(txt); txt = ""; end
                newAnns(end+1).StartFrame = s; %#ok<AGROW>
                newAnns(end).EndFrame     = e;
                newAnns(end).Text         = char(txt);
            end
            switch mode
                case 'replace'
                    obj.Annotations = newAnns;
                case 'append'
                    obj.Annotations = [obj.Annotations, newAnns];
            end
            obj.SelectedAnnotation = [];
            obj.drawAnnotations();
            fprintf('Imported %d annotation(s) from %s\n', numel(newAnns), filepath);
        end

        % --- Drawing ---

        function drawAnnotations(obj)
            % Tear down and rebuild every annotation rectangle, text, and
            % context menu. Called after structural changes (add / edit /
            % delete / import) and after the parent redraws nav data.
            obj.clearAnnotationGraphics();
            if isempty(obj.NavigationAxes); return; end
            if obj.getNumFrames() == 0;     return; end
            nA  = numel(obj.Annotations);
            if nA == 0
                obj.AnnotationRows = [];
                return;
            end
            nAx = obj.getNumNavigationAxes();
            obj.AnnotationRows = obj.computeAnnotationRows();
            for ai = 1:nA
                a     = obj.Annotations(ai);
                row   = obj.AnnotationRows(ai);
                isSel = isequal(obj.SelectedAnnotation, ai);
                [faceColor, faceAlpha, lineWidth] = obj.styleFor(isSel);

                cm = uicontextmenu(obj.MainFigure);
                uimenu(cm, 'Text', 'Edit text', ...
                    'MenuSelectedFcn', @(~,~)obj.editAnnotationText(ai));
                uimenu(cm, 'Text', 'Edit range', ...
                    'MenuSelectedFcn', @(~,~)obj.editAnnotationRange(ai));
                uimenu(cm, 'Text', 'Delete', ...
                    'MenuSelectedFcn', @(~,~)obj.deleteAnnotation(ai));
                obj.AnnotationContextMenus(end+1) = cm;

                for axi = 1:nAx
                    ax   = obj.NavigationAxes(axi);
                    yL   = ylim(ax);
                    rowH = diff(yL) * obj.AnnotationHeightFraction;
                    yTop = yL(2) - rowH * (row - 1);
                    yPos = yTop - rowH;
                    xS   = obj.mapFrameNumToAxesX(a.StartFrame);
                    xE   = obj.mapFrameNumToAxesX(a.EndFrame);
                    w    = max(xE - xS, eps);
                    rh = rectangle(ax, ...
                        'Position',      [xS, yPos, w, rowH], ...
                        'FaceColor',     faceColor, ...
                        'FaceAlpha',     faceAlpha, ...
                        'EdgeColor',     'k', ...
                        'LineWidth',     lineWidth, ...
                        'PickableParts', 'all', ...
                        'HitTest',       'on', ...
                        'ContextMenu',   cm);
                    rh.UserData.AnnotationIdx = ai;
                    obj.AnnotationRects(end+1) = rh;
                    th = text(ax, (xS + xE)/2, yPos + rowH/2, a.Text, ...
                        'HorizontalAlignment', 'center', ...
                        'VerticalAlignment',   'middle', ...
                        'Color',               'k', ...
                        'FontSize',            8, ...
                        'PickableParts',       'none', ...
                        'HitTest',             'off', ...
                        'Clipping',            'on', ...
                        'ContextMenu',         cm);
                    obj.AnnotationTexts(end+1) = th;
                end
            end
        end

        function updateAnnotationStyles(obj)
            % Visual-only refresh: tweak FaceColor/Alpha/LineWidth on the
            % existing rectangles to reflect SelectedAnnotation. Cheaper
            % than drawAnnotations and preserves rectangle/menu identity.
            nA  = numel(obj.Annotations);
            nAx = obj.getNumNavigationAxes();
            if numel(obj.AnnotationRects) ~= nA * nAx
                obj.drawAnnotations();
                return;
            end
            for ai = 1:nA
                isSel = isequal(obj.SelectedAnnotation, ai);
                [faceColor, faceAlpha, lineWidth] = obj.styleFor(isSel);
                for axi = 1:nAx
                    rh = obj.AnnotationRects((ai-1)*nAx + axi);
                    if ~isvalid(rh); continue; end
                    rh.FaceColor = faceColor;
                    rh.FaceAlpha = faceAlpha;
                    rh.LineWidth = lineWidth;
                end
            end
        end

        function clearAnnotationGraphics(obj)
            if ~isempty(obj.AnnotationRects)
                v = isvalid(obj.AnnotationRects);
                if any(v); delete(obj.AnnotationRects(v)); end
            end
            obj.AnnotationRects = matlab.graphics.primitive.Rectangle.empty(0);
            if ~isempty(obj.AnnotationTexts)
                v = isvalid(obj.AnnotationTexts);
                if any(v); delete(obj.AnnotationTexts(v)); end
            end
            obj.AnnotationTexts = matlab.graphics.primitive.Text.empty(0);
            if ~isempty(obj.AnnotationContextMenus)
                v = isvalid(obj.AnnotationContextMenus);
                if any(v); delete(obj.AnnotationContextMenus(v)); end
            end
            obj.AnnotationContextMenus = matlab.ui.container.ContextMenu.empty(0);
        end

        function bringAnnotationsToFront(obj)
            if isempty(obj.AnnotationRects); return; end
            v = isvalid(obj.AnnotationRects);
            if any(v); uistack(obj.AnnotationRects(v), 'top'); end
            v = isvalid(obj.AnnotationTexts);
            if any(v); uistack(obj.AnnotationTexts(v), 'top'); end
        end

        % --- Overrides of base class hooks ---

        function drawNavigationData(obj, varargin)
            drawNavigationData@VideoBrowser(obj, varargin{:});
            obj.drawAnnotations();
        end

        function MouseDownHandler(obj, src, evt)
            [xFig, yFig] = obj.GetCurrentVideoPanelPoint();
            [~, inNav, ~] = obj.whereIsMouse(xFig, yFig);
            if inNav
                idx = obj.hitTestAnnotation(xFig, yFig);
                if ~isempty(idx)
                    % Use lightweight selection so the rectangle and its
                    % ContextMenu remain valid for the imminent menu open
                    % (right-click) or any follow-up action.
                    obj.selectAnnotation(idx);
                    return;
                end
                if ~isempty(obj.SelectedAnnotation)
                    obj.deselectAnnotation();
                end
            end
            MouseDownHandler@VideoBrowser(obj, src, evt);
        end

        function KeyPressHandler(obj, src, evt)
            switch evt.Key
                case 'return'
                    if ~isempty(obj.SelectedAnnotation)
                        obj.editAnnotationText(obj.SelectedAnnotation);
                    elseif any(obj.FrameSelection)
                        obj.createAnnotationsFromSelection();
                    end
                    return;
                case 'delete'
                    if ~isempty(obj.SelectedAnnotation)
                        obj.deleteAnnotation(obj.SelectedAnnotation);
                        return;
                    end
                case 'escape'
                    if ~isempty(obj.SelectedAnnotation)
                        obj.deselectAnnotation();
                        return;
                    end
                case 'i'
                    if any(strcmp(evt.Modifier, 'control'))
                        obj.importAnnotations();
                        return;
                    end
                case 'e'
                    if any(strcmp(evt.Modifier, 'control'))
                        obj.exportAnnotations();
                        return;
                    end
            end
            KeyPressHandler@VideoBrowser(obj, src, evt);
        end

        function showHelp(obj, varargin)
            showHelp@VideoBrowser(obj, varargin{:});
            extraText = {
'***************************** Annotations *******************************';
'                                controls';
'';
'   enter (with frame selection) =      create annotation(s) from selected';
'                                       frames, prompting for text';
'   click on annotation =               select annotation';
'   right-click on annotation =         open annotation context menu';
'                                       (Edit text / Edit range / Delete)';
'   enter (annotation selected) =       edit selected annotation text';
'   delete (annotation selected) =      delete selected annotation';
'   escape (annotation selected) =      deselect annotation';
'   control-i =                         import annotations from CSV';
'   control-e =                         export annotations to CSV';
'';
'CSV format: three columns named StartFrame, EndFrame, Text';
                };
            f = figure();
            f.Name = 'Video Annotator - Annotation Controls';
            f.UserData.text = uicontrol(f, 'Style', 'text', 'Units', 'normalized', ...
                'Position', [0.01, 0.01, 0.99, 0.99], ...
                'FontName', 'Monospaced', 'String', extraText, ...
                'HorizontalAlignment', 'left');
        end

        % --- Helpers ---

        function createAnnotationsFromSelection(obj)
            sel = double(obj.FrameSelection(:)');
            d = diff([0, sel, 0]);
            starts = find(d ==  1);
            ends   = find(d == -1) - 1;
            if isempty(starts); return; end
            for k = 1:length(starts)
                s = starts(k);
                e = ends(k);
                if length(starts) == 1
                    promptStr = sprintf('Annotation text for frames %d-%d:', s, e);
                else
                    promptStr = sprintf('Annotation text for frames %d-%d (%d/%d):', ...
                        s, e, k, length(starts));
                end
                answer = inputdlg(promptStr, 'New annotation', [1, 60], {''});
                if isempty(answer); break; end
                obj.addAnnotation(s, e, answer{1});
            end
            obj.clearSelection();
        end

        function idx = hitTestAnnotation(obj, xFig, yFig)
            % Figure point -> annotation index under the cursor, taking
            % into account each annotation's row in the overlap layout,
            % or [] if none.
            idx = [];
            if isempty(obj.Annotations); return; end
            inAxes = obj.inNavigationAxes(xFig, yFig);
            if ~inAxes; return; end
            ax       = obj.NavigationAxes(inAxes);
            axPos    = getWidgetFigurePosition(ax, obj.MainFigure.Units);
            axYL     = ylim(ax);
            yAxData  = axYL(1) + (yFig - axPos(2)) / axPos(4) * diff(axYL);
            rowH     = diff(axYL) * obj.AnnotationHeightFraction;
            if numel(obj.AnnotationRows) == numel(obj.Annotations)
                rows = obj.AnnotationRows;
            else
                rows = obj.computeAnnotationRows();
            end
            curFrame = obj.mapFigureXToFrameNum(xFig);
            for k = 1:numel(obj.Annotations)
                a = obj.Annotations(k);
                if curFrame < a.StartFrame || curFrame > a.EndFrame; continue; end
                yTop = axYL(2) - rowH * (rows(k) - 1);
                yBot = yTop - rowH;
                if yAxData >= yBot && yAxData <= yTop
                    idx = k;
                    return;
                end
            end
        end

        function [faceColor, faceAlpha, lineWidth] = styleFor(obj, isSel)
            if isSel
                color     = obj.AnnotationSelectedColor;
                lineWidth = 2.0;
            else
                color     = obj.AnnotationColor;
                lineWidth = 0.5;
            end
            if numel(color) == 4
                faceColor = color(1:3);
                faceAlpha = color(4);
            else
                faceColor = color(1:3);
                faceAlpha = 1;
            end
        end

        function rows = computeAnnotationRows(obj)
            % Greedy interval-coloring: each annotation gets the lowest
            % row index (1-based) such that nothing already placed in
            % that row overlaps with it, processed in order of StartFrame.
            nA = numel(obj.Annotations);
            rows = zeros(1, nA);
            if nA == 0; return; end
            starts = [obj.Annotations.StartFrame];
            ends   = [obj.Annotations.EndFrame];
            [~, order] = sort(starts);
            rowEnds = [];
            for i = order
                s = starts(i);
                e = ends(i);
                placed = false;
                for r = 1:length(rowEnds)
                    if rowEnds(r) < s
                        rowEnds(r) = e;
                        rows(i) = r;
                        placed = true;
                        break;
                    end
                end
                if ~placed
                    rowEnds(end+1) = e; %#ok<AGROW>
                    rows(i) = length(rowEnds);
                end
            end
        end
    end
end
