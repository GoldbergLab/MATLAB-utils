function anchorWidget(widget1, anchorPoint1, widget2, anchorPoint2, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% anchorWidget: Anchor one widget to another
% usage: anchorWidget(widget1, anchorPoint1, widget2, anchorPoint2)
%
% where,
%    widget1 is the graphics object to be moved
%    anchorPoint1 is a string/char array representing an anchor point on 
%       widget1, one of 'NW', 'N', 'NE', 'E', 'SE', 'S', 'SW', 'W', or 'C'
%    widget2 is the reference graphics object
%    anchorPoint2 is a string/char array representing an anchor point on 
%       widget2, one of 'NW', 'N', 'NE', 'E', 'SE', 'S', 'SW', 'W', or 'C'
%
% This function positions widget1 relative to widget2 by anchoring one of
%   the cardinal direction points on the boundary of widget1 (or the
%   center) to a cardinal direction point on the boundary of widget2 (or
%   the center). Note that widget1 cannot be the parent of widget2, but
%   widget2 may be the parent of widget1.
%
% See also: stackChildren, gridChildren
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    widget1 matlab.graphics.Graphics
    anchorPoint1 {mustBeMember(anchorPoint1, {'NW', 'N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'C'})}
    widget2 matlab.graphics.Graphics
    anchorPoint2 {mustBeMember(anchorPoint2, {'NW', 'N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'C'})}
    options.Offset = [0, 0]
end

commonUnit = 'inches';
anchorPoints = {anchorPoint1, anchorPoint2};
positions = [getPositionWithUnits(widget1, commonUnit); ...
             getPositionWithUnits(widget2, commonUnit)];

if widget1.Parent == widget2
    % If widget2 is the parent of widget1, then zero out its position
    positions(2, 1:2) = [0, 0];
elseif widget2.Parent == widget1
    error('Cannot anchor parent relative to child');
end


anchorPositions = zeros(2, 2);

% Find position of specified anchor points
for k = 1:2
    switch anchorPoints{k}
        case 'NW'
            anchorPositions(k, 1) = positions(k, 1);
            anchorPositions(k, 2) = positions(k, 2) + positions(k, 4);
        case 'N'
            anchorPositions(k, 1) = positions(k, 1) + positions(k, 3)/2;
            anchorPositions(k, 2) = positions(k, 2) + positions(k, 4);
        case 'NE'
            anchorPositions(k, 1) = positions(k, 1) + positions(k, 3);
            anchorPositions(k, 2) = positions(k, 2) + positions(k, 4);
        case 'E'
            anchorPositions(k, 1) = positions(k, 1) + positions(k, 3);
            anchorPositions(k, 2) = positions(k, 2) + positions(k, 4)/2;
        case 'SE'
            anchorPositions(k, 1) = positions(k, 1) + positions(k, 3);
            anchorPositions(k, 2) = positions(k, 2);
        case 'S'
            anchorPositions(k, 1) = positions(k, 1) + positions(k, 3)/2;
            anchorPositions(k, 2) = positions(k, 2);
        case 'SW'
            anchorPositions(k, 1) = positions(k, 1);
            anchorPositions(k, 2) = positions(k, 2);
        case 'W'
            anchorPositions(k, 1) = positions(k, 1);
            anchorPositions(k, 2) = positions(k, 2) + positions(k, 4)/2;
        case 'C'
            anchorPositions(k, 1) = positions(k, 1) + positions(k, 3)/2;
            anchorPositions(k, 2) = positions(k, 2) + positions(k, 4)/2;
    end
end


% Determine how much to move widget1 to anchor anchorPoint1 to anchorPoint2
delta = diff(anchorPositions(:, 1:2));

% Move widget1
changePositionWithUnits(widget1, delta, commonUnit, [1, 2]);

if any(options.Offset)
    % Adjust offset sign so positive = further away
    switch anchorPoints{2}
        case 'NW'
            offsetDirections = [-1, 1];
        case 'N'
            offsetDirections = [0, 1];
        case 'NE'
            offsetDirections = [1, 1];
        case 'E'
            offsetDirections = [1, 0];
        case 'SE'
            offsetDirections = [1, -1];
        case 'S'
            offsetDirections = [0, -1];
        case 'SW'
            offsetDirections = [-1, -1];
        case 'W'
            offsetDirections = [-1, 0];
        case 'C'
            offsetDirections = [0, 0];
    end
    options.Offset = options.Offset .* offsetDirections;

    % Apply offset
    changePositionWithUnits(widget1, options.Offset, widget1.Units, [1, 2]);
end