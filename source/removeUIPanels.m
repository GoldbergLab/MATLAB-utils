function fig = removeUIPanels(fig)
% Remove any uipanels from the given figure without deleting or moving 
% children of uipanels

panelsToRemove = gobjects().empty();
originalChildren = fig.Children;
for k = 1:length(originalChildren)
    child = originalChildren(k);
    if isa(child, 'matlab.ui.container.Panel')
        panel = child;
        panelChildren = panel.Children;
        for j = 1:length(panelChildren)
            child = panelChildren(j);
            childPosition = getWidgetFigurePosition(child, child.Units);
            child.Parent = fig;
            child.Position = childPosition;
        end
        panelsToRemove(end+1) = panel; %#ok<AGROW> 
    end
end
for panel = panelsToRemove
    delete(panel);
end