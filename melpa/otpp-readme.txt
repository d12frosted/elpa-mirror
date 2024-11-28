This is a lightweight workspace management package that provides a thin layer
between builtin packages `project' and `tab-bar'. The whole idea consists of
creating a _tab per opened project_ while ensuring unique names for the
created tabs (when multiple opened projects have the same name).

This package is inspired by `project-tab-groups' which creates a "tab group"
per project.

; Installation

This package is available on MELPA.

```emacs-lisp
(use-package otpp
  :straight t
  :after project
  :init
  ;; If you like to define some aliases for better user experience
  (defalias 'one-tab-per-project-mode 'otpp-mode)
  (defalias 'one-tab-per-project-override-mode 'otpp-override-mode)
  ;; Enable `otpp-mode' globally
  (otpp-mode 1)
  ;; If you want to advice the commands in `otpp-override-commands'
  ;; to be run in the current's tab (so, current project's) root directory
  (otpp-override-mode 1))
```

; Basic usage

The usage is quite straightforward, there is no extra commands to learn to be
able to use it. When `otpp-mode' global minor mode is enabled, you will have
this:

- When you switch to a project `project-switch-project' (bound by default to
  `C-x p p`), `otpp' will create a tab with the project name.

- When you kill a project with all its buffers with `project-kill-buffers', the
  tab is closed.

- Lets say you've switched to the project under
  `/home/user/project1/backend/', `otpp' will create a tab named `backend'
  for this particular project. Now, you opened a second project under
  `/home/user/project2/backend/', `otpp' will detect that the name of the
  project `backend' is the same as the previously opened one, but it have a
  different path. In this case, `otpp' will create a tab named
  `backend[project2]` and renames the previously opened tab to
  `backend[project1]`. This conflict resolution is provided by the
  `otpp-uniq' library.

- For some cases, you might need to attach a manually created tab (by
  `tab-bar-new-tab') to an opened project so you have two tabs dedicated to
  the same project (with different windows layouts for example). In this
  case, you can call the command `otpp-change-tab-root-dir' and select the
  path of the project to attach to.

- When you use some commands to jump to a file (`find-file',
  `xref-find-definitions', etc.), you can end up with a buffer belonging to a
  _different project (lets say `B')_ but displayed in the current project's
  tab _(`A')_. In this case, you can call `otpp-detach-buffer-to-tab' to
  create a new tab dedicated to the buffer's project `B'. When the opened
  buffer is project-less (not part of a project), the command will signal a
  user error unless `otpp-allow-detach-projectless-buffer' is non-nil, in
  this case, `otpp' creates a new project-less tab for the buffer.

; Advanced usage

Consider this use case: supposing you are using `otpp-mode' and you've run
`project-switch-project' to open the `X' project in a new `X' tab. Now you
`M-x find-file` then you open the `test.cpp` file outside the current `X'
project. Now, if you run `project-find-file', you will be in one of these two
situations:

1. If `test.cpp` is part of another project `Y', the `project-find-file' will
   prompt you with a list of `Y's files even though we are in the `X' tab.

2. If `test.cpp` isn't part of any project, `project-find-file' will prompt
you to select a project first, then to select a file.

For this, `otpp' provides `otpp-prefix' (we recommend to bind it to some key,
like `C-x t P`, using `otpp-prefix' from `M-x' can have some limitations).
When you run `otpp-prefix' followed by `C-x p f` for example, you will be
prompted for files in the current's tab project files even if you are
visiting a file outside of the current project.

In my workflow, I would like to always restrict the commands like
`project-find-file' and `project-kill-buffers' to the project bound to the
current tab, even if I'm visiting a file which is not part of this project.
If you like this behavior, you can enable the `otpp-override-mode'. This mode
will advice all the commands defined in `otpp-override-commands' to be ran in
the current's tab root directory (_a.k.a._, in the project bound to the
current tab).

When `otpp-override-mode' is enabled, the `otpp-prefix' acts inversely. While
all `otpp-override-commands' are restricted to the current's tab project by
default, running a command with `otpp-prefix' will disable this behavior,
which results of the next command to be run in the `default-directory'
depending on the visited buffer.

; Similar packages

This section is not exhaustive, it includes only the packages that I used
before.

- [`project-tab-groups'](https://github.com/fritzgrabo/project-tab-groups):
  This package provides a mode that enhances the Emacs built-in `project' to
  support keeping projects isolated in named tab groups. `otpp' is inspired
  by this package, but instead of setting the tab groups, `otpp' introduces a
  new attribute in the tab named `otpp-root-dir' where it stores the root
  directory of the project bound to the tab. This allows keeping the tabs
  updated in case another project with the same name (but a different path)
  is opened.

- [`tabspaces'](https://github.com/mclear-tools/tabspaces): This package
  provide workspace management with `tab-bar' and with an integration with
  `project'. Contrary to `otpp' and `project-tab-groups', `tabspaces' don't
  create tabs automatically, you need to call specific commands like
  `tabspaces-open-or-create-project-and-workspace'. Also, `tabspaces'
  behavior isn't predictable when you open several projects with the same
  directory name.
