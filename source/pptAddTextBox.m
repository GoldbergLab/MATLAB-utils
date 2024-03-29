function textBox = pptAddTextBox(slide, x, y, width, height, txt, fontSize, bold, italic)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% pptAddTextBox: Add a text box to a powerpoint slide
% usage: textBox = pptAddTextBox(slide, x, y, width, height, txt)
%        textBox = pptAddTextBox(slide, x, y, width, height, txt, fontSize, bold, italic)
%
% where,
%    slide is a slide object generated by the Presentation.Slides.AddSlide
%       function.
%    x is the x position of the upper left hand corner of the box in points
%    y is the y position of the upper left hand corner of the box in points
%    width is the width of the box in points
%    height is the height of the box in points
%    txt is an array of characters to put in the text box (the text itself)
%    fontSize (optional) is the font size to use in points
%
% This function uses the MATLAB activex interface for the VBA powerpoint
%   API to add text boxes to powerpoint files.
%
% See also: 
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist('fontSize', 'var') || isempty(fontSize)
    fontSize = [];
end
if ~exist('italic', 'var') || isempty(italic)
    italic = false;
end

% Translate boolean value into appropriate VBA constant
if bold
    bold = 'msoTrue';
else
    bold = 'msoFalse';
end

% Translate boolean value into appropriate VBA constant
if italic
    italic = 'msoTrue';
else
    italic = 'msoFalse';
end

% Create textbox with given location and dimensions
textBox = slide.Shapes.AddTextbox('msoTextOrientationHorizontal', x, y, width, height);
% Set text box text content
textBox.TextFrame.TextRange.Text = txt;
% If desired, change font
if ~isempty(fontSize)
    textBox.TextFrame.TextRange.Font.Size = fontSize;
end
% Set boldness
textBox.TextFrame.TextRange.Font.Bold = bold;
% Set italicness
textBox.TextFrame.TextRange.Font.Italic = italic;
