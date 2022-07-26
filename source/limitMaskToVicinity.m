function limited_mask = limitMaskToVicinity(mask, vicinity_mask, radius)
% Produce a limited_mask which is identical to mask within the vicinity of
% the bounding box of true pixels of vicinity_mask

% Get limits of bbox of true values in vicinity mask
[xlimits, ylimits] = getMaskLim(vicinity_mask);
xlimits = xlimits + [-radius, radius];
ylimits = ylimits + [-radius, radius];

% Ensure vicinity limits are in bounds
xlimits(1) = max(1, xlimits(1));
xlimits(2) = min(size(mask, 1), xlimits(2));
ylimits(1) = max(1, ylimits(1));
ylimits(2) = min(size(mask, 2), ylimits(2));

% Create overlay to limit mask to vicinity
vicinity_overlay = false(size(mask));
vicinity_overlay(xlimits(1):xlimits(2), ylimits(1):ylimits(2)) = true;

% Limit mask
limited_mask = mask & vicinity_overlay;