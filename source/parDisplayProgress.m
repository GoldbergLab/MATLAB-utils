classdef parDisplayProgress < parallel.pool.DataQueue
    properties
        TaskTotals
        TaskNames
    end
    methods
        function obj = parDisplayProgress(taskNames, taskTotals, varargin)
            obj@parallel.pool.DataQueue(varargin{:})
            obj.TaskNames = taskNames;
            obj.TaskTotals = taskTotals;
            obj.afterEach(@obj.displayProgress);
        end
        function displayProgress(obj, data)
            name = data{1};
            count = data{2};
            idx = find(strcmp(name, obj.TaskNames));
            name = obj.TaskNames{idx};
            total = obj.TaskTotals(idx);
            fprintf('%s is %0.01f%% done\n', name, 100*count / total);
        end
        function send(obj, name, count)
            send@parallel.pool.DataQueue(obj, {name, count});
        end
    end
end
