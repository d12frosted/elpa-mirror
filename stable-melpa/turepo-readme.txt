turepo provides a simple command to open the current project's
git repository in your web browser.  It supports:
- GitHub
- GitLab
- Codeberg
- SourceHut
- Gitea
Both ssh based and http based git projects are supported

Usage:

Via use-package:
(use-package turepo
  :ensure t
  :bind (("C-c g r" . turepo)))

Or directly via the `turepo` function provided by the package.

Configuration:

turepo-debug-mode (default: nil)
  When enabled, displays debug messages showing the execution flow,
  including git repository location, config file path, matched URL
  pattern, and the URL being opened.  When disabled (default), turepo
  operates silently on success and only displays error messages.

  Enable debug mode:
  (setq turepo-debug-mode t)

  Or via use-package:
  (use-package turepo
    :custom
    (turepo-debug-mode t))

Developed by Swarnim B (https://smarniw.com)
