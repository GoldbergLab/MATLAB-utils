function s = pchiprot(x, y, xq)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% pchiprot: Apply a pchip interpolation sandwitched between rotations
% usage:  s = pchiprot(x, y, xq)
%         s = pchiprot(x, y, xq, angle)
%
% where,
%    x is a set of x values to fit
%    y is a set of y values to fit
%    xq is a set of query x points to interpolate at
%    angle is the angle to rotate/unrotate, in radians. Default = pi/4
%    s is the interpolated y values, corresponding to xq
%
% This is an elaboration of the pchip function that is robust to duplicate
%   x-values. If multiple fit points have the same x value, then the pchip
%   function fails with an error. By first rotating all the points, then
%   fitting the pchip, then unrotating, we can avoid that problem.
%
% See also: pchip, pchiprot
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Pick an angular nudge to produce a functional graph, and find rotated
% points
if any(diff(x) < 0)
    % Ordering must be reversed
    flipX = true;
    x = flip(x);
    y = flip(y);
    disp('hi');
else
    flipX = false;
end
[angle, xr, yr] = findFunctionalRotation(x, y);
if flipX
    xr = flip(xr);
    yr = flip(yr);
end

% Fit pchip to rotated points
ppr = pchip(xr, yr);

% Rotate query x-values using complex exponential
r = exp(-angle*1i) * (xq);
xqr = real(r);
yqr = imag(r);
xqr2 = zeros(size(xq));
opts.Display = 'notify';
for k = 1:length(xqr)
    xqfunc = @(x)yqr(k)+(x-xqr(k))*tan((pi/2)-angle) - ppval(ppr, x);
    xqr2(k) = fzero(xqfunc, xqr(k), opts);
end
sr = ppval(ppr, xqr2);
% Unrotate interpolated points
r = exp(angle*1i) .* (xqr2 + sr*1i);
s = imag(r);