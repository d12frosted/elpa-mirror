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

Developed by Swarnim B (https://smarniw.com)
