function displayProgress(template, index, total, numUpdates)
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

if ~exist('numUpdates', 'var') || isempty(numUpdates)
    numUpdates = total;
end

if mod(index, ceil(total/numUpdates)) == 0
    fprintf(template, index, total);
end