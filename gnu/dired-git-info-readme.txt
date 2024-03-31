<a href="<https://elpa.gnu.org/packages/dired-git-info.html>"><img
alt="GNU ELPA" src="<https://elpa.gnu.org/favicon.png"/>></a>


1 Description
═════════════

  This Emacs packages provides a minor mode which shows git information
  inside the dired buffer:

  <./images/screenshot2.png>


2 Installation
══════════════

2.1 GNU ELPA
────────────

  This package is available on [GNU ELPA]. You can install it via `M-x
  package-install RET dired-git-info RET'


[GNU ELPA] <https://elpa.gnu.org>


2.2 Manual
──────────

  For manual installation, clone the repository and call:

  ┌────
  │ (package-install-file "/path/to/dired-git-info.el")
  └────


3 Config
════════

3.1 Bind the minor mode command in dired
────────────────────────────────────────

  ┌────
  │ (with-eval-after-load 'dired
  │   (define-key dired-mode-map ")" 'dired-git-info-mode))
  └────


3.2 Don't hide normal Dired file info
─────────────────────────────────────

  By default, toggling `dired-git-info-mode' also toggles the built-in
  `dired-hide-details-mode', which hides file details such as ownership,
  permissions and size. This behaviour can be disabled by overriding
  `dgi-auto-hide-details-p':

  ┌────
  │ (setq dgi-auto-hide-details-p nil)
  └────


3.3 Enable automatically in every Dired buffer (if in Git repository)
─────────────────────────────────────────────────────────────────────

  To enable `dired-git-info-mode' whenever you navigate to a Git
  repository, use the following (if you want to use this you have to
  install from source as long this change is not picked up by ELPA):
  ┌────
  │ (add-hook 'dired-after-readin-hook 'dired-git-info-auto-enable)
  └────
