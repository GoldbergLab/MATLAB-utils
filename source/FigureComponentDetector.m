function FigureComponentDetector(src, ~)
persistent matches
newMatches = findAllMatchingChildren(src, @(w)checkWidget(w, src.CurrentPoint));
if ~isempty(newMatches) && (length(matches) ~= length(newMatches) || ~all(matches == newMatches) || isempty(matches))
    disp(newMatches);
end
matches = newMatches;

function match = checkWidget(w, currentPoint)
if isprop(w, 'Units')
    match = isPositionWithinWidget(w, currentPoint);
else
    match = false;
end