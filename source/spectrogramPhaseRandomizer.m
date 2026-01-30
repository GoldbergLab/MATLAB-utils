function S = spectrogramPhaseRandomizer(S)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% spectrogramPhaseRandomizer: Randomize the phase of a spectrogram
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

newPhase = exp(1i*rand(size(S)));
% 
% % Zero frequency component has to have all zero phase, or reconstructed signal will be complex
% newPhase(end, :) = 1;

S = S .* newPhase;