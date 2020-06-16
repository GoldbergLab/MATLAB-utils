function idx = rndIdx(nOnes, nTotal, seed)
idx = zeros([1, nTotal], 'logical');
if exist('seed', 'var')
    if isnan(seed)
        seed = sum(clock()*1000);
    end
    rng(seed);
else
    seed = NaN;
end
onesIdx = randsample(nTotal, nOnes);
idx(onesIdx) = 1;
disp(['rndIdx(', num2str(nOnes), ', ', num2str(nTotal), ', ', num2str(seed), ')'])
disp(idx);