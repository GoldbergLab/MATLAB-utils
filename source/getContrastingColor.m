function newRGB = getContrastingColor(seedRGBs, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% getContrastingColor: Get the best contrasting color(s) given other colors
% usage: RGB = getContrastingColor(RGBs, Name/Value, ...)
%
% where,
%    seedRGBs is a cell array
%    options is <description>
%    RGB is <description>
%
% <long description>
%
% See also: <related functions>
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    seedRGBs
    options.Discretization = 0.1
    options.Colormap = 'none'
    options.N = NaN
    options.Display = false
end

if isnan(options.N)
    single = true;
    newRGB = [];
    N = 1;
else
    single = false;
    newRGB = {};
    N = options.N;
end

d = options.Discretization;

if isnumeric(seedRGBs)
    if isvector(seedRGBs) && length(seedRGBs) == 3
        % Single RGB color
        seedRGBs = {seedRGBs};
    elseif size(seedRGBs, 2) == 3
        % Nx3 matrix of colors
        
    end
elseif iscell(seedRGBs)
    % Make sure all the colors in the cell array are RGb numeric triplets
    seedRGBs = cellfun(@validatecolor, seedRGBs, 'UniformOutput', false);
else
    error('Please specify the color')
end

if istext(options.Colormap)
    if strcmp(options.Colormap, 'none')
        coords = 0:d:1;
        [Rs, Gs, Bs] = ndgrid(coords, coords, coords);
        RGB_space = [Rs(:), Gs(:), Bs(:)];
    else
        RGB_space = colormap(options.Colormap);
    end
elseif isnumeric(options.Colormap) && size(options.Colormap, 2) == 3
    RGB_space = options.Colormap;
end

for r = 1:N
    maxDistance = 0;
    mostContrastingColor = [1, 0, 0];
    for k = 1:size(RGB_space, 1)
        rgbTest = RGB_space(k, :);
        newDistance = inf;
        for j = 1:length(seedRGBs)
            seedRGB = seedRGBs{j};
            distance = norm(rgbTest - seedRGB);
            newDistance = min(distance, newDistance);
            if distance < maxDistance
                % This point is not better, move on
                break;
            end
            if distance < newDistance
                newDistance = distance;
            end
        end
        if newDistance > maxDistance
            % This point is better
            maxDistance = newDistance;
            mostContrastingColor = rgbTest;
        end
    end
    
    if single
        newRGB = mostContrastingColor;
    else
        newRGB{end+1} = mostContrastingColor; %#ok<AGROW> 
        seedRGBs{end+1} = mostContrastingColor; %#ok<AGROW> 
    end
end

if options.Display
    if single
        displayRGBs = [seedRGBs, {newRGB}];
    else
        displayRGBs = seedRGBs;
    end
    viewColors(displayRGBs);
end