function [imageData, colormaps, clims, aspectRatios, ax_positions, plotters, fig] = getFigureImageData(figureOrFigurePath)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% getFigureImageData: Extract image data from an existing figure
% usage:  [imageData, colormaps, clims, aspectRatios, ax_positions, plotters, fig] = getFigureImageData(figureOrFigurePath)
%
% where,
%    figureOrFigurePath is a figure object or a path to a saved figure file
%    imageData is a cell array of the image data found in the figure
%    colormaps is a cell array of colormaps for images found in the figure
%    clims is a cell array of clims for images found in the figure
%    aspectRatios is a cell array of aspectRatios for images found in the figure
%    ax_positions is a cell array of axes positions for images found in the figure
%    plotters is a cell array of the plotters for images found in the figure
%    fig is the figure itself
%
% This function extracts any image data found in a figure or saved figure
%   file, along with some metadata about the image and how it was displayed
%   in the figure.
%
% See also:
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ischar(figureOrFigurePath)
    fig = openfig(figureOrFigurePath);
    [~, name, ~] = fileparts(figureOrFigurePath);
    fig.NumberTitle = 'off';
    fig.Name = name;
else
    fig = figureOrFigurePath;
end
imageData = {};
colormaps = {};
clims = {};
aspectRatios = {};
plotters = {};
ax_positions = {};

for k = 1:length(fig.Children)
    ax = fig.Children(k);
    if isa(ax, 'matlab.graphics.axis.Axes')
        for j = 1:length(ax.Children)
            if isa(ax.Children(j), 'matlab.graphics.primitive.Image')
                im = ax.Children(j);
                yl = ylim(ax);
                yl(1) = ceil(yl(1));
                yl(2) = floor(yl(2));
                xl = xlim(ax);
                xl(1) = ceil(xl(1));
                xl(2) = floor(xl(2));
                imageData{end+1} = im.CData(yl(1):yl(2), xl(1):xl(2));
                colormaps{end+1} = ax.Colormap;
                clims{end+1} = ax.CLim;
                p = ax.InnerPosition;
                aspectRatios{end+1} = p(3)/p(4);
                plotters{end+1} = @()replot(imageData{end}, colormaps{end}, clims{end}, aspectRatios{end});
                ax.Units = 'pixels';
                ax_positions{end+1} = ax.InnerPosition;
            end
        end
    end
end

function replot(im, cmap, c_lim, aspectRatio)
f = figure;
ax = axes(f);
imshow(imresize(im, [200, 200*aspectRatio]), 'Colormap', cmap);
clim(ax, c_lim);