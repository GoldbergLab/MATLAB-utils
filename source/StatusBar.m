classdef StatusBar < handle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% StatusBar: A compact status bar / progress bar widget for MATLAB GUIs
%
% Consists of an axes that displays a status text message and an optional
% progress bar fill. Designed to be one character height tall.
%
% Usage:
%   sb = StatusBar(parent)
%   sb = StatusBar(parent, 'Position', [x y w h], 'Units', 'normalized')
%   sb.Status = 'Loading...';
%   sb.Progress = 0.5;    % Fill 50% of the bar
%   sb.Progress = [];     % Hide the progress bar
%
% See also: axes, text, patch
%
% Version: 1.0
% Author:  Brian Kardon / Claude
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% Public properties
    properties
        Status (1, :) char = ''                  % Status text message
        Progress double = []                     % Progress fraction (0-1), or [] to hide
        HorizontalAlignment (1, :) char {mustBeMember(HorizontalAlignment, {'left', 'center', 'right'})} = 'left'
        ProgressColor (1, 3) double = [0.3, 0.6, 1.0]  % Fill color for progress bar
        BackgroundColor (1, 3) double = [0.94, 0.94, 0.94]  % Background color
        TextColor (1, 3) double = [0, 0, 0]     % Status text color
        FontSize (1, 1) double = 9               % Font size for status text
        BorderColor (1, 3) double = [0.7, 0.7, 0.7]  % Border color
        AutoClear (1, 1) logical = false             % Automatically clear after reaching 100%
        AutoClearDelay (1, 1) double = 3             % Seconds to wait before auto-clearing
    end

    %% Forwarded properties (get/set passed to the axes)
    properties (Dependent)
        Position
        Units
        Visible
        Parent
        Tag
    end

    %% Private properties
    properties (Access = private)
        Axes matlab.graphics.axis.Axes
        TextHandle matlab.graphics.primitive.Text
        ProgressPatch matlab.graphics.primitive.Patch
        BackgroundPatch matlab.graphics.primitive.Patch
        AutoClearTimer timer = timer.empty  % Single-shot timer for auto-clear
    end

    %% Constructor
    methods
        function obj = StatusBar(parent, options)
            % Create a StatusBar in the given parent container.
            arguments
                parent = []
                options.Position (1, 4) double = [0, 0, 1, 0.03]
                options.Units (1, :) char = 'normalized'
            end

            if isempty(parent)
                parent = gcf;
            end

            % Create the axes
            obj.Axes = axes(parent, ...
                'Units', options.Units, ...
                'Position', options.Position, ...
                'XLim', [0, 1], 'YLim', [0, 1], ...
                'XTick', [], 'YTick', [], ...
                'XTickLabel', {}, 'YTickLabel', {}, ...
                'Box', 'on', ...
                'XColor', obj.BorderColor, ...
                'YColor', obj.BorderColor, ...
                'Color', obj.BackgroundColor, ...
                'HandleVisibility', 'off', ...
                'HitTest', 'off', ...
                'PickableParts', 'none');

            hold(obj.Axes, 'on');

            % Background patch (full width, behind everything)
            obj.BackgroundPatch = patch(obj.Axes, ...
                [0, 1, 1, 0], [0, 0, 1, 1], obj.BackgroundColor, ...
                'EdgeColor', 'none', ...
                'HitTest', 'off', 'PickableParts', 'none');

            % Progress bar patch (starts hidden)
            obj.ProgressPatch = patch(obj.Axes, ...
                [0, 0, 0, 0], [0, 0, 1, 1], obj.ProgressColor, ...
                'EdgeColor', 'none', ...
                'HitTest', 'off', 'PickableParts', 'none', ...
                'Visible', 'off');

            % Status text
            obj.TextHandle = text(obj.Axes, 0.01, 0.5, '', ...
                'Units', 'data', ...
                'VerticalAlignment', 'middle', ...
                'HorizontalAlignment', obj.HorizontalAlignment, ...
                'FontSize', obj.FontSize, ...
                'Color', obj.TextColor, ...
                'Interpreter', 'none', ...
                'HitTest', 'off', 'PickableParts', 'none');

            hold(obj.Axes, 'off');

            obj.updateTextPosition();
        end
    end

    %% Property setters for public properties (trigger display updates)
    methods
        function set.Status(obj, value)
            obj.Status = value;
            obj.TextHandle.String = value;
        end

        function set.Progress(obj, value)
            if ~isempty(value)
                value = max(0, min(1, value));
            end
            obj.Progress = value;
            obj.updateProgressDisplay();
            % Cancel any pending auto-clear timer
            obj.cancelAutoClearTimer();
            % Start auto-clear countdown if progress reached 100%
            if obj.AutoClear && ~isempty(value) && value >= 1
                obj.startAutoClearTimer();
            end
        end

        function set.HorizontalAlignment(obj, value)
            obj.HorizontalAlignment = value;
            if ~isempty(obj.TextHandle) && isvalid(obj.TextHandle)
                obj.TextHandle.HorizontalAlignment = value;
                obj.updateTextPosition();
            end
        end

        function set.ProgressColor(obj, value)
            obj.ProgressColor = value;
            if ~isempty(obj.ProgressPatch) && isvalid(obj.ProgressPatch)
                obj.ProgressPatch.FaceColor = value;
            end
        end

        function set.BackgroundColor(obj, value)
            obj.BackgroundColor = value;
            if ~isempty(obj.BackgroundPatch) && isvalid(obj.BackgroundPatch)
                obj.BackgroundPatch.FaceColor = value;
            end
            if ~isempty(obj.Axes) && isvalid(obj.Axes)
                obj.Axes.Color = value;
            end
        end

        function set.TextColor(obj, value)
            obj.TextColor = value;
            if ~isempty(obj.TextHandle) && isvalid(obj.TextHandle)
                obj.TextHandle.Color = value;
            end
        end

        function set.FontSize(obj, value)
            obj.FontSize = value;
            if ~isempty(obj.TextHandle) && isvalid(obj.TextHandle)
                obj.TextHandle.FontSize = value;
            end
        end

        function set.BorderColor(obj, value)
            obj.BorderColor = value;
            if ~isempty(obj.Axes) && isvalid(obj.Axes)
                obj.Axes.XColor = value;
                obj.Axes.YColor = value;
            end
        end
    end

    %% Dependent property getters/setters (forwarded to axes)
    methods
        function value = get.Position(obj)
            value = obj.Axes.Position;
        end
        function set.Position(obj, value)
            obj.Axes.Position = value;
        end

        function value = get.Units(obj)
            value = obj.Axes.Units;
        end
        function set.Units(obj, value)
            obj.Axes.Units = value;
        end

        function value = get.Visible(obj)
            value = obj.Axes.Visible;
        end
        function set.Visible(obj, value)
            obj.Axes.Visible = value;
        end

        function value = get.Parent(obj)
            value = obj.Axes.Parent;
        end
        function set.Parent(obj, value)
            obj.Axes.Parent = value;
        end

        function value = get.Tag(obj)
            value = obj.Axes.Tag;
        end
        function set.Tag(obj, value)
            obj.Axes.Tag = value;
        end
    end

    %% Public methods
    methods
        function reset(obj)
            % Clear the status text and hide the progress bar.
            obj.cancelAutoClearTimer();
            obj.Status = '';
            obj.Progress = [];
        end

        function delete(obj)
            % Clean up the timer and axes when the StatusBar is destroyed.
            obj.cancelAutoClearTimer();
            if ~isempty(obj.Axes) && isvalid(obj.Axes)
                delete(obj.Axes);
            end
        end
    end

    %% Private methods
    methods (Access = private)
        function startAutoClearTimer(obj)
            % Start a single-shot timer that calls reset() after the
            % configured delay.
            obj.AutoClearTimer = timer( ...
                'StartDelay', obj.AutoClearDelay, ...
                'ExecutionMode', 'singleShot', ...
                'TimerFcn', @(~,~) obj.reset());
            start(obj.AutoClearTimer);
        end

        function cancelAutoClearTimer(obj)
            % Stop and delete any pending auto-clear timer. The try/catch
            % around stop() handles the case where this is called from
            % within the timer's own callback (via reset()), in which case
            % the timer may already be in a state where stop() throws.
            if ~isempty(obj.AutoClearTimer) && isvalid(obj.AutoClearTimer)
                try
                    stop(obj.AutoClearTimer);
                catch
                    % Timer may be executing or already stopped
                end
                delete(obj.AutoClearTimer);
            end
            obj.AutoClearTimer = timer.empty;
        end

        function updateProgressDisplay(obj)
            % Update the progress bar patch visibility and size.
            if isempty(obj.Progress)
                obj.ProgressPatch.Visible = 'off';
            else
                obj.ProgressPatch.XData = [0, obj.Progress, obj.Progress, 0];
                obj.ProgressPatch.Visible = 'on';
            end
        end

        function updateTextPosition(obj)
            % Set the text X position based on HorizontalAlignment.
            switch obj.HorizontalAlignment
                case 'left'
                    obj.TextHandle.Position(1) = 0.01;
                case 'center'
                    obj.TextHandle.Position(1) = 0.5;
                case 'right'
                    obj.TextHandle.Position(1) = 0.99;
            end
        end
    end
end
