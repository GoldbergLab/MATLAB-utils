function displayProgress(template, index, total, numUpdates, gui)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% displayProgress: Show intermittent progress updates
% usage:  displayProgress(template, index, total, numUpdates)
%         displayProgress(template, index, total)
%
% where,
%    template is a sprintf formatting string containing two integer spots,
%       one for the current job index, one for the total number of jobs, in
%       that order.
%    index is the current job index
%    numUpdates is the approximate number of update to show. If omitted or
%       empty, an update will be displayed for every call; in that case
%       displayProgress is equivalent to fprintf.
%    gui is an optional boolean flag indicating whether or not to display a
%       modal progress bar in addition to the command window output.
%       Default is false.
%
% A common repetitive problem is displaying intermittent progress updates
%   for a long-running process without excessive output. This is a quick
%   way to show custom updates at reasonable intervals.
%
% See also: fprintf
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments
    template char
    index (1, 1) double
    total (1, 1) double
    numUpdates double = 20
    gui (1, 1) logical = false
end

persistent progressBar

if isempty(template)
    % Use default template
    template = 'Done with %d of %d\n';
end
if isempty(numUpdates)
    % Default is one update for every call
    numUpdates = total;
end

if gui
    progressBar = waitbar(0, '', 'WindowStyle', 'modal');
end

if mod(index, ceil(total/numUpdates)) == 0
    msg = sprintf(template, index, total);
    if gui
        waitbar(index/total, progressBar, msg);
    else
        fprintf(msg);
    end
end

if index == total
    close(progressBar);
end