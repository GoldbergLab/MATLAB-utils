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
            [onsets, offsets, startPulse, endPulse] = findOnsetOffsetPairs([false, false, false, false], [], false);
            assert(isempty(onsets))
            assert(isempty(offsets))
            assert(~endPulse)
            assert(~startPulse)
            [onsets, offsets, startPulse, endPulse] = findOnsetOffsetPairs([true, true, true, true, false, false, false, false], [], false);
            assert(isempty(onsets))
            assert(isempty(offsets))
            assert(~endPulse)
            assert(startPulse)
            [onsets, offsets, startPulse, endPulse] = findOnsetOffsetPairs([true, true, true, true, false, false, false, false], [], true);
            assert(length(onsets) == 1)
            assert(onsets == 1)
            assert(length(offsets) == 1)
            assert(offsets == 4)
            assert(~endPulse)
            assert(startPulse)
            [onsets, offsets, startPulse, endPulse] = findOnsetOffsetPairs([true, true, true, true, true], [], false);
            assert(isempty(onsets))
            assert(isempty(offsets))
            assert(endPulse)
            assert(startPulse)
            [onsets, offsets, startPulse, endPulse] = findOnsetOffsetPairs([true, true, true, true, true], [], true);
            assert(length(onsets) == 1)
            assert(onsets == 1)
            assert(length(offsets) == 1)
            assert(offsets == 5)
            assert(endPulse)
            assert(startPulse)
            [onsets, offsets, startPulse, endPulse] = findOnsetOffsetPairs([true, true, true, true, false, false, false, false, true, true, true, true], [], true);
            assert(length(onsets) == 2)
            assert(all(onsets == [1, 9]))
            assert(length(offsets) == 2)
            assert(all(offsets == [4, 12]))
            assert(endPulse)
            assert(startPulse)
            [onsets, offsets, startPulse, endPulse] = findOnsetOffsetPairs([true, true, true, true, false, false, false, false, true, true, true, true], [], false);
            assert(isempty(onsets))
            assert(isempty(offsets))
            assert(endPulse)
            assert(startPulse)
            [onsets, offsets, startPulse, endPulse] = findOnsetOffsetPairs([true, true, true, true, false, false, false, false, true, true, true, true, false, false, false, false], [], true);
            assert(length(onsets) == 2)
            assert(all(onsets == [1, 9]))
            assert(length(offsets) == 2)
            assert(all(offsets == [4, 12]))
            assert(~endPulse)
            assert(startPulse)
            [onsets, offsets, startPulse, endPulse] = findOnsetOffsetPairs([true, true, true, true, false, false, false, false, true, true, true, true, false, false, false, false], [], false);
            assert(length(onsets) == 1)
            assert(onsets == 9)
            assert(length(offsets) == 1)
            assert(offsets == 12)
            assert(~endPulse)
            assert(startPulse)
            [onsets, offsets, startPulse, endPulse] = findOnsetOffsetPairs([true, false, true, false, true, false]);
            assert(length(onsets) == 2)
            assert(all(onsets==[3, 5]))
            assert(length(offsets) == 2)
            assert(all(offsets==[3, 5]))
            assert(~endPulse)
            assert(startPulse)
            [onsets, offsets, startPulse, endPulse] = findOnsetOffsetPairs([true, false, true, false, true, false]');
            assert(length(onsets) == 2)
            assert(all(onsets==[3, 5]))
            assert(length(offsets) == 2)
            assert(all(offsets==[3, 5]))
            assert(~endPulse)
            assert(startPulse)
        otherwise
            warning('No unit tests exist for function %s', functionName)
    end
end

disp('All unit tests passed!')