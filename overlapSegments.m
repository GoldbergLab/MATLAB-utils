function [oA, oB] = overlapSegments(sA, sB, rA, rB, roundOutputs)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% mapDataStreams: Map a range of samples in one data stream to a
%   corresponding range of samples in another data stream.
% usage:  matchRanges = mapDataStreams(syncList, baseFile, baseIndexRange, 
%                                      streamIndex)
%
% where,
%   sA is a segment to overlap in coordinate system A
%   sB is a segment to overlap in coordinate system B
%   rA is an optional reference segment in coordinate system A which maps 
%       to rB. Default is [0, 1].
%   rB is an optioanl reference segment in coordinate system B which maps 
%       to rA. Default is [0, 1].
%   oA is a sub-segment of segment A that overlaps with segment B
%   oB is a sub-segment of segment B that overlaps with segment A
%   roundOutputs is an optioanl boolean flag indicating whether or not to 
%       round outputs coordinates to integers. Default is true.
%
% overlapSegments finds the overlap between two 1-D segments. If the two
%   segments are in coordinates from disparate coordinate systems, the
%   overlap can be found by providing two reference segments that map to
%   each other in the two coordinate systems.
%
% See also: syncTagStreams
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('roundOutputs', 'var')
    roundOutputs = true;
end

if ~exist('rA', 'var')
    rA = [0, 1];
end
if ~exist('rB', 'var')
    rB = [0, 1];
end

% Check validity of inputs
for segC = {rA, rB, sA, sB}
    seg = segC{1};
    assert(length(seg) == 2, 'Error, all inputs to overlapSegments must have length 2');
    assert(seg(1) <= seg(2), 'Error, all inputs to overlapSegments must have second value greater than the first');
end

% Scale conversion between coordinate system B and A
slopeBtoA = (rA(1) - rA(2))/(rB(1) - rB(2));
slopeAtoB = (rB(1) - rB(2))/(rA(1) - rA(2));

% Function to map numbers in coordinate system B to coordinate system A
mapBtoA = @(nB)slopeBtoA*(nB - rB(1)) + rA(1);
mapAtoB = @(nA)slopeAtoB*(nA - rA(1)) + rB(1);

% Segment B mapped to A coordinate system - "sB in A"
sBinA = mapBtoA(sB);

if sA(2) < sBinA(1) || sBinA(2) < sA(1)
    % |---A---| 
    %             |---B---|
    %          OR
    %             |---A---| 
    %  |---B---|
    oA = [];
elseif sA(1) <= sBinA(1) && sA(2) <= sBinA(2)
    % |---A---| 
    %       |---B---|
    oA = [sBinA(1), sA(2)];
elseif sBinA(1) <= sA(1) && sBinA(2) <= sA(2)
    %       |---A---| 
    %  |---B---|
    oA = [sA(1), sBinA(2)];
elseif sA(1) >= sBinA(1) && sA(2) <= sBinA(2)
    %     |---A---| 
    %   |-----B-----|
    oA = sA;
elseif sBinA(1) >= sA(1) && sBinA(2) <= sA(2)
    %   |-----A-----| 
    %     |---B---|
    oA = sBinA;
else
    error('Failed to identify segment overlap!');
end

oB = mapAtoB(oA);

if roundOutputs
    oA = round(oA);
    oB = round(oB);
end