This aims to be a complete package for dotnet tasks that aren't part
of the languages but needed for any project: Solution management, nuget, etc.

Steps to setup:
  1. Place sharper.el in your load-path.  Or install from MELPA.
  2. Add a binding to start sharper's transient:
      (require 'sharper)
      (global-set-key (kbd "C-c n") 'sharper-main-transient) ;; For "n" for "dot NET"

Some commands show lists of items.  In those cases, "RET" shows the transient with the Actions
available.

For a detailed user manual see:
https://github.com/sebasmonia/sharper/blob/master/README.md
