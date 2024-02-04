function tests = safeSliceTest
tests = functiontests(localfunctions);
end

function test1DLeftOutOfBounds(testCase)
actualSolution = safeSlice(1:10, -4:4);
expectedSolution = 1:4;
verifyEqual(testCase, actualSolution, expectedSolution);
end

function test1DRightOutOfBounds(testCase)
actualSolution = safeSlice(1:10, 5:15);
expectedSolution = 5:10;
verifyEqual(testCase, actualSolution, expectedSolution);
end

function test1DBothOutOfBounds(testCase)
actualSolution = safeSlice(1:10, -5:15);
expectedSolution = 1:10;
verifyEqual(testCase, actualSolution, expectedSolution);
end

function testND(testCase)
x = reshape(1:120, 5, 6, 4);
actualSolution = safeSlice(x, -2:3, 4:100, -5:20);
expectedSolution = x(1:3, 4:6, 1:4);
verifyEqual(testCase, actualSolution, expectedSolution);
end