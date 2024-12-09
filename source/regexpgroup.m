function [groupNames, groupValues, groupIdx] = regexpgroup(strings, regex)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% regexpgroup: group a cell array of strings based on regex tokens
% usage: [groupNames, groupElements] = regexpgroup(strings, regex)
%
% where,
%    strings is a cell array of char arrays to group
%    regex is a regular expression with one capturing group
%    groupNames is a cell array of the unique tokens found in strings
%    groupValues is a cell array of cell arrays, each element of which
%       corresponds to the elements of strings that contained the token in
%       corresponding element of groupNames
%    groupIdx is a cell array of indices for each group, such that
%       groupValues(k) is the same as strings(groupIdx{k})
%
% This function takes an array of strings and groups them by the token 
%   matched by the given regular expression. For example, 
%       groups = regexpgroup({'aaa', 'aab', 'bba', 'bbb'}, '(bb)') 
%   would yield
%       groupNames => {'', 'bb'}
%       groupElements => {{'aaa', 'aab'}, {'bba', 'bbb'}}
%
% See also: regexpfilter, regexpmatch
%
% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Find tokens in each string
    capturedTokens = regexp(strings, regex, 'tokens');
    
    % Flatten token array
    capturedTokens = cellfun(@flattenToken, capturedTokens, 'UniformOutput', false);
    % Find unique list of tokens
    groupNames = unique(capturedTokens);
    % Initialize group values array
    groupValues = cell(size(groupNames));
    groupIdx = cell(size(groupNames));
    for k = 1:length(groupNames)
        % For each value, categorize it into a subgroup based on which token it contains
        mask = strcmp(capturedTokens, groupNames{k});
        groupValues{k} = strings(mask);
        groupIdx{k} = find(mask);
    end
end

function token = flattenToken(token)
    while iscell(token)
        if isempty(token)
            token = '';
        else
            token = token{1};
        end
    end
end