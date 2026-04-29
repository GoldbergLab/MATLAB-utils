function g = grayEncode(n, nBits)
% grayEncode  Convert nonnegative integer(s) to reflected binary Gray code.
%
%   g = grayEncode(n)        returns the Gray-code representation of n, such
%                            that successive integers differ in exactly one
%                            bit position.
%   g = grayEncode(n, nBits) additionally errors if any value of n does not
%                            fit in nBits bits. This is a safety check: a
%                            truncated Gray code is NOT cyclic, so silently
%                            overflowing would produce duplicate codes for
%                            different input values.
%
% n may be a scalar or array of nonnegative integers. Output has the same
% shape and type as n.
%
% Inverse: grayDecode.

arguments
    n {mustBeNonnegative, mustBeInteger}
    nBits {mustBeScalarOrEmpty, mustBeInteger, mustBePositive} = []
end

if ~isempty(nBits) && any(n(:) >= 2^nBits)
    error('grayEncode:Overflow', ...
        'Value %g does not fit in nBits=%d bits (max representable is %d).', ...
        max(n(:)), nBits, 2^nBits - 1);
end

g = bitxor(n, bitshift(n, -1));
