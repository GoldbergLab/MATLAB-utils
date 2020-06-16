function vnames = getVarNames(varargin)
vnames = {};
k = 1;
while true
    try
        vnames{k} = inputname(k);
    catch ME
        break;
    end
    k = k + 1;
end