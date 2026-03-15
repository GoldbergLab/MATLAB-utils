classdef DockablePanel < handle
    properties
        MainPanel matlab.ui.container.Panel
        SubPanel matlab.ui.container.Panel
        TitleLabel matlab.ui.control.UIControl
    end
    properties  % UIPanel arguments
      BackgroundColor = [0.9400 0.9400 0.9400]
      BeingDeleted
      BorderType = 'etchedin'
      BorderWidth = 1
      BusyAction = 'queue'
      ButtonDownFcn = ''
      Children %= [0×0 GraphicsPlaceholder]
      Clipping = 'on'
      ContextMenu %= [0×0 GraphicsPlaceholder]
      CreateFcn = ''
      DeleteFcn = ''
      Enable = on
      FontAngle = 'normal'
      FontName = 'MS Sans Serif'
      FontSize = 8
      FontUnits = 'points'
      FontWeight = 'normal'
      ForegroundColor = [0 0 0]
      HandleVisibility = 'on'
      HighlightColor = [1 1 1]
      InnerPosition = [0.0043 0.0057 0.9929 0.9905]
      Interruptible = 'on'
      Layout %= [0×0 matlab.ui.layout.LayoutOptions]
      OuterPosition = [0 0 1 1]
      Parent %= [1×1 Figure]
      Position = [0 0 1 1]
      Scrollable = 'off'
      ShadowColor = [0.7000 0.7000 0.7000]
      SizeChangedFcn = ''
      Tag = ''
      Title = ''
      TitlePosition = 'lefttop'
      Tooltip = ''
      Type = 'uidockablepanel'
      Units = 'normalized'
      UserData = []
      Visible = 'on'
    end
    methods
        function obj = DockablePanel(props)
            arguments
                props.?matlab.ui.container.Panel
            end
            mainPanelSharedPropNames = ["BackgroundColor", "ForegroundColor"];
            mainPanelExclusivePropNames = ["Position"]; %#ok<NBRAK2> 
            titleSharedPropNames = ["FontAngle", "FontName", "FontSize", "FontUnits", "FontWeight", "BackgroundColor", "ForegroundColor"];
            titleExclusivePropNames = [];
            mainPanelSharedProps = struct();
            mainPanelExclusiveProps = struct();
            titleSharedProps = struct();
            titleExclusiveProps = struct();

            for name = fieldnames(props)
                if any(name == mainPanelSharedPropNames)
                    mainPanelProps.(name) = props.(name);
                end
                if any(name == mainPanelExclusivePropNames)
                    mainPanelProps.(name) = props.(name);
                    props = rmfield(props, name);
                end
                if any(name == titleSharedPropNames)
                    titleProps.(name) = props.(name);
                end
                if any(name == titleExclusivePropNames)
                    titleProps.(name) = props.(name);
                    props = rmfield(props, name);
                end
            end

            obj.MainPanel = uipanel();
            obj.TitleLabel = uicontrol();
            if isfield(props, 'Title')
                obj.Title = props.Title;
            end
            
            mainPanelSharedPropNames = namedargs2cell(mainPanelSharedPropNames);
            mainPanelExclusivePropNames = namedargs2cell(mainPanelExclusivePropNames);
            titleSharedPropNames = namedargs2cell(titleSharedPropNames);
            titleExclusivePropNames = namedargs2cell(titleExclusivePropNames);

            % Pass remaining arguments to the uipanel
            props = namedargs2cell(props);
            obj.SubPanel = uipanel(props{:}, 'Title', '');
        end
    end
    methods % Setters
        function set.BackgroundColor(obj, BackgroundColor)
            obj.SubPanel.BackgroundColor = BackgroundColor; %#ok<*MCSUP> 
        end
        function set.BorderType(obj, BorderType)
            obj.SubPanel.BorderType = BorderType;
        end
        function set.BorderWidth(obj, BorderWidth)
            obj.SubPanel.BorderWidth = BorderWidth;
        end
        function set.BusyAction(obj, BusyAction)
            obj.SubPanel.BusyAction = BusyAction;
        end
        function set.ButtonDownFcn(obj, ButtonDownFcn)
            obj.SubPanel.ButtonDownFcn = ButtonDownFcn;
        end
        function set.Children(obj, Children)
            obj.SubPanel.Children = Children;
        end
        function set.Clipping(obj, Clipping)
            obj.SubPanel.Clipping = Clipping;
        end
        function set.ContextMenu(obj, ContextMenu)
            obj.SubPanel.ContextMenu = ContextMenu;
        end
        function set.CreateFcn(obj, CreateFcn)
            obj.SubPanel.CreateFcn = CreateFcn;
        end
        function set.DeleteFcn(obj, DeleteFcn)
            obj.SubPanel.DeleteFcn = DeleteFcn;
        end
        function set.Enable(obj, Enable)
            obj.SubPanel.Enable = Enable;
        end
        function set.FontAngle(obj, FontAngle)
            obj.SubPanel.FontAngle = FontAngle;
        end
        function set.FontName(obj, FontName)
            obj.SubPanel.FontName = FontName;
        end
        function set.FontSize(obj, FontSize)
            obj.SubPanel.FontSize = FontSize;
        end
        function set.FontUnits(obj, FontUnits)
            obj.SubPanel.FontUnits = FontUnits;
        end
        function set.FontWeight(obj, FontWeight)
            obj.SubPanel.FontWeight = FontWeight;
        end
        function set.ForegroundColor(obj, ForegroundColor)
            obj.SubPanel.ForegroundColor = ForegroundColor;
        end
        function set.HandleVisibility(obj, HandleVisibility)
            obj.SubPanel.HandleVisibility = HandleVisibility;
        end
        function set.HighlightColor(obj, HighlightColor)
            obj.SubPanel.HighlightColor = HighlightColor;
        end
        function set.InnerPosition(obj, InnerPosition)
            obj.SubPanel.InnerPosition = InnerPosition;
        end
        function set.Interruptible(obj, Interruptible)
            obj.SubPanel.Interruptible = Interruptible;
        end
        function set.Layout(obj, Layout)
            obj.SubPanel.Layout = Layout;
        end
        function set.OuterPosition(obj, OuterPosition)
            obj.SubPanel.OuterPosition = OuterPosition;
        end
        function set.Parent(obj, Parent)
            obj.SubPanel.Parent = Parent;
        end
        function set.Position(obj, Position)
            obj.SubPanel.Position = Position;
        end
        function set.Scrollable(obj, Scrollable)
            obj.SubPanel.Scrollable = Scrollable;
        end
        function set.ShadowColor(obj, ShadowColor)
            obj.SubPanel.ShadowColor = ShadowColor;
        end
        function set.SizeChangedFcn(obj, SizeChangedFcn)
            obj.SubPanel.SizeChangedFcn = SizeChangedFcn;
        end
        function set.Tag(obj, Tag)
            obj.SubPanel.Tag = Tag;
        end
        function set.Title(obj, Title)
            obj.SubPanel.Title = Title;
        end
        function set.TitlePosition(obj, TitlePosition)
            obj.SubPanel.TitlePosition = TitlePosition;
        end
        function set.Tooltip(obj, Tooltip)
            obj.SubPanel.Tooltip = Tooltip;
        end
        function set.Type(obj, Type)
            obj.SubPanel.Type = Type;
        end
        function set.Units(obj, Units)
            obj.SubPanel.Units = Units;
        end
        function set.UserData(obj, UserData)
            obj.SubPanel.UserData = UserData;
        end
        function set.Visible(obj, Visible)
            obj.SubPanel.Visible = Visible;
        end
    end
    methods % Getters
        function BackgroundColor = get.BackgroundColor(obj)
            BackgroundColor = obj.SubPanel.BackgroundColor;
        end
        function BeingDeleted = get.BeingDeleted(obj)
            BeingDeleted = obj.SubPanel.BeingDeleted;
        end
        function BorderType = get.BorderType(obj)
            BorderType = obj.SubPanel.BorderType;
        end
        function BorderWidth = get.BorderWidth(obj)
            BorderWidth = obj.SubPanel.BorderWidth;
        end
        function BusyAction = get.BusyAction(obj)
            BusyAction = obj.SubPanel.BusyAction;
        end
        function ButtonDownFcn = get.ButtonDownFcn(obj)
            ButtonDownFcn = obj.SubPanel.ButtonDownFcn;
        end
        function Children = get.Children(obj)
            Children = obj.SubPanel.Children;
        end
        function Clipping = get.Clipping(obj)
            Clipping = obj.SubPanel.Clipping;
        end
        function ContextMenu = get.ContextMenu(obj)
            ContextMenu = obj.SubPanel.ContextMenu;
        end
        function CreateFcn = get.CreateFcn(obj)
            CreateFcn = obj.SubPanel.CreateFcn;
        end
        function DeleteFcn = get.DeleteFcn(obj)
            DeleteFcn = obj.SubPanel.DeleteFcn;
        end
        function Enable = get.Enable(obj)
            Enable = obj.SubPanel.Enable;
        end
        function FontAngle = get.FontAngle(obj)
            FontAngle = obj.SubPanel.FontAngle;
        end
        function FontName = get.FontName(obj)
            FontName = obj.SubPanel.FontName;
        end
        function FontSize = get.FontSize(obj)
            FontSize = obj.SubPanel.FontSize;
        end
        function FontUnits = get.FontUnits(obj)
            FontUnits = obj.SubPanel.FontUnits;
        end
        function FontWeight = get.FontWeight(obj)
            FontWeight = obj.SubPanel.FontWeight;
        end
        function ForegroundColor = get.ForegroundColor(obj)
            ForegroundColor = obj.SubPanel.ForegroundColor;
        end
        function HandleVisibility = get.HandleVisibility(obj)
            HandleVisibility = obj.SubPanel.HandleVisibility;
        end
        function HighlightColor = get.HighlightColor(obj)
            HighlightColor = obj.SubPanel.HighlightColor;
        end
        function InnerPosition = get.InnerPosition(obj)
            InnerPosition = obj.SubPanel.InnerPosition;
        end
        function Interruptible = get.Interruptible(obj)
            Interruptible = obj.SubPanel.Interruptible;
        end
        function Layout = get.Layout(obj)
            Layout = obj.SubPanel.Layout;
        end
        function OuterPosition = get.OuterPosition(obj)
            OuterPosition = obj.SubPanel.OuterPosition;
        end
        function Parent = get.Parent(obj)
            Parent = obj.SubPanel.Parent;
        end
        function Position = get.Position(obj)
            Position = obj.SubPanel.Position;
        end
        function Scrollable = get.Scrollable(obj)
            Scrollable = obj.SubPanel.Scrollable;
        end
        function ShadowColor = get.ShadowColor(obj)
            ShadowColor = obj.SubPanel.ShadowColor;
        end
        function SizeChangedFcn = get.SizeChangedFcn(obj)
            SizeChangedFcn = obj.SubPanel.SizeChangedFcn;
        end
        function Tag = get.Tag(obj)
            Tag = obj.SubPanel.Tag;
        end
        function Title = get.Title(obj)
            Title = obj.SubPanel.Title;
        end
        function TitlePosition = get.TitlePosition(obj)
            TitlePosition = obj.SubPanel.TitlePosition;
        end
        function Tooltip = get.Tooltip(obj)
            Tooltip = obj.SubPanel.Tooltip;
        end
        function Type = get.Type(obj)
            Type = obj.SubPanel.Type;
        end
        function Units = get.Units(obj)
            Units = obj.SubPanel.Units;
        end
        function UserData = get.UserData(obj)
            UserData = obj.SubPanel.UserData;
        end
        function Visible = get.Visible(obj)
            Visible = obj.SubPanel.Visible;
        end
    end
end