classdef StateStack < handle
    properties
        UndoStack       (1, :) cell = {}
        RedoStack       (1, :) cell = {}
        MaxStackSize    (1, 1) double
    end
    methods
        function obj = StateStack(maxStackSize)
            arguments
                maxStackSize (1, 1) double {mustBeInteger, mustBePositive} = 20
            end
            obj.MaxStackSize = maxStackSize;
        end
        function SaveState(obj, currentState)
            % Save state to the undo stack, clearing the redo stack in the
            % process
            obj.AddToUndoStack(currentState);
            obj.RedoStack = {};
        end
        function Clear(obj)
            % Clear all stacks
            obj.UndoStack = {};
            obj.RedoStack = {};
        end
        function state = UndoState(obj, currentState)
            % Pop state off the undo stack and return, while also adding
            % currentState to the redo stack
            if isempty(obj.UndoStack)
                % Redo stack is empty, just return the current state
                state = currentState;
                return;
            end
            state = obj.RemoveFromUndoStack();
            obj.AddToRedoStack(currentState);
        end
        function state = RedoState(obj, currentState)
            % Pop state off the redo stack and return, while also adding
            % current state to the undo stack
            if isempty(obj.RedoStack)
                % Redo stack is empty, just return the current state
                state = currentState;
                return;
            end
            state = obj.RemoveFromRedoStack();
            obj.AddToUndoStack(currentState);
        end
    end
    methods (Access = private)
        function AddToUndoStack(obj, state)
            obj.UndoStack{end+1} = state;
            if length(obj.UndoStack) > obj.MaxStackSize
                obj.UndoStack(1) = [];
            end
        end
        function AddToRedoStack(obj, state)
            obj.RedoStack{end+1} = state;
            if length(obj.RedoStack) > obj.MaxStackSize
                obj.RedoStack(1) = [];
            end
        end
        function state = RemoveFromUndoStack(obj)
            if isempty(obj.UndoStack)
                err.identifier = 'MATLAB:StackEmpty';
                err.message = 'Cannot undo - undo stack empty';
                error(err);
            end
            state = obj.UndoStack{end};
            obj.UndoStack(end) = [];
        end
        function state = RemoveFromRedoStack(obj)
            state = obj.RedoStack{end};
            obj.RedoStack(end) = [];
        end
    end
end