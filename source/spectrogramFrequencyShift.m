function S = spectrogramFrequencyShift(S, K)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% spectrogramFrequencyShift: 
% usage: S = spectrogramPhaseRandomizer(S)
%
% where,
%    S is the short time fourier transform (STFT) of a signal.
%
% Takes a STFT representation of a signal
%
% See also: <related functions>
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

S = circshift(S, K, 1);
size(S)
fillValue = 0;
S(1:K, :) = fillValue;