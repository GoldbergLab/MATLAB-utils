classdef VideoSetBrowser < VideoBrowser
    properties (Access = private)
        VideoDirectoryList          matlab.ui.control.UIControl
        VideoDirectoryPanel         matlab.ui.container.Panel
        VideoDirectoryLabel         matlab.ui.control.UIControl
        VideoIndexChangeListener    event.proplistener
        VideoCache                  MemoryCache
    end
    properties
        VideoDirectory              char = ''
        VideoFilter                 char = ''
    end
    properties (Transient)
    end
    properties (SetObservable, Access = private)
    end
    methods
        function obj = VideoSetBrowser(videoDirectory, videoFilter, varargin)
            obj@VideoBrowser('', varargin{:});
            if ~exist('videoFilter', 'var') || isempty(videoFilter)
                videoFilter = '.*\.[aAvViI]';
            end
            obj.VideoCache = MemoryCache(5);
            obj.VideoDirectory = videoDirectory;
            obj.VideoFilter = videoFilter;
            obj.UpdateVideoList();
            obj.HandleVideoIndexChange();
        end
        function createDisplayArea(obj)
            createDisplayArea@VideoBrowser(obj);
            % Adjust position of video panel to make room for dir panel
            obj.VideoPanel.Position = [0.25, 0, 0.75, 1];

            % Create widgets
            obj.VideoDirectoryPanel =   uipanel(obj.MainFigure, 'Units', 'normalized', 'Position', [0, 0, 0.25, 1]);
            obj.VideoDirectoryLabel =   uicontrol(obj.VideoDirectoryPanel, 'Style', 'text', 'String', '', 'Units', 'normalized' , 'Position', [0, 0.85, 1, 0.15]);
            obj.VideoDirectoryList =    uicontrol(obj.VideoDirectoryPanel, 'Style', 'listbox', 'Units', 'normalized', 'String', {}, 'Position', [0, 0, 1, 0.85]);

            obj.VideoIndexChangeListener = addlistener(obj.VideoDirectoryList, 'Value', 'PostSet', @obj.HandleVideoIndexChange);

            obj.VideoDirectoryLabel.FontSize = 12;

            obj.MainFigure.Name = 'Video Set Browser';
            obj.MainFigure.WindowScrollWheelFcn = @obj.ScrollWheelHandler;

            obj.UpdateVideoDirectoryLabel();
            obj.UpdateVideoList();
        end
        function HandleVideoIndexChange(obj, src, evt)
            % Handle a change in the selected video index in the listbox

            % Get the new video index
            videoIndex = obj.VideoDirectoryList.Value;
            
            % Get the path corresponding to the selected index
            selectedPath = obj.VideoDirectoryList.UserData{videoIndex};

            % Disable listbox while loading
            obj.VideoDirectoryList.Enable = "off";

            % Set the new video data
            if obj.VideoCache.isCached(videoIndex)
                obj.VideoData = obj.VideoCache.retrieveElement(videoIndex);
            else
                obj.VideoData = selectedPath;
                % Cache video
                obj.VideoCache.storeElement(videoIndex, obj.VideoData);
            end

            % Reenable list box after loading
            obj.VideoDirectoryList.Enable = "on";

            % Reset zoom
            obj.ZoomVideoAxes()
        end
        function UpdateVideoDirectoryLabel(obj)
            obj.VideoDirectoryLabel.String = ['Path: ', abbreviateText(obj.VideoDirectory, 20, 0.25)];
        end
        function UpdateVideoList(obj)
            [videoPaths, videoNames] = findFilesByRegex(obj.VideoDirectory, obj.VideoFilter, false, false);
            obj.VideoDirectoryList.String = videoNames;
            obj.VideoDirectoryList.UserData = videoPaths;
            
        end
        function ScrollWheelHandler(obj, src, evt)
            evt.VerticalScrollCount;
        end
%         function setVideoData(obj, newVideoData)
%             setVideoData@VideoBrowser(obj, newVideoData);
%         end
    end
end