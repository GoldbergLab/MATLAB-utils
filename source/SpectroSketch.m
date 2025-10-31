classdef SpectroSketch < handle
    properties
        % UI stuff
        MainFigure                  matlab.ui.Figure
        DataPanel                   matlab.ui.container.Panel
        SpectrogramPanel            matlab.ui.container.Panel
        SpectrogramAxes             matlab.graphics.axis.Axes
        AudioPanel                  matlab.ui.container.Panel
        AudioAxes                   matlab.graphics.axis.Axes
        StatusBar                   matlab.ui.control.UIControl         % Bottom status bar widget
        Divider                     matlab.ui.control.UIControl         % A button to allow user to drag navigation axes larger or smaller
        SpectrogramImage            matlab.graphics.primitive.Image
        SettingsPanel               matlab.ui.container.Panel
        BrushSettingsPanel          matlab.ui.container.Panel

        BrushAxes                   matlab.graphics.axis.Axes

        BrushTypeButtonGroup        matlab.ui.container.ButtonGroup
        SolidBrushButton            matlab.ui.control.UIControl
        SolidBrushSettingsPanel     matlab.ui.container.Panel
        SolidBrushMagSliderPanel    matlab.ui.container.Panel
        SolidBrushMagSlider         matlab.ui.control.UIControl
        StackBrushButton            matlab.ui.control.UIControl
        StackBrushSettingsPanel     matlab.ui.container.Panel
        StackBrushNumSliderPanel    matlab.ui.container.Panel
        StackBrushNumSlider         matlab.ui.control.UIControl
        StackBrushMagSliderPanel    matlab.ui.container.Panel
        StackBrushMagSlider         matlab.ui.control.UIControl

        TextureBrushButton          matlab.ui.control.UIControl
        TextureBrushSettingsPanel   matlab.ui.container.Panel
        BrushSizeSliderPanel        matlab.ui.container.Panel
        BrushSizeSlider             matlab.ui.control.UIControl

        BrushModeButtonGroup        matlab.ui.container.ButtonGroup
        BrushModeAddButton          matlab.ui.control.UIControl
        BrushModeReplaceButton      matlab.ui.control.UIControl
        BrushModeMultiplyButton     matlab.ui.control.UIControl

        SpectrogramSettingsPanel    matlab.ui.container.Panel
        SpectrogramCLimButton       matlab.ui.control.UIControl

        BrushOverlay                matlab.graphics.primitive.Rectangle
        PlayCursors                 
        BrushTextureAudioData
        IsDividerDragging
        ShiftKeyDown = false
        CtrlKeyDown = false
        IsDrawing = false
        Brush = stackBrush(7, 41, 5, 25, 'Smoothing', 5) %gaussBrush(7)
        BrushTMultiplier =          0.1
        BrushFMultiplier =          100
        AudioPlayer             audioplayer
        SpectrogramCLim = [13.0000, 24.5000]
    end
    properties
        AudioData
        SpectrogramData
        FrequencyValues
        TimeValues
        Window = hamming(512)
        WindowOverlap = 256
        NFFT = 512
        AudioSamplingRate
        CurrentTime
    end
    methods
        function obj = SpectroSketch(options)
            arguments
                options.AudioData = zeros(150000, 1);
                options.AudioSamplingRate = 44100;
            end
            if size(options.AudioData, 1) < size(options.AudioData, 2)
                % Standardize dimensions of AudioData
                options.AudioData = transpose(options.AudioData);
            end
            if size(options.AudioData, 2) > 1
                % Select only first channel
                options.AudioData = options.AudioData(:, 1);
            end
            obj.AudioData = options.AudioData;
            obj.AudioSamplingRate = options.AudioSamplingRate;
            obj.initializeUI();
            obj.updateSpectrogramData();
            obj.updateSpectrogramDisplay();
            obj.updateAudioDisplay();
            obj.AudioPlayer = audioplayer(obj.AudioData, obj.AudioSamplingRate);
            obj.AudioPlayer.TimerFcn = @obj.updatePlayCursors;
            obj.AudioPlayer.TimerPeriod = 1000 / obj.AudioSamplingRate;
        end
        function initializeUI(obj)
            % Create & prepare the graphics containers (the figure & axes)
            
            % Delete graphics containers in case they already exist
            % obj.deleteDisplayArea();
            
            % Create graphics containers
            obj.MainFigure =                figure( ...
                                                'BusyAction', 'cancel' ...
                                                );
            obj.MainFigure.Position = [80, 80, 1200, 800];
            obj.DataPanel =                 uipanel(obj.MainFigure ...
                                                );
            obj.SpectrogramPanel =          uipanel(obj.DataPanel ...
                                                );
            obj.SpectrogramAxes =           axes(obj.SpectrogramPanel, ...
                                                'Visible', false ...
                                                );
            obj.AudioPanel =                uipanel(obj.DataPanel ...
                                                );
            obj.AudioAxes =                 axes(obj.AudioPanel, ...
                                                'HitTest', 'on', ...
                                                'PickableParts', 'all' ...
                                                );
            obj.Divider =                   uicontrol(obj.DataPanel, ...
                                                'ForegroundColor', 'black', ...
                                                'BackgroundColor', 'black', ...
                                                'Style','text', ...
                                                'String', '----------------------------', ...
                                                'Visible','off', ...
                                                'BackgroundColor', obj.MainFigure.Color, ...
                                                'ButtonDownFcn', @obj.DividerMouseDown, ...
                                                'Enable', 'off' ...
                                                );
            obj.StatusBar =                 uicontrol(obj.MainFigure, ...
                                                'Style', 'text', ...
                                                'String', 'test', ...
                                                'HorizontalAlignment', 'left' ...
                                                );
            obj.SettingsPanel =             uipanel(obj.MainFigure);
            obj.BrushSettingsPanel =                uipanel(obj.SettingsPanel, ...
                                                'Title', 'Brush Settings' ...
                                                );
            obj.SpectrogramSettingsPanel =  uipanel(obj.SettingsPanel, ...
                                                'Title', 'Spectrogram Settings' ...
                                                );
            obj.SpectrogramCLimButton =     uicontrol(obj.SpectrogramSettingsPanel, ...
                                                "Style", "pushbutton", ...
                                                "String", "Color scale", ...
                                                "Callback", @(varargin)CLimGUI(obj.SpectrogramAxes) ...
                                                );

            obj.BrushAxes =                 axes(obj.BrushSettingsPanel, ...
                                                'XLimMode', 'manual', ...
                                                'YLimMode', 'manual', ...
                                                'XLim', [0, 0.25], ...
                                                'YLim', obj.SpectrogramAxes.YLim/5 ...
                                                );
                                                % 'DataAspectRatioMode', 'manual', ...
                                                % 'DataAspectRatio', obj.SpectrogramAxes.DataAspectRatio ...
            obj.BrushAxes.XAxis.Visible = 'off';
            obj.BrushAxes.YAxis.Visible = 'off';

            obj.BrushTypeButtonGroup =      uibuttongroup(obj.BrushSettingsPanel, ...
                                                "Title", 'Brush type' ...
                                                );
            obj.SolidBrushButton =          uicontrol(obj.BrushTypeButtonGroup, ...
                                                "Style", "radiobutton", ...
                                                "String", "Solid brush", ...
                                                "Callback", @obj.layoutUI ...
                                                );
            obj.StackBrushButton =          uicontrol(obj.BrushTypeButtonGroup, ...
                                                "Style", "radiobutton", ...
                                                "String", "Stack brush", ...
                                                "Callback", @obj.layoutUI ...
                                                );
            obj.TextureBrushButton =        uicontrol(obj.BrushTypeButtonGroup, ...
                                                "Style", "radiobutton", ...
                                                "String", "Texture brush", ...
                                                "Callback", @obj.layoutUI ...
                                                );
            obj.SolidBrushSettingsPanel =   uipanel(obj.BrushSettingsPanel, ...
                                                'Title', 'Solid brush settings' ...
                                                );
            obj.SolidBrushMagSliderPanel =  uipanel(obj.SolidBrushSettingsPanel, ...
                                                'Title', 'Magnitude' ...
                                                );
            obj.SolidBrushMagSlider =       uicontrol(obj.SolidBrushMagSliderPanel, ...
                                                "Min", 0, "Max", 25, ...
                                                "Value", 10, ...
                                                "Style", "slider" ...
                                                );
            obj.StackBrushSettingsPanel =   uipanel(obj.BrushSettingsPanel, ...
                                                'Title', 'Stack brush settings' ...
                                                );
            obj.StackBrushNumSliderPanel =  uipanel(obj.StackBrushSettingsPanel, ...
                                                'Title', 'Number of stacks' ...
                                                );
            obj.StackBrushNumSlider =       uicontrol(obj.StackBrushNumSliderPanel, ...
                                                "Min", 2, "Max", 12, ...
                                                "Value", 10, ...
                                                "Style", "slider" ...
                                                );
            obj.StackBrushMagSliderPanel =  uipanel(obj.StackBrushSettingsPanel, ...
                                                'Title', 'Magnitude' ...
                                                );
            obj.StackBrushMagSlider =       uicontrol(obj.StackBrushMagSliderPanel, ...
                                                "Min", 0, "Max", 25, ...
                                                "Value", 10, ...
                                                "Style", "slider" ...
                                                );
            obj.TextureBrushSettingsPanel =   uipanel(obj.BrushSettingsPanel, ...
                                                'Title', 'Texture brush settings' ...
                                                );
            obj.BrushSizeSliderPanel =      uipanel(obj.BrushSettingsPanel, ...
                                                'Title', 'Brush size' ...
                                                );
            obj.BrushSizeSlider =           uicontrol(obj.BrushSizeSliderPanel, ...
                                                "Min", 1, "Max", 10, ...
                                                "Value", 5, ...
                                                "Style", "slider" ...
                                                );
            obj.BrushModeButtonGroup =      uibuttongroup(obj.BrushSettingsPanel, ...
                                                'Title', 'Brush mode' ...
                                                );
            obj.BrushModeAddButton =          uicontrol(obj.BrushModeButtonGroup, ...
                                                "Style", "radiobutton", ...
                                                "String", "Add" ...
                                                );
            obj.BrushModeReplaceButton =        uicontrol(obj.BrushModeButtonGroup, ...
                                                "Style", "radiobutton", ...
                                                "String", "Replace" ...
                                                );            
            obj.BrushModeMultiplyButton =        uicontrol(obj.BrushModeButtonGroup, ...
                                                "Style", "radiobutton", ...
                                                "String", "Multiply" ...
                                                );

            % obj.HelpButton =                uicontrol(obj.SpectrogramPanel, 'Style', 'pushbutton', 'Units', 'normalized', 'String', '?', 'HorizontalAlignment', 'center', 'Callback', @obj.showHelp);

            % Style graphics containers
            obj.MainFigure.ToolBar = 'none';
            obj.MainFigure.MenuBar = 'none';
            obj.MainFigure.NumberTitle = 'off';
            obj.MainFigure.Name = 'SpectroSketch';

            obj.SpectrogramAxes.Toolbar.Visible = 'off';
            obj.SpectrogramAxes.YTickMode = 'manual';
            obj.SpectrogramAxes.YTickLabelMode = 'manual';
            obj.SpectrogramAxes.YTickLabel = [];
            obj.SpectrogramAxes.YTick = [];
            obj.SpectrogramAxes.XTickMode = 'manual';
            obj.SpectrogramAxes.XTickLabelMode = 'manual';
            obj.SpectrogramAxes.XTickLabel = [];
            obj.SpectrogramAxes.XTick = [];
            axis(obj.SpectrogramAxes, 'off');
            obj.SpectrogramAxes.Visible = true;


            obj.AudioAxes.Toolbar.Visible = 'off';
            obj.AudioAxes.YTickMode = 'manual';
            obj.AudioAxes.YTickLabelMode = 'manual';
            obj.AudioAxes.YTickLabel = [];
            obj.AudioAxes.YTick = [];
            axis(obj.AudioAxes, 'off');

            % Configure callbacks
            obj.MainFigure.WindowButtonMotionFcn = @obj.MouseMotionHandler;
            obj.MainFigure.WindowButtonUpFcn = @obj.MouseUpHandler;
            obj.MainFigure.WindowButtonDownFcn = @obj.MouseDownHandler;
            obj.MainFigure.WindowScrollWheelFcn = @obj.ScrollHandler;
            obj.MainFigure.BusyAction = 'cancel';
            obj.MainFigure.KeyPressFcn = @obj.KeyPressHandler;
            obj.MainFigure.KeyReleaseFcn = @obj.KeyReleaseHandler;
            obj.MainFigure.SizeChangedFcn = @obj.layoutUI;

            obj.layoutUI();

            drawnow()
        end
        
        function layoutUI(obj, varargin)
            statusH = 20;
            radioH = 20;
            sliderH = 20;
            labelH = 20;
            settingsXFrac = 0.25;
            spectrogramYFrac = 0.8;
            dividerH = 20;
            brushPanelFrac = 0.5;
            brushAxesH = 100;
            brushTypeButtonGroupH = 7 * radioH;
            brushTypePanelXFrac = 0.4;
            buttonH = 30;

            allWidgets = [
              obj.DataPanel;
                obj.SpectrogramPanel;
                  obj.SpectrogramAxes;
                obj.Divider;
                obj.AudioPanel;
                  obj.AudioAxes;
              obj.StatusBar;
              obj.SettingsPanel;
              obj.SpectrogramSettingsPanel;
              obj.SpectrogramCLimButton;
              obj.BrushSettingsPanel;
                obj.BrushAxes;
                obj.BrushTypeButtonGroup;
                  obj.SolidBrushButton;
                  obj.StackBrushButton;
                  obj.TextureBrushButton;
                obj.SolidBrushSettingsPanel;
                  obj.SolidBrushMagSliderPanel;
                    obj.SolidBrushMagSlider;
                obj.StackBrushSettingsPanel;
                obj.TextureBrushSettingsPanel;
                    obj.StackBrushNumSliderPanel;
                      obj.StackBrushNumSlider;
                    obj.StackBrushMagSliderPanel;
                      obj.StackBrushMagSlider;
                obj.BrushSizeSliderPanel;
                obj.BrushSizeSlider;
                obj.BrushModeButtonGroup;
                  obj.BrushModeAddButton;
                  obj.BrushModeReplaceButton;
                  obj.BrushModeMultiplyButton
              ];
            set(allWidgets, 'Units', 'pixels');

            figPos = getpixelposition(obj.MainFigure);
            figW = figPos(3);
            figH = figPos(4);
                obj.StatusBar.Position = [0, 0, figW, statusH];
    
                dataPanelW = figW * (1 - settingsXFrac);
                dataPanelH = figH - statusH;
                obj.DataPanel.Position = [0, statusH, dataPanelW, dataPanelH];
                    audioPanelW = dataPanelW; audioPanelH = (dataPanelH - dividerH) * (1-spectrogramYFrac);
                    obj.AudioPanel.Position = [0, 0, audioPanelW, audioPanelH];
                        obj.AudioAxes.Position = [0, 0, audioPanelW, audioPanelH];
                    obj.Divider.Position = [0, audioPanelH, dataPanelW, dividerH];
                    spectrogramPanelW = dataPanelW; spectrogramPanelH = (dataPanelH - dividerH) * spectrogramYFrac;
                    obj.SpectrogramPanel.Position = [0, audioPanelH + dividerH, spectrogramPanelW, spectrogramPanelH];
                        obj.SpectrogramAxes.Position = [0, 0, spectrogramPanelW, spectrogramPanelH];
                settingsPanelW = figW * settingsXFrac; settingsPanelH = figH - statusH;
                obj.SettingsPanel.Position = [dataPanelW, statusH, settingsPanelW, settingsPanelH];
                    brushSettingsPanelW = settingsPanelW; brushSettingsPanelH = settingsPanelH * brushPanelFrac;
                    obj.BrushSettingsPanel.Position = [0, 0, brushSettingsPanelW, brushSettingsPanelH];
                        obj.BrushAxes.Position(4) = brushAxesH;
                        brushAxesW = obj.BrushAxes.Position(3);
                        obj.BrushAxes.Position = [0, brushSettingsPanelH - brushAxesH, brushAxesW, brushAxesH];
                        obj.BrushTypeButtonGroup.Position =   [0, brushSettingsPanelH - brushAxesH - brushTypeButtonGroupH, brushSettingsPanelW * brushTypePanelXFrac, brushTypeButtonGroupH];
                            obj.SolidBrushButton.Position =   [0, brushTypeButtonGroupH - radioH * 2, brushSettingsPanelW, radioH];
                            obj.StackBrushButton.Position =   [0, brushTypeButtonGroupH - radioH * 3, brushSettingsPanelW, radioH];
                            obj.TextureBrushButton.Position = [0, brushTypeButtonGroupH - radioH * 4, brushSettingsPanelW, radioH];
                        typeSpecificSettingsW = brushSettingsPanelW * (1-brushTypePanelXFrac);
                        typeSpecificBrushSettingsPosition = [brushSettingsPanelW * brushTypePanelXFrac, brushSettingsPanelH - brushAxesH - brushTypeButtonGroupH, typeSpecificSettingsW, brushTypeButtonGroupH];
                        % Set visibility of type specific brush settings
                        switch obj.BrushTypeButtonGroup.SelectedObject
                            case obj.SolidBrushButton
                                obj.SolidBrushSettingsPanel.Position =   typeSpecificBrushSettingsPosition;
                                obj.SolidBrushMagSliderPanel.Position = [0, 0, typeSpecificSettingsW, brushTypeButtonGroupH - labelH];
                                obj.SolidBrushMagSlider.Position = [0, brushTypeButtonGroupH - labelH - 2*sliderH, typeSpecificSettingsW, sliderH];

                                obj.SolidBrushSettingsPanel.Visible =   true;
                                obj.StackBrushSettingsPanel.Visible =   false;
                                obj.TextureBrushSettingsPanel.Visible = false;
                            case obj.StackBrushButton
                                obj.StackBrushSettingsPanel.Position =   typeSpecificBrushSettingsPosition;
                                obj.StackBrushNumSliderPanel.Position = [0, brushTypeButtonGroupH - labelH - (labelH + sliderH), typeSpecificSettingsW, labelH + sliderH];
                                obj.StackBrushNumSlider.Position =      [0, 0, typeSpecificSettingsW, sliderH];
                                obj.StackBrushMagSliderPanel.Position = [0, brushTypeButtonGroupH - labelH - 2*(labelH + sliderH), typeSpecificSettingsW, labelH + sliderH];
                                obj.StackBrushMagSlider.Position =      [0, 0, typeSpecificSettingsW, sliderH];

                                obj.SolidBrushSettingsPanel.Visible =   false;
                                obj.StackBrushSettingsPanel.Visible =   true;
                                obj.TextureBrushSettingsPanel.Visible = false;
                            case obj.TextureBrushButton
                                obj.TextureBrushSettingsPanel.Position = typeSpecificBrushSettingsPosition;
                                obj.SolidBrushSettingsPanel.Visible =   false;
                                obj.StackBrushSettingsPanel.Visible =   false;
                                obj.TextureBrushSettingsPanel.Visible = true;
                        end
                        obj.BrushSizeSliderPanel.Position = [0, brushSettingsPanelH - brushAxesH - brushTypeButtonGroupH - sliderH, brushSettingsPanelW, sliderH + labelH];
                            obj.BrushSizeSlider.Position = [0, sliderH - labelH, brushSettingsPanelW, sliderH];
                        brushModeButtonGroupH = brushSettingsPanelH - (brushAxesH + brushTypeButtonGroupH + sliderH);
                        brushModeButtonGroupY = brushSettingsPanelH - brushAxesH - brushTypeButtonGroupH - sliderH - brushModeButtonGroupH;
                        obj.BrushModeButtonGroup.Position = [0, brushModeButtonGroupY, brushSettingsPanelW, brushModeButtonGroupH];
                            obj.BrushModeAddButton.Position =      [0, brushModeButtonGroupH - radioH * 2, brushSettingsPanelW, radioH];
                            obj.BrushModeReplaceButton.Position =  [0, brushModeButtonGroupH - radioH * 3, brushSettingsPanelW, radioH];
                            obj.BrushModeMultiplyButton.Position = [0, brushModeButtonGroupH - radioH * 4, brushSettingsPanelW, radioH];
                    spectrogramSettingsPanelW = settingsPanelW; spectrogramSettingsPanelH = settingsPanelH * (1 - brushPanelFrac);
                    obj.SpectrogramSettingsPanel.Position = [0, brushSettingsPanelH, spectrogramSettingsPanelW, spectrogramSettingsPanelH];
                        obj.SpectrogramCLimButton.Position = [0, 0, 100, buttonH];
        end

        function updateSpectrogramData(obj)
            [obj.SpectrogramData, obj.FrequencyValues, obj.TimeValues] = ...
                stft( ...
                    obj.AudioData, ...
                    obj.AudioSamplingRate, ...
                    'Window', obj.Window, ...
                    "OverlapLength", obj.WindowOverlap, ...
                    "FFTLength", obj.NFFT, ...
                    "FrequencyRange", "onesided" ...
                    );
        end
        function updateAudioData(obj)
            obj.AudioData = istft( ...
                obj.SpectrogramData, ...
                obj.AudioSamplingRate, ...
                "Window", obj.Window, ...
                "OverlapLength", obj.WindowOverlap, ...
                "FFTLength", obj.NFFT, ...
                "FrequencyRange", "onesided" ...
                );
            delete(obj.AudioPlayer);
            obj.AudioPlayer = audioplayer(obj.AudioData, obj.AudioSamplingRate);
        end
        function updateSpectrogramDisplay(obj)
            power = 2*log(abs(obj.SpectrogramData)+eps)+20;
            if isvalid(obj.SpectrogramImage)
                obj.SpectrogramImage.CData = power;
            else
                obj.SpectrogramImage = imagesc( ...
                    'XData', obj.TimeValues, ...
                    'YData', obj.FrequencyValues, ...
                    'CData', power, ...
                    'Parent', obj.SpectrogramAxes ...
                    );
            end

            obj.SpectrogramAxes.YDir = 'normal';
            obj.SpectrogramAxes.XLim = [obj.TimeValues(1), obj.TimeValues(end)];
            obj.SpectrogramAxes.YLim = [obj.FrequencyValues(1), obj.FrequencyValues(end)];
            c = colormap();
            c(1, :) = [0, 0, 0];
            colormap(obj.SpectrogramAxes, c);
            obj.SpectrogramAxes.CLim = obj.SpectrogramCLim;

        end
        function updateAudioDisplay(obj)
            plot(obj.AudioAxes, (1:length(obj.AudioData)) / obj.AudioSamplingRate, obj.AudioData);
        end
        function clearSpectrogram(obj)
            arguments
                obj SpectroSketch
            end
            obj.SpectrogramData = obj.SpectrogramData * 0;
            obj.updateSpectrogramDisplay();
            obj.updateAudioData();
            obj.updateAudioDisplay();
        end
        function applyBrush(obj, t, f)
            [tidx, fidx] = obj.getBrushIdx(t, f);
            [tSize, fSize] = obj.getBrushIdxSize(t, f);
            brush = zeros(fSize, tSize);
            switch obj.BrushTypeButtonGroup.SelectedObject.String
                case 'Solid brush'
                    brush(:) = obj.SolidBrushMagSlider.Value;
                case 'Stack brush'
                    numStacks = round(obj.StackBrushNumSlider.Value);
                    magStacks = obj.StackBrushMagSlider.Value;
                    brush(:) = stackBrush(tSize, fSize, numStacks, magStacks, 'Smoothing', round(tSize/5));
                case 'Texture brush'
                    brush = resizeArray(obj.BrushTextureAudioData, [fSize, tSize]);
            end
            switch obj.BrushModeButtonGroup.SelectedObject.String
                case 'Add'
                    obj.SpectrogramData(fidx(1):fidx(2), tidx(1):tidx(2)) = obj.SpectrogramData(fidx(1):fidx(2), tidx(1):tidx(2)) + brush;
                case 'Multiply'
                    obj.SpectrogramData(fidx(1):fidx(2), tidx(1):tidx(2)) = obj.SpectrogramData(fidx(1):fidx(2), tidx(1):tidx(2)) .* brush;
                case 'Replace'
                    obj.SpectrogramData(fidx(1):fidx(2), tidx(1):tidx(2)) = brush;
            end
            % switch obj.BrushModeButtonGroup.
            % obj.brushMagnitude(tidx, fidx, obj.Brush, "Behavior", "add");
        end
        function copyTexture(obj)
            [t, f] = obj.getCurrentSpectrogramPoint();
            [tidx, fidx] = obj.getBrushIdx(t, f);
            obj.BrushTextureAudioData = obj.SpectrogramData(fidx(1):fidx(2), tidx(1):tidx(2));
        end
        function brushMagnitude(obj, tidx, fidx, brush, options)
            arguments
                obj SpectroSketch
                tidx double
                fidx double
                brush double {mustBeMatrix}
                options.Behavior {mustBeMember(options.Behavior, {'add', 'replace'})} = 'add'
            end
            obj.SpectrogramData = addMatrixCentered(obj.SpectrogramData, brush, fidx, tidx, options.Behavior);

        end
        function setMagnitude(obj, tidx, fidx, magnitude, options)
            arguments
                obj SpectroSketch
                tidx double
                fidx double
                magnitude double {mustBeReal}
                options.Phase {mustBeMember(options.Phase, {'keep', 'zero', 'random'})} = 'random'
            end
            switch options.Phase
                case 'random'
                    obj.SpectrogramData(fidx, tidx) = magnitude * exp(1i*rand()*2*pi);
                case 'keep'
                    obj.SpectrogramData(fidx, tidx) = obj.SpectrogramData(fidx, tidx) * magnitude / abs(obj.SpectrogramData(fidx, tidx));
                case 'zero'
                    obj.SpectrogramData(fidx, tidx) = magnitude;
            end
            obj.updateSpectrogramDisplay();
            obj.updateAudioData();
            obj.updateAudioDisplay();
        end
        function [xFig, yFig] = getCurrentFigurePoint(obj)
            xFig = obj.MainFigure.CurrentPoint(1, 1);
            yFig = obj.MainFigure.CurrentPoint(1, 2);
        end
        function [t, f] = getCurrentSpectrogramPoint(obj)
            t = obj.SpectrogramAxes.CurrentPoint(1, 1);
            f = obj.SpectrogramAxes.CurrentPoint(1, 2);
        end
        function [tidx, fidx, t, f] = getCurrentSpectrogramIndices(obj, options)
            arguments
                obj SpectroSketch
                options.T = []
                options.F = []
            end
            if isempty(options.T) || isempty(options.F)
                [t, f] = obj.getCurrentSpectrogramPoint();
            else
                t = options.T;
                f = options.F;
            end
            if t < obj.TimeValues(1)
                tidx = [];
            else
                tidx = find(obj.TimeValues >= t, 1, "first");
            end
            if f < obj.FrequencyValues(1)
                fidx = [];
            else
                fidx = find(obj.FrequencyValues >= f, 1, "first");
            end
        end
        function totalTime = getTotalTime(obj)
            totalTime = length(obj.AudioData) / obj.AudioSamplingRate;
        end
        function [inSpectrogramAxes, inAudioAxes, inDivider] = whereIsMouse(obj, x, y)
            if isPositionWithinWidget(obj.SpectrogramAxes, [x, y], 'pixels')
                inSpectrogramAxes = true;
                inAudioAxes = false;
                inDivider = false;
            elseif isPositionWithinWidget(obj.AudioAxes, [x, y], 'pixels')
                inSpectrogramAxes = false;
                inAudioAxes = true;
                inDivider = false;
            elseif isPositionWithinWidget(obj.Divider, [x, y], 'pixels')
                inSpectrogramAxes = false;
                inAudioAxes = false;
                inDivider = true;
            else
                inSpectrogramAxes = false;
                inAudioAxes = false;
                inDivider = false;
            end
        end
        function MouseMotionHandler(obj, ~, ~)
            % Handle mouse motion events
            if isempty(obj.SpectrogramData) || isempty(obj.AudioData)
                return
            end
            [xFig, yFig] = obj.getCurrentFigurePoint();

            [inSpectrogramAxes, inAudioAxes, inDivider] = obj.whereIsMouse(xFig, yFig);
            if inSpectrogramAxes
                [tidx, fidx, t, f] = obj.getCurrentSpectrogramIndices();
                if obj.IsDrawing
                    obj.applyBrush(t, f);
                    obj.updateSpectrogramDisplay();
                    obj.updateAudioData();
                    obj.updateAudioDisplay();
                end
                if ~isempty(obj.SpectrogramData)
                    if ~isempty(tidx) && ~isempty(fidx)
                        val = num2str(abs(obj.SpectrogramData(fidx, tidx)));
                        obj.StatusBar.String = sprintf('Spectrogram(%.03f s, %d Hz) = %s', t, f, val);
                    end
                end
                obj.updateBrushOverlay(t, f);
            end
            if inAudioAxes
                if ~obj.isPlaying()
                    % Do not change frame during mouseover if audio is
                    % playing
                    obj.CurrentTime = 0;
                end
                mouseTime = 0;
                obj.StatusBar.String = sprintf('Time = %d / %d s', mouseTime, obj.getTotalTime());
            end
            if inDivider
            end
            if ~inSpectrogramAxes && ~inAudioAxes && ~inDivider
            end
            if obj.IsDividerDragging
            end
        end
        function MouseDownHandler(obj, ~, ~)
            % Handle user mouse click
            [xFig, yFig] = obj.getCurrentFigurePoint();

            [inSpectrogramAxes, inAudioAxes, inDivider] = obj.whereIsMouse(xFig, yFig);
            if inSpectrogramAxes
                [t, f] = obj.getCurrentSpectrogramPoint();
                obj.applyBrush(t, f);
                obj.updateSpectrogramDisplay();
                obj.updateAudioData();
                obj.updateAudioDisplay();
                obj.IsDrawing = true;
            elseif inAudioAxes
                % Mouse click is in navigation axes
                % frameNum = obj.mapFigureXToFrameNum(xFig);

                % Set current frame to the click location
                % obj.CurrentTime = frameNum;
                if obj.isPlaying()
                    % obj.restartVideo();
                end
            end
            if inDivider
            end
        end
        function MouseUpHandler(obj, ~, ~)
            obj.IsDividerDragging = false;
            obj.IsDrawing = false;
        end
        function KeyPressHandler(obj, ~, evt)
            switch evt.Key
                case 'escape'
                case 'space'
                    if obj.isPlaying()
                        stop(obj.AudioPlayer);
                        delete(obj.PlayCursors);
                    else
                        obj.AudioPlayer.play();
                    end
                case 'shift'
                    obj.ShiftKeyDown = true;
                case 'control'
                    obj.CtrlKeyDown = true;
                case 'c'
                    if obj.CtrlKeyDown
                        obj.copyTexture();
                    else
                        obj.clearSpectrogram();
                    end
                case 's'
                    if any(strcmp(evt.Modifier, 'control'))
                    end
                case 'rightarrow'
                case 'leftarrow'
            end
        end
        function KeyReleaseHandler(obj, ~, evt)
            switch evt.Key
                case 'shift'
                    obj.ShiftKeyDown = false;
                case 'control'
                    obj.CtrlKeyDown = false;
            end
        end
        function ScrollHandler(obj, ~, evt)
            [xFig, yFig] = obj.getCurrentFigurePoint();
            
            [inSpectrogramAxes, inAudioAxes, ~] = obj.whereIsMouse(xFig, yFig);
            if inSpectrogramAxes
                scrollCount = evt.VerticalScrollCount;
                scrollSpeed = 0.5;
                if obj.ShiftKeyDown
                    % Adjust time size
                    obj.BrushTMultiplier = max(obj.BrushTMultiplier + 0.01 * scrollCount, 0.001);
                elseif obj.CtrlKeyDown
                    % Adjust frequency size
                    obj.BrushFMultiplier = max(obj.BrushFMultiplier + 10 * scrollCount, 0.001);
                else
                    % Adjust overall size
                    newSize = obj.BrushSizeSlider.Value + scrollCount * scrollSpeed;
                    newSize = max(newSize, obj.BrushSizeSlider.Min);
                    newSize = min(newSize, obj.BrushSizeSlider.Max);
                    obj.BrushSizeSlider.Value = newSize;
                end
                [t, f] = obj.getCurrentSpectrogramPoint();
                obj.updateBrushOverlay(t, f);
            end
            if inAudioAxes
            %     scrollCount = evt.VerticalScrollCount;
            %     if obj.ShiftKeyDown
            %         % User has shift pressed - shift axes instead of
            %         % zooming
            %         currentTLim = xlim(obj.NavigationAxes(1));
            %         shiftFraction = 0.1;
            %         shiftAmount = diff(currentTLim) * shiftFraction * scrollCount;
            %         newTLim = currentTLim + shiftAmount;
            %         xlim(obj.NavigationAxes(1), newTLim);
            % 
            %         % Update video frame too
            %         frameNum = obj.mapFigureXToFrameNum(xFig);
            %         if ~obj.isPlaying()
            %             % Do not change frame during mouseover if video is
            %             % playing
            %             obj.CurrentFrameNum = frameNum;
            %         end
            %     else
            %         % Zoom in or out
            %         zoomFactor = 2^scrollCount;
            %         obj.NavigationZoom = obj.NavigationZoom * zoomFactor;
            %         if obj.NavigationZoom > 1
            %             % No point in allowing user to zoom further out the
            %             % showing whole plot
            %             obj.NavigationZoom = 1;
            %         end
            %         obj.drawNavigationData(false);
            %     end
            end
        end        
        function [TSize, FSize] = getBrushSize(obj)
            brushSize = obj.BrushSizeSlider.Value;
            TSize = brushSize * obj.BrushTMultiplier;
            FSize = brushSize * obj.BrushFMultiplier;
        end
        function [TLim, FLim] = getBrushLim(obj, tCenter, fCenter, options)
            arguments
                obj SpectroSketch
                tCenter
                fCenter
                options.Trim = false
            end
            [TSize, FSize] = obj.getBrushSize();
            TLim = [tCenter - TSize / 2, tCenter + TSize / 2];
            FLim = [fCenter - FSize / 2, fCenter + FSize / 2];
            if options.Trim
                TLim(1) = max(TLim(1), obj.TimeValues(1));
                TLim(2) = min(TLim(2), obj.TimeValues(end));
                FLim(1) = max(FLim(1), obj.FrequencyValues(1));
                FLim(2) = min(FLim(2), obj.FrequencyValues(end));
            end
        end
        function [TIdx, FIdx] = getBrushIdx(obj, tCenter, fCenter)
            [TLim, FLim] = obj.getBrushLim(tCenter, fCenter, 'Trim', true);
            TIdx = [0, 0];
            FIdx = [0, 0];
            TIdx(1) = max(find(obj.TimeValues >= TLim(1), 1, 'first'), 1);
            TIdx(2) = min(find(obj.TimeValues >= TLim(2), 1, 'first'), size(obj.SpectrogramData, 2));
            FIdx(1) = max(find(obj.FrequencyValues >= FLim(1), 1, 'first'), 1);
            FIdx(2) = min(find(obj.FrequencyValues >= FLim(2), 1, 'first'), size(obj.SpectrogramData, 1));
        end
        function [nT, nF] = getBrushIdxSize(obj, tCenter, fCenter)
            [TIdx, FIdx] = obj.getBrushIdx(tCenter, fCenter);
            nT = diff(TIdx) + 1;
            nF = diff(FIdx) + 1;
        end
        function updateBrushOverlay(obj, t, f)
            if isempty(obj.BrushOverlay) || ~isvalid(obj.BrushOverlay)
                obj.BrushOverlay = rectangle( ...
                    "Parent", obj.SpectrogramAxes, ...
                    "FaceColor", 'none', ...
                    'EdgeColor', 'yellow' ...
                    );
            end
            [TLim, FLim] = obj.getBrushLim(t, f);
            obj.BrushOverlay.Position = [TLim(1), FLim(1), TLim(2) - TLim(1), FLim(2) - FLim(1)];
        end
        function updatePlayCursors(obj, varargin)
            if obj.isPlaying()
                t = obj.AudioPlayer.CurrentSample / obj.AudioSamplingRate;
                if isempty(obj.PlayCursors) || any(~isvalid(obj.PlayCursors)) || any(~isgraphics(obj.PlayCursors))
                    delete(obj.PlayCursors);
                    obj.PlayCursors = gobjects(0);
                    obj.PlayCursors(1) = line( ...
                        obj.SpectrogramAxes, ...
                        [t, t], obj.SpectrogramAxes.YLim, ...
                        'Color', 'green' ...
                        );
                    obj.PlayCursors(2) = line( ...
                        obj.AudioAxes, ...
                        [t, t], obj.AudioAxes.YLim, ...
                        'Color', 'green' ...
                        );
                end
                obj.PlayCursors(1).XData = [t, t];
                obj.PlayCursors(1).YData = obj.SpectrogramAxes.YLim;
                obj.PlayCursors(2).XData = [t, t];
                obj.PlayCursors(2).YData = obj.AudioAxes.YLim;
            else
                delete(obj.PlayCursors);
            end
        end

        function playing = isPlaying(obj)
            % Check if audio is currently playing
            if isempty(obj.AudioPlayer)
                playing = false;
            else
                playing = obj.AudioPlayer.isplaying();
            end
        end

    end
end

function C = addMatrixCentered(A, B, row, col, operation)
% addMatrixCentered: Add a smaller matrix B into A, centered at (row, col)
% C = addMatrixCentered(A, B, row, col)
%
% A, B: numeric 2D arrays (size(B) < size(A))
% row, col: scalar indices specifying the *center* of B within A
% C: resulting matrix after adding B into A (with edge truncation)
%
% Example:
%   A = zeros(6);
%   B = ones(3);
%   C = addMatrixCentered(A, B, 1, 1);
%
%   % B is centered at (1,1); portions that would fall off A are truncated

arguments
    A (:,:) double
    B (:,:) double
    row (1,1) double {mustBeInteger, mustBePositive}
    col (1,1) double {mustBeInteger, mustBePositive}
    operation {mustBeMember(operation, {'add', 'replace'})}
end

[HA, WA] = size(A);
[HB, WB] = size(B);

% Compute the intended top-left corner of B in A
r0 = row - floor(HB/2);
c0 = col - floor(WB/2);

% Compute index ranges for A and B, truncated to fit A’s boundaries
rA = max(r0,1) : min(r0+HB-1, HA);
cA = max(c0,1) : min(c0+WB-1, WA);

% Simplify: compute start/stop in B directly
rB = 1 + (rA(1)-r0) : 1 + (rA(end)-r0);
cB = 1 + (cA(1)-c0) : 1 + (cA(end)-c0);

% Add the overlapping region
C = A;
switch operation
    case 'add'
        C(rA, cA) = C(rA, cA) + B(rB, cB);
    case 'replace'
        C(rA, cA) = B(rB, cB);
end
end

function brush = gaussBrush(s, options)
    arguments
        s (1, 1) double
        options.Phase {mustBeMember(options.Phase, {'zero', 'random'})} = 'random'
    end
    if mod(s, 2) == 0
        s = s + 1;
    end
    h = ceil(s/2);
    [X, Y] = ndgrid((1:s)-h, (1:s)-h);
    brush = exp(-(X.^2 + Y.^2));
    switch options.Phase
        case 'random'
            brush = brush .* exp(1i*rand(size(brush))*2*pi);
    end
end

function brush = stackBrush(nt, nf, n, mag, options)
    arguments
        nt (1, 1) double
        nf (1, 1) double
        n (1, 1) double {mustBeInteger, mustBeGreaterThan(n, 1)} = 5
        mag (1, 1) double = 25
        options.Phase {mustBeMember(options.Phase, {'zero', 'random'})} = 'random'
        options.Smoothing {mustBePositive, mustBeInteger} = 0
    end
    brush = zeros(nf, nt);
    stackSpacing = (nf-1) / (n-1);

    for stack = 1:n
        brush(round((stack-1)*stackSpacing + 1), :) = mag;
    end

    if options.Smoothing > 0
        brush = movmean(brush, options.Smoothing, 1);
    end

    switch options.Phase
        case 'random'
            brush = brush .* exp(1i*rand(size(brush))*2*pi);
    end
end

function B = resizeArray(A, targetSize)
% resizeArray: symmetrically trim or zero-pad 2D array to target size
% usage:  B = resizeArray(A, targetSize)
%
% A: input 2D numeric array
% targetSize: [numRows numCols] desired output size
%
% The function will center A within the new array. If A is larger,
% it trims symmetrically; if smaller, it pads with zeros symmetrically.

arguments
    A (:,:) double
    targetSize (1,2) double {mustBePositive, mustBeInteger}
end

[sizeA1, sizeA2] = size(A);
[target1, target2] = deal(targetSize(1), targetSize(2));

% Compute trim/pad start and end indices for each dimension
trim1 = max(0, sizeA1 - target1);
trim2 = max(0, sizeA2 - target2);
pad1  = max(0, target1 - sizeA1);
pad2  = max(0, target2 - sizeA2);

% Calculate indices to keep (for trimming)
start1 = floor(trim1/2) + 1;
end1   = sizeA1 - ceil(trim1/2);
start2 = floor(trim2/2) + 1;
end2   = sizeA2 - ceil(trim2/2);

Atrim = A(start1:end1, start2:end2);

% Pad symmetrically (for smaller arrays)
B = padarray(Atrim, [floor(pad1/2), floor(pad2/2)], 0, 'pre');
B = padarray(B, [ceil(pad1/2), ceil(pad2/2)], 0, 'post');

end