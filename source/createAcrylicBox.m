function svgText = createAcrylicBox(boxSize, svgSavePath, inchesPerTab, materialThickness, materialDims)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% createAcrylicBox: Generate an SVG image of the pieces of a box with the
%                   given parameters, useful laser cutting.
%
% usage:  svgText = createAcrylicBox(boxSize, svgSavePath)
%         svgText = createAcrylicBox(boxSize, svgSavePath, inchesPerTab)
%         svgText = createAcrylicBox(boxSize, svgSavePath, inchesPerTab, 
%                                    materialThickness)
%         svgText = createAcrylicBox(boxSize, svgSavePath, inchesPerTab, 
%                                    materialThickness, materialDims)
% where,
%    svgText is the text of the svg file
%    boxSize is a 1x3 vector giving the outside dimensions of the box in 
%       thou (thousandths of an inch). The untabbed side will have the 
%       dimensions given by the first two elements of this vector. For 
%       example, if the box size is [6000, 7000, 8000] (6in x 7in x 8in), 
%       one of the 6in x 7in sides will be the untabbed door of the box.
%    svgSavePath is the filepath to use to save the SVG file
%    inchesPerTab (optional) is the length of each tab (innie + outie).
%       Default = 0.5 inches per tab
%    materialThickness (optional) is the thickness of the material the box 
%       will be cut from in thou. This determines the depth of the tabs. 
%       Default = 125 thou (1/8 inch)
%    materialDims (optional) is a 1x2 vector indicating the canvas size to 
%       make the SVG file with, in thou. This does not affect the box, just 
%       the canvas that SVG editors will display the box on when opened. 
%       Default = [24000, 12000]
%
% This function creates an SVG file containing the outlines of the walls of
%   a box. If material is cut with a laser cutter using the output pattern 
%   of this script, the resulting pieces can be assembled into a box. The 
%   box has interlocking tabs, which allows for easier assembly and 
%   stronger bonding. The box also features one side that is left 
%   un-tabbed, which can serve as a door or an opening. This script also 
%   outputs the SVG file as a char array, and displays a figure showing a 
%   preview of the shape created.
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Determine # of tabs to include
if ~exist('inchesPerTab', 'var')
    inchesPerTab = 0.5;
end
numTabs = [0, 0, 0];
for k = 1:3
    dim = boxSize(k);
    numTabs(k) = ceil(dim/(inchesPerTab*1000));
    dim
    inchesPerTab
    numTabs
end

if ~exist('materialThickness', 'var')
    materialThickness = 125;
end
if ~exist('materialDims', 'var')
    materialDims = [24000, 12000];
end

% Shape determinations (F=flat-out, f=flat-in, O=outie, I=innie):
faceShapes = {
    ['f', 'O', 'I', 'O'];
    ['f', 'O', 'I', 'O']; 
    ['f', 'I', 'O', 'I'];
    ['f', 'I', 'O', 'I'];
    ['O', 'I', 'O', 'I'];
    ['F', 'F', 'F', 'F']};
% Direction of each edge (corresponding to edge shapes above), given as a
% coordinate index
faceDirections = [
    [2, 3, 2, 3];
    [2, 3, 2, 3];
    [1, 3, 1, 3];
    [1, 3, 1, 3];
    [2, 1, 2, 1];
    [2, 1, 2, 1]
    ];
% Coordinate indices indicating which dimension each face is placed out on
faceCoordinateIndices = [1, 1, 2, 2, 3, 3];
% 
unitEdgeOffsets = [
    [ 1, 0];
    [ 0, 1];
    [-1, 0];
    [0, -1];
    ];

faceCoordinates = {};
for faceNum = 1:6
    faceCoordinates{faceNum} = createFaceCoordinates(faceShapes{faceNum}, faceDirections(faceNum, :), boxSize, numTabs, materialThickness);
end

svgStart = [
['<?xml version="1.0" encoding="UTF-8"?>', newline], ...
['<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">', newline], ...
['<!-- Creator: CorelDRAW 2017 -->', newline], ...
['<svg xmlns="http://www.w3.org/2000/svg" xml:space="preserve" width="24in" height="12in" version="1.1" style="shape-rendering:geometricPrecision; text-rendering:geometricPrecision; image-rendering:optimizeQuality; fill-rule:evenodd; clip-rule:evenodd"', newline], ...
['viewBox="0 0 ',num2str(materialDims(1)),' ',num2str(materialDims(2)),'"', newline], ...
[' xmlns:xlink="http://www.w3.org/1999/xlink">', newline], ...
[' <defs>', newline], ...
['  <style type="text/css">', newline], ...
['   <![CDATA[', newline], ...
['    .str0 {stroke:red;stroke-width:3;stroke-miterlimit:2.61313}', newline], ...
['    .fil0 {fill:none}', newline], ...
['   ]]>', newline], ...
['  </style>', newline], ...
[' </defs>', newline], ...
[' <g>', newline], ...
['  <metadata id="CorelCorpID_0Corel-Layer"/>', newline], ...
];
svgGroupStart = ['  <g>', newline];
svgLineFormat = ['    <line class="fil0 str0" x1="%.3f" y1="%.3f" x2="%.3f" y2="%.3f" />', newline];
svgGroupEnd = ['  </g>', newline];
svgEnd = [[' </g>', newline], ['</svg>']];

svgText = svgStart;
intraFaceDistance = 250;
offset = [0; 0];
figure;
for f = 1:length(faceCoordinates)
    singleFaceCoordinates = faceCoordinates{f};
    minX = min(singleFaceCoordinates(1, :));
    minY = min(singleFaceCoordinates(2, :));
    singleFaceCoordinates = singleFaceCoordinates - [minX; minY];
    maxX = max(singleFaceCoordinates(1, :));
    singleFaceCoordinates = singleFaceCoordinates + offset;
    plot(singleFaceCoordinates(1, :), singleFaceCoordinates(2, :));
    hold on;

    lineInputs = [singleFaceCoordinates(1, 1:end-1); singleFaceCoordinates(2, 1:end-1); singleFaceCoordinates(1, 2:end); singleFaceCoordinates(2, 2:end)];
    lines = sprintf(svgLineFormat, lineInputs);
    svgText = [svgText, svgGroupStart, lines, svgGroupEnd];
    offset = offset + [maxX + intraFaceDistance; 0];
end
axis equal
svgText = [svgText, svgEnd];
writePlainText(svgSavePath, svgText);

function faceCoordinates = createFaceCoordinates(faceShape, faceDirections, boxSize, numTabs, materialThickness)
%disp('starting face:')
faceCoordinates = [];
for k = 1:length(faceShape)
    edgeShape = faceShape(k);
    edgeDirection = faceDirections(k);
    edgeSize = boxSize(edgeDirection);
    otherSize = boxSize(unique(faceDirections(faceDirections ~= edgeDirection)));
    if edgeShape == 'F' || edgeShape == 'f'
        currentNumTabs = 0;
    else
        currentNumTabs = numTabs(edgeDirection);
    end
    edge = createUrEdge(currentNumTabs) .* [edgeSize; materialThickness];
%    figure;
%    plot(edge(1, :), edge(2, :));
%    title(edgeShape);
%    hold on;
    if edgeShape == 'I'
        edge = flipEdge(edge);
    end
    edge = edge + [0; otherSize/2 - materialThickness/2];
    if edgeShape == 'F'
        % Extend edge to the level of one material thickness
        edge = edge + [0; materialThickness];
    elseif edgeShape == 'f'
        % Depress edge to the level of one material thickness
%        edge = edge - [0; materialThickness/2];
    end
%    plot(edge(1, :), edge(2, :));
    edge = rotateEdgeK(edge, k-1);
    edge = eliminateRepeatPoints(edge);
    faceCoordinates = eliminateRepeatPoints(faceCoordinates);
    [faceCoordinates, edge] = trimSegments(faceCoordinates, edge);
    faceCoordinates = [faceCoordinates, edge];
    faceCoordinates = eliminateRepeatPoints(faceCoordinates);
end
faceCoordinates = eliminateRepeatPoints(faceCoordinates);
[faceCoordinates, ~] = trimSegments(faceCoordinates, faceCoordinates);
faceCoordinates = eliminateRepeatPoints(faceCoordinates);

function coordinates = eliminateRepeatPoints(coordinates)
repeatIndices = all(coordinates(:, 1:end-1) == coordinates(:, 2:end), 1);
coordinates(:, repeatIndices) = [];

function [coordinates1, coordinates2] = trimSegments(coordinates1, coordinates2)
% Assume last segment of 1 is perpendicular to last segment of 2
if ~isempty(coordinates1) && any(coordinates1(:, end) ~= coordinates2(:, 1))
    dir1 = find((coordinates1(:, end-1) - coordinates1(:, end)), 1);
    dir2 = find((coordinates2(:, 2) - coordinates2(:, 1)), 1);
    end1 = coordinates2(dir1, 1);
    start2 = coordinates1(dir2, end);
    coordinates1(dir1, end) = end1;
    coordinates2(dir2, 1) = start2;
end
%coordinates = [coordinates1, coordinates2];

function urEdge = createUrEdge(numTabs, varargin)
if nargin > 1
    tabFraction = varargin{1};
    if tabFraction <= 0 || tabFraction >= 1
        warning(['Bad tab fraction: ', num2str(tabFraction)]);
    end
else
    tabFraction = 0.5;
end
urEdge = [0; 0];
urSegment = [[tabFraction, tabFraction, 1, 1]; [0, 1, 1, 0]];
scaleFactor = 1/(numTabs + (1-tabFraction));
lastX = 0;
lastY = 0;
for t = 1:numTabs
    urEdge = [urEdge, urSegment .* [scaleFactor; 1] + [lastX; lastY]];
    lastX = urEdge(1, end);
    lastY = urEdge(2, end);
end
urEdge = [urEdge, [[lastX, 1]; [lastY, 0]]];
urEdge = urEdge - [0.5; 0.5];

function flippedEdge = flipEdge(edge)
flippedEdge = [edge(1, :); -edge(2, :)];

function rotatedEdge = rotateEdge(edge)
% Rotate edge coordinates by 90 degrees
rotatedEdge = [edge(2, :); -edge(1, :)];

function rotatedEdge = rotateEdgeK(edge, k)
% Rotate edge coordinates by k*90 degrees
rotatedEdge = edge;
for c = 1:k
    rotatedEdge = rotateEdge(rotatedEdge);
end