This file provides methods that quickly get you to your destination inside
your current project, leveraging the power of git if you are using it to
store your code.

A project is defined as a directory which meets one of these conditions in
the following order:

- The presence of a `.dir-locals.el' file (emacs23 style) or a
  `.emacs-project' file (`project-local-variables' style).
- The git repository that the current buffer is in.
- The mercurial repository the current buffer is in.
- The project root defined in `project-root.el', a library not included with
  GNU Emacs.
- The current default-directory if none of the above is found.

When we're in a git repository, we use git-ls-files and git-grep to speed up
our searching. Otherwise, we fallback on find statements. As a special
optimization, we prune ".svn" and ".hg" directories whenever we find.

ftf provides three main user functions:

- `ftf-find-file' which does a filename search. It has been tested on large
  projects; it takes slightly less than a second from command invocation to
  prompt on the Chromium source tree 9,183 files as of the time of
  this writing).

  It uses git-ls-files for speed when available (such as the Chromium tree),
  and falls back on a find statement at the project root/default-directory
  when git is unavailable.

- `ftf-grepsource' which greps all the files for the escaped pattern passed
  in at the prompt.

  It uses git-grep for speed when available (such as the Chromium tree),
  and falls back on a find|xargs grep statement when not.

- The `with-ftf-project-root' macro, which locally changes
  `default-directory' to what find-things-fast thinks is the project
  root. Two trivial example functions, `ftf-gdb' and `ftf-compile' are
  provided which show it off.

By default, it looks only for files whose names match `ftf-filetypes'. The
defaults were chosen specifically for C++/Chromium development, but people
will probably want to override this so we provide a helper function you can
use in your mode hook, `ftf-add-filetypes'. Example:

(add-hook 'emacs-lisp-mode-hook
          (lambda () (ftf-add-filetypes '("*.el" "*.elisp"))))

If `ido-mode' is enabled, the menu will use `ido-completing-read'
instead of `completing-read'.

This file was based on the `find-file-in-project.el' by Phil Hagelberg and
Doug Alcorn which can be found on the EmacsWiki. Obviously, the scope has
greatly expanded.

Recommended binding:
(global-set-key (kbd [f1]) 'ftf-find-file)
(global-set-key (kbd [f2]) 'ftf-grepsource)
(global-set-key (kbd [f4]) 'ftf-gdb)
(global-set-key (kbd [f5]) 'ftf-compile)
