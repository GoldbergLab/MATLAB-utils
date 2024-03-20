function [presentation, slide] = pptAddFigure(presentationOrPath, fig, slideNum)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% pptAddFigure: Add a figure to a new or existing presentation
% usage: presentation = pptAddFigure(presentationOrPath)
%        presentation = pptAddFigure(presentationOrPath, fig)
%        presentation = pptAddFigure(presentationOrPath, fig, slideNum)
%
% where,
%    presentationOrPath is either a path to an existing presentation, a
%       path for a new presentation, or an existing presentation object
%       function.
%    fig is a handle to a MATLAB figure to insert in the presentation
%    slideNum is an optional index to insert the new slide. If omitted, the
%       slide will be added at the end
%    presentation is the presentation object
%
% This function uses the MATLAB activex interface for the VBA powerpoint
%   API to add a MATLAB figure to the 
%
% See also: 
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ischar(presentationOrPath)
    presentationPath = presentationOrPath;
    % User passed in path to open/create
    ppt = actxserver('PowerPoint.Application');
    [folder, ~, ext] = fileparts(presentationPath);
    if isempty(folder)
        % Assume file refers to current working directory.
        presentationPath = fullfile(pwd(), presentationPath);
    end
    if any(strcmpi(ext, {'.ppt', '.pptx', '.odp', '.pptm', '.ppsx', '.ppsm', '.pps'}))
        if exist(presentationPath, 'file')
            presentation = ppt.Presentations.Open(presentationPath);
        else
            presentation = ppt.Presentations.Add();
        end
    else
        error('Given file is not a valid powerpoint presentation: %s', presentationPath);
    end
else
    % User passed in ppt object
    presentation = presentationOrPath;
    presentationPath = '';
end

% Get blank slide template
blankSlideTemplate = presentation.SlideMaster.CustomLayouts.Item(7);
% Determine slide number to use
if ~exist('slideNum', 'var') || isempty(slideNum)
    slideNum = presentation.Slides.count+1;
end
% Create a new blank slide
slide = presentation.Slides.AddSlide(slideNum, blankSlideTemplate);

slideWidth = presentation.PageSetup.SlideWidth;
slideHeight = presentation.PageSetup.SlideHeight;
marginFactor = 1/40;

try
    tempImagePath = [tempname(), '.emf']; %sprintf('tmp%s.raw', r);
    exportgraphics(fig, tempImagePath, 'ContentType', 'vector');
    exportSize = getExportSize(fig);
    [imageWidth, imageHeight] = scaleBoxToFitBox(exportSize(2), exportSize(1), slideWidth * (1-2*marginFactor), slideHeight * (1-2*marginFactor));
    image = slide.Shapes.AddPicture(tempImagePath, 'msoFalse', 'msoTrue', slideWidth*marginFactor, slideHeight*marginFactor, imageWidth, imageHeight);
    
    delete(tempImagePath);
catch ME
    disp(ME.getReport())
    % Try to delete temp file even if we get an error
    if exist(tempImagePath, 'file')
        delete(tempImagePath);
    end
end

if isempty(presentationPath)
    presentation.Save();
else
    presentation.SaveAs(presentationPath);
end
