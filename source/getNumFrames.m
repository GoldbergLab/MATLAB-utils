function numFrames = getNumFrames(videoFileName)

% Relies on ffprobe command (part of ffmpeg package) being present in the
%   system.

command = sprintf('ffprobe -v error -select_streams v:0 -show_entries stream=nb_frames -of default=nokey=1:noprint_wrappers=1 "%s"', videoFileName);
[status, stdout] = system(command);
numFrames = str2double(stdout);