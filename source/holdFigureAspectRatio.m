function holdFigureAspectRatio(fig, state)
arguments
    fig matlab.ui.Figure
    state (1, 1) matlab.lang.OnOffSwitchState = 'on' 
end

if state
    figPosition = getUIPositionInUnits(fig, 'pixels');
    currentAspectRatio = figPosition(4)/figPosition(3);
    fig.SizeChangedFcn = resizeFunctionFactory(currentAspectRatio);
    fig.Interruptible = 'off';
    fig.BusyAction = "cancel";
else
    fig.SizeChangedFcn = '';
end

end

function resizeFunction = resizeFunctionFactory(aspectRatio)
    import java.awt.Robot;

    function theResizeFunction(src, ~)
        p = getUIPositionInUnits(src, 'pixels');
        currentAspectRatio = p(4)/p(3);
        threshold = 0.01;
        if abs(aspectRatio - currentAspectRatio) > threshold
            factor = sqrt(aspectRatio / currentAspectRatio);
            p(4) = p(4) * factor;
            p(3) = p(3) / factor;
            resizeFunc = src.SizeChangedFcn;
            src.SizeChangedFcn = '';
            drawnow();
            setUIPositionInUnits(src, p, 'pixels');
            mouse = Robot;
            r = groot();
            screenSize = r.ScreenSize();
            mouse.mouseMove(p(1)+p(3), p(2));
            drawnow();
            src.SizeChangedFcn = resizeFunc;
        end
    end
    resizeFunction = @theResizeFunction;
end