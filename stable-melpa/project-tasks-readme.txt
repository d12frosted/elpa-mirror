`project-tasks` provides efficient task management for your project.
It allows you to organize and manage your project's tasks in an
Org file. You can quickly jump to the task file, capture new tasks
and easily run tasks by name.

The main idea is to use Org source blocks as tasks. Each source
block is a task and its name is the task name. You can use
`project-tasks` to quickly run a task by name.

Example:
If we want to have a fast way to run `top` command in our project,
we can add a source block named `Run top` to `tasks.org` file:
#+name: Run top
#+begin_src elisp :results none
(comint-run "top")
#+end_src

Then we just need to run `M-x project-tasks` to select and run the task.
