function abc = alphabet(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% alphabet: generate a common set of symbols
% usage: abc = alphabet(tokenType1, tokenType2, ..., tokenTypeN)
%
% where,
%    tokenType1...N is one or more token types from the following list:
%       {'letters', 'LETTERS', 'numbers', 'symbols', 'varname', 'all'}
%    abc is a unique list of all the tokens requested
%
% See also:
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
arguments (Repeating)
    varargin {mustBeMember(varargin, {'letters', 'LETTERS', 'numbers', 'symbols', 'varname', 'all'})}
end

tokens.letters = 'abcdefghijklmnopqrstuvwxyz';
tokens.LETTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
tokens.numbers = '0123456789';
tokens.varname = [tokens.letters, tokens.LETTERS, tokens.numbers, '_'];
tokens.symbols = '`~!@#$%^&*()-=_+\|[]{};'':",./<>?';
allTokens = struct2cell(tokens);
tokens.all = {allTokens{:}};
abc = cell(1, nargin);
for k = 1:nargin
    if ~isfield(tokens, varargin{k})
        error('Invalid token type: %s', varargin{k});
    end
    abc{k} = tokens.(varargin{k});
end
abc = unique([abc{:}], 'stable');