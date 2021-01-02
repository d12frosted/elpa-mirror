
Make everything use the same mechanism to open files.  Currently, `dired` has
its mechanism, `org-mode` uses something different (the `org-file-apps`
variable), and `mu4e` something else (a simple prompt).  This package makes
sure that each package uses the mechanism of `dired`.  I advise you to
install the [`runner`](https://github.com/thamer/runner) package to improve
the `dired` mechanism.
