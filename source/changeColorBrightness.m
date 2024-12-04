function RGB = changeColorBrightness(RGB, brightnessFactor)
if iscell(RGB)
    RGB = cellfun(@(c)changeColorBrightness(c, brightnessFactor), RGB, 'UniformOutput', false);
else
    RGB = validatecolor_safe(RGB);
    RGB = RGB * brightnessFactor;
    RGB = min(RGB, 1);
    RGB = max(RGB, 0);
end