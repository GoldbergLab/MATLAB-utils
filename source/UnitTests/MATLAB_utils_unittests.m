function MATLAB_utils_unittests(functionList)
arguments
    functionList = {}
end

if isempty(functionList)
    [~, functionList] = MATLAB_utils();
elseif ischar(functionList)
    functionList = {functionList};
end

for k = 1:length(functionList)
    functionName = functionList{k};
    fprintf('Testing function %s\n', functionName)
    switch functionName
        case 'findOnsetOffsetPairs'
            [a, b] = findOnsetOffsetPairs([false, false, false, false], [], false);
            assert(isempty(a))
            assert(isempty(b))
            [a, b] = findOnsetOffsetPairs([true, true, true, true, false, false, false, false], [], false);
            assert(isempty(a))
            assert(isempty(b))
            [a, b] = findOnsetOffsetPairs([true, true, true, true, false, false, false, false], [], true);
            assert(length(a) == 1)
            assert(a == 1)
            assert(length(b) == 1)
            assert(b == 4)
            [a, b] = findOnsetOffsetPairs([true, true, true, true, true], [], false);
            assert(isempty(a))
            assert(isempty(b))
            [a, b] = findOnsetOffsetPairs([true, true, true, true, true], [], true);
            assert(length(a) == 1)
            assert(a == 1)
            assert(length(b) == 1)
            assert(b == 5)
            [a, b] = findOnsetOffsetPairs([true, true, true, true, false, false, false, false, true, true, true, true], [], true);
            assert(length(a) == 2)
            assert(all(a == [1, 9]))
            assert(length(b) == 2)
            assert(all(b == [4, 12]))
            [a, b] = findOnsetOffsetPairs([true, true, true, true, false, false, false, false, true, true, true, true], [], false);
            assert(isempty(a))
            assert(isempty(b))
            [a, b] = findOnsetOffsetPairs([true, true, true, true, false, false, false, false, true, true, true, true, false, false, false, false], [], true);
            assert(length(a) == 2)
            assert(all(a == [1, 9]))
            assert(length(b) == 2)
            assert(all(b == [4, 12]))
            [a, b] = findOnsetOffsetPairs([true, true, true, true, false, false, false, false, true, true, true, true, false, false, false, false], [], false);
            assert(length(a) == 1)
            assert(a == 9)
            assert(length(b) == 1)
            assert(b == 12)
            [a, b] = findOnsetOffsetPairs([true, false, true, false, true, false]);
            assert(length(a) == 2)
            assert(all(a==[3, 5]))
            assert(length(b) == 2)
            assert(all(b==[3, 5]))
        otherwise
            warning('No unit tests exist for function %s', functionName)
    end
end

disp('All unit tests passed!')