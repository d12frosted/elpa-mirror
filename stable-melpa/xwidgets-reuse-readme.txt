Xwidget sessions are relatively heavy-weight. This packages allows a single
xwidgets session to be reused for browsing. This can be useful for tasks like
viewing html email in xwidgets or elfeed feeds or dash documentation. To
customize behavior, you can register minor modes with `xwidgets-reuse' that
bind custom keys. Call `xwidgets-reuse-register-minor-mode' to register your
minor mode. Use `xwidgets-reuse-xwidget-reuse-browse-url(url &optional
use-minor-mode)' to browse `url' reusing an xwidget session. This turns off
all minor modes registered with `xwidgets-reuse' in the reused xwidgets
session. If `use-minor-mode' is provided, then this minor mode is turned on
in the xwidgets session. Furthermore, this package allows the creation and
management of named sessions. A named session is a session that once created,
can be accessed and reused by its name. xwidgets-reuse also supports
automatic cleanup of named sessions to save resources. It runs a timer and
automatically closes sessions that are registered for cleanup if they are
currently not shown in a visible window.
