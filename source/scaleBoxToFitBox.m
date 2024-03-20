function [newInnerWidth, newInnerHeight, scale] = scaleBoxToFitBox(innerWidth, innerHeight, outerWidth, outerHeight)
if innerHeight/innerWidth > outerHeight/outerWidth
    % Scale based on height
    scale = outerHeight / innerHeight;
else
    % Scale based on width
    scale = outerWidth / innerWidth;
end
newInnerWidth = scale * innerWidth;
newInnerHeight = scale * innerHeight;