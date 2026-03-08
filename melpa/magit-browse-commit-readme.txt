This package provides functionality to browse GitHub pull requests or
GitLab merge requests directly from magit-blame mode.  When invoked on
a blamed line, it will attempt to find the merge commit that introduced
the change and open the corresponding PR/MR in your browser.

Usage:
  M-x magit-browse-commit-at-point

Or bind it to a key:
  (with-eval-after-load 'magit-blame
    (define-key magit-blame-mode-map (kbd "M-o") #'magit-browse-commit-at-point))
