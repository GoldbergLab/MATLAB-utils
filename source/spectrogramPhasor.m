function S = spectrogramPhasor(S)
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

newPhase = exp(1i*repmat(0:((2*pi)/(size(S, 2)-1)):2*pi, size(S, 1), 1));

S = S .* newPhase;