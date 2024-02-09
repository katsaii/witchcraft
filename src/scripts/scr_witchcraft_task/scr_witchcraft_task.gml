//! A micro-library for handling async task management.

//# feather use syntax-errors

show_debug_message("enchanted with Witchcraft::task by @katsaii");

/// The completion state for a Witchcraft task.
enum WTaskState {
    IN_PROGRESS,
    COMPLETE,
    CANCELLED,
}

/// Stores information about a Witchcraft task, such as its name and callback.
function WTask() constructor {
    /// The name of this task. Defaults to `undefined`.
    ///
    /// @return {String}
    self.name = undefined;
    /// The completion state of this task.
    ///
    /// @return {Enum.WTaskState}
    self.state = WTaskState.IN_PROGRESS;
    /// The callback to invoke when this task is marked as complete. See
    /// `WTaskManager::createTask` for more information.
    ///
    /// @return {Function}
    self.onComplete = undefined;
    /// The `WTaskManager` this task originated from.
    ///
    /// @return {Struct.WTaskManager}
    self.manager = undefined;

    /// Marks this task as complete and invokes its callback.
    ///
    /// @return {Any} [result]
    ///   The result of the completion, can be anything.
    static complete = function (result = undefined) {
        if (state != WTaskState.IN_PROGRESS) {
            //"task '", task.name, "' completed after being cancelled"
            return;
        }
        state = WTaskState.COMPLETE;
        manager.tasksRemaining -= 1;
        var completionResult = undefined;
        if (onComplete != undefined) {
            completionResult = onComplete({
                task : task,
                result : result,
            });
        }
        manager.__checkTaskCompletion();
        return completionResult;
    };

    /// Cancels this task. Does not call the `onComplete` callback.
    static cancel = function () {
        if (state != WTaskState.IN_PROGRESS) {
            //"task '", task.name, "' completed after being cancelled"
            return;
        }
        state = WTaskState.CANCELLED;
        manager.tasksRemaining -= 1;
        manager.__checkTaskCompletion();
    };
}

/// Manages a database of Witchcraft tasks and their callbacks.
function WTaskManager() constructor {
    /// The number of remaining tasks being tracked by this task manager.
    ///
    /// @return {Real}
    self.tasksRemaining = 0;
    /// The number of total tasks registered to this task manager.
    ///
    /// @return {Real}
    self.totalTasks = 0;
    /// An array containing information about all tasks registered to this
    /// task manager.
    ///
    /// @return {Array<Struct>}
    self.taskList = [];
    /// The function to call when all tasks are completed. Respects new
    /// tasks being added during the completion of a final task.
    ///
    /// The manager itself will be passed as the sole argument to this
    /// hook.
    ///
    /// @return {Function}
    self.onTasksComplete = undefined;

    /// Creates a new task and registers it to this task manager.
    ///
    /// @param {String} name
    ///   The name of the task to register. This can be anything, or
    ///   `undefined` if the name doesn't matter.
    ///
    /// @param {Function} [onComplete]
    ///   An optional function to call when the task is completed. A
    ///   struct containing the following fields will be passed as the
    ///   sole argument to this function:
    ///
    ///     - `"task"`: data associated with the task itself.
    ///     - `"result"`: the result of the task upon completion.
    ///
    /// @return {Function}
    static createTask = function (name, onComplete = undefined) {
        var task = new WTask();
        task.name = name;
        task.onComplete = onComplete;
        task.manager = self;
        tasksRemaining += 1;
        totalTasks += 1;
        array_push(taskList, task);
        return task;
    };

    /// Clear all tasks in this task manager. Any unfinished tasks will be
    /// forgotten.
    static clearTasks = function () {
        var taskList_ = taskList;
        for (var i = array_length(taskList_) - 1; i >= 0; i -= 1) {
            // cancel all the tasks if they're still in progress
            var task = taskList_[i];
            if (task.state == WTaskState.IN_PROGRESS) {
                task.cancel();
            }
        }
    };

    /// Cleans up any resolved tasks from this task manager.
    static cleanTasks = function () {
        var taskList_ = taskList;
        for (var i = array_length(taskList_) - 1; i >= 0; i -= 1) {
            var task = taskList_[i];
            if (task.state != WTaskState.IN_PROGRESS) {
                array_delete(taskList_, i, 1);
                totalTasks -= 1;
            }
        }
    };

    /// @ignore
    static __checkTaskCompletion = function () {
        if (onTasksComplete != undefined && tasksRemaining < 1) {
            onTasksComplete(self);
        }
    };
}