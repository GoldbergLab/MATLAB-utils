function color = validatecolor_safe(color)
    % This method will shadow the built in validatecolor.
    % validatecolor but with fallback for older MATLAB versions
    try
        color = validatecolor(color);
    catch ME
        switch ME.identifier
            case 'MATLAB:UndefinedFunction'
                % validatecolor not available - attempt to do it manually
                switch color
                    case {"red", "r"}
                        color = [1 0 0];
                    case {"green", "g"}
                        color = [0 1 0];
                    case {"blue", "b"}
                        color = [0 0 1];
                    case {"cyan", "c"}
                        color = [0 1 1];
                    case {"magenta", "m"}
                        color = [1 0 1];
                    case {"yellow", "y"}
                        color = [1 1 0];
                    case {"black", "k"}
                        color = [0 0 0];
                    case {"white", "w"}
                        color = [1 1 1];
                    otherwise
                        error('MATLAB:graphics:validatecolor:InvalidColorString', 'Invalid color value');
                end
            otherwise
                rethrow(ME);
        end
    end
end
