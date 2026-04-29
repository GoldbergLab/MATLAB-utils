function n = grayDecode(g, nBits)
% grayDecode  Convert reflected binary Gray code back to a plain integer.
%
%   n = grayDecode(g)        decodes assuming values fit in 32 bits.
%   n = grayDecode(g, nBits) decodes assuming values fit in nBits bits.
%
% g may be a scalar or array of nonnegative integers. Output has the same
% shape and type as g.
%
% Inverse: grayEncode.

arguments
    g {mustBeNonnegative, mustBeInteger}
    nBits (1, 1) {mustBePositive, mustBeInteger} = 32
end

n = g;
shift = 1;
while shift < nBits
    n = bitxor(n, bitshift(n, -shift));
    shift = shift * 2;
end
