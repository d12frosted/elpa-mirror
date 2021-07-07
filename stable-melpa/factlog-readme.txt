You need Python program factlog [1] to use this package.
factlog can be installed easily by "pip install factlog".
If you are using factlog.el from Git repository, you don't
need to install factlog separately.

To use factlog.el, simply add the following in your configuration:

  (require 'factlog)
  (factlog-mode)

You need helm.el or anything.el to access recently opened file list.

* List recently opened files:
  `helm-factlog-list' / `anything-factlog-list'
* List recently opened notes and choose them by title:
  `helm-factlog-list-notes' / `anything-factlog-list-notes'

[1] https://github.com/tkf/factlog
