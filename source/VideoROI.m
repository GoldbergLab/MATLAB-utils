classdef VideoROI < VideoBrowser
    % VideoROI  Pick a single rectangular ROI from a video.
    %
    %   roi = VideoROI('path/to/video') opens a video browser window. Scrub to a
    %   useful frame (left/right arrows, or press space to play), then press 'r'
    %   and drag to draw a rectangle. Each draw simply replaces the previous ROI
    %   - there are no editing handles by design. Close the window to accept.
    %   When the window closes, the chosen ROI is available as:
    %
    %       roi.ROI   ->   [x, y, width, height]   (pixel coordinates)
    %
    %   The whole frame is selected when the window opens, so closing without
    %   drawing anything returns the full-frame ROI.
    %
    %   This blocks (via uiwait) until the window is closed, so the line
    %   "roi = VideoROI(path)" does not return until you are done selecting.
    %
    %   See also: VideoBrowser, drawrectangle
    properties
        ROI = []                            % [x, y, width, height] in pixels, updated live as you draw
    end
    properties (Access = private)
        RectangleHandle = gobjects(1)       % Handle to the displayed ROI rectangle overlay
    end
    methods
        function obj = VideoROI(videoData, options)
            arguments
                videoData
                options.Title char = ''
            end
            % Load synchronously so the frame size is known immediately and
            %   scrubbing is responsive.
            obj@VideoBrowser(videoData, 'Async', false, 'Title', options.Title);
            obj.MainFigure.Name = 'VideoROI - press ''r'' then drag to set the ROI; close the window to accept';

            % Start with the entire frame selected.
            [frameHeight, frameWidth] = obj.getFrameSize();
            obj.setROI([1, 1, frameWidth, frameHeight]);

            % Block until the user closes the window. obj.ROI holds the result.
            uiwait(obj.MainFigure);
        end
        function KeyPressHandler(obj, src, evt)
            % Let the base browser handle its shortcuts, then add 'r' for ROI.
            KeyPressHandler@VideoBrowser(obj, src, evt);
            if strcmp(evt.Key, 'r')
                obj.drawNewROI();
            end
        end
    end
    methods (Access = private)
        function [frameHeight, frameWidth] = getFrameSize(obj)
            % Frame height/width from the loaded video data (H x W x [3] x N).
            frameHeight = size(obj.VideoData, 1);
            frameWidth = size(obj.VideoData, 2);
        end
        function setROI(obj, roi)
            % Store the ROI (clamped to the frame) and (re)draw the overlay.
            [frameHeight, frameWidth] = obj.getFrameSize();
            x = min(max(round(roi(1)), 1), frameWidth);
            y = min(max(round(roi(2)), 1), frameHeight);
            w = max(1, min(round(roi(3)), frameWidth - x + 1));
            h = max(1, min(round(roi(4)), frameHeight - y + 1));
            obj.ROI = [x, y, w, h];

            if ~isempty(obj.RectangleHandle) && isvalid(obj.RectangleHandle)
                delete(obj.RectangleHandle);
            end
            obj.RectangleHandle = rectangle(obj.VideoAxes, 'Position', obj.ROI, ...
                'EdgeColor', 'r', 'LineWidth', 1.5, 'HitTest', 'off', 'PickableParts', 'none');
        end
        function drawNewROI(obj)
            % Let the user drag out a fresh rectangle, replacing any existing
            %   ROI. The browser's own mouse callbacks are suspended during the
            %   draw so they don't interfere, and restored afterward.
            saved = obj.suspendMouseCallbacks();
            restorer = onCleanup(@() obj.restoreMouseCallbacks(saved));

            rect = drawrectangle(obj.VideoAxes, 'Color', 'r', 'LineWidth', 1.5);
            if ~isvalid(rect) || isempty(rect.Position) || any(rect.Position(3:4) <= 0)
                % User aborted or drew a zero-size rectangle - keep the old ROI.
                if isvalid(rect)
                    delete(rect);
                end
                return;
            end
            position = rect.Position;
            % Replace the editable drawrectangle ROI with a static overlay.
            delete(rect);
            obj.setROI(position);
        end
        function saved = suspendMouseCallbacks(obj)
            % Save and clear the figure/axes mouse callbacks used by the base
            %   browser, so interactive drawing isn't disrupted by them.
            fig = obj.MainFigure;
            ax = obj.VideoAxes;
            saved.figDown = fig.WindowButtonDownFcn;
            saved.figUp = fig.WindowButtonUpFcn;
            saved.figMotion = fig.WindowButtonMotionFcn;
            saved.figScroll = fig.WindowScrollWheelFcn;
            saved.axButtonDown = ax.ButtonDownFcn;
            fig.WindowButtonDownFcn = '';
            fig.WindowButtonUpFcn = '';
            fig.WindowButtonMotionFcn = '';
            fig.WindowScrollWheelFcn = '';
            ax.ButtonDownFcn = '';
        end
        function restoreMouseCallbacks(obj, saved)
            % Restore callbacks saved by suspendMouseCallbacks (guarded in case
            %   the window was closed mid-draw).
            fig = obj.MainFigure;
            if ~isempty(fig) && isvalid(fig)
                fig.WindowButtonDownFcn = saved.figDown;
                fig.WindowButtonUpFcn = saved.figUp;
                fig.WindowButtonMotionFcn = saved.figMotion;
                fig.WindowScrollWheelFcn = saved.figScroll;
            end
            ax = obj.VideoAxes;
            if ~isempty(ax) && isvalid(ax)
                ax.ButtonDownFcn = saved.axButtonDown;
            end
        end
    end
end
