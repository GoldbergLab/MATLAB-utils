function displayProgress(template, index, total, numUpdates)
% Show intermittent progress updates
% template: A sprintf formatting string containing two integer spots, one
%   for the current job index, one for the total number of jobs, in that 
%   order.
% index: The current job index
% total: The total number of jobs
% numUpdates: Approximate number of updates to show.

if mod(index, ceil(total/numUpdates)) == 0
    fprintf(template, index, total);
end