function tileFigures(figureList, tileSize)

tiledFig = figure();
panels = gobjects().empty;
for k = 1:length(figureList)
    panels(k) = uipanel('Parent', tiledFig);
    fig = figureList(k);
    copyobj(fig.Children, panels(k));
    tileChildren(tiledFig, tileSize);
end

%     for childNum = 1:length(fig.Children)
%         child = fig.Children(childNum);
%         originalUnits = child.Position;
%         child.Units = 'normalized';
%         child.Units = originalUnits;
%     end
