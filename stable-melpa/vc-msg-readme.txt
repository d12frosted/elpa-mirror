
This package is an extended and actively maintained version of the
package emacs-git-messenger.

Run "M-x vc-msg-show" and follow the hint.

The Version Control Software (VCS) is detected automatically.

Set up to force the VCS type (Perforce, for example),
  (setq vc-msg-force-vcs "p4")

You can add hook to `vc-msg-hook',
  (defun vc-msg-hook-setup (vcs-type commit-info)
    ;; copy commit id to clipboard
    (message (format "%s\n%s\n%s\n%s"
                     (plist-get commit-info :id)
                     (plist-get commit-info :author)
                     (plist-get commit-info :author-time)
                     (plist-get commit-info :author-summary))))
  (add-hook 'vc-msg-hook 'vc-msg-hook-setup)

Hook `vc-msg-show-code-hook' is hook after code of certain commit
is displayed.  Here is sample code:
  (defun vc-msg-show-code-setup ()
    ;; use `ffip-diff-mode' from package find-file-in-project instead of `diff-mode'
    (ffip-diff-mode))
  (add-hook 'vc-msg-show-code-hook 'vc-msg-show-code-setup)

Git users could set `vc-msg-git-show-commit-function' to show the code of commit,

  (setq vc-msg-git-show-commit-function 'magit-show-commit)

If `vc-msg-git-show-commit-function' is executed, `vc-msg-show-code-hook' is ignored.

Perforce is detected automatically.  You don't need any manual setup.
But if you use Windows version of perforce CLI in Cygwin Emacs, we
provide the variable `vc-msg-p4-file-to-url' to convert file path to
ULR so Emacs and Perforce CLI could communicate the file location
correctly:
  (setq vc-msg-p4-file-to-url '(".*/proj1" "//depot/development/proj1"))

The program provides a plugin framework so you can easily write a
plugin to support any alien VCS.  Please use "vc-msg-git.el" as a sample.

Sample configuration to integrate with Magit (https://magit.vc/),

(eval-after-load 'vc-msg-git
  '(progn
     ;; show code of commit
     (setq vc-msg-git-show-commit-function 'magit-show-commit)
     ;; open file of certain revision
     (push '("m"
             "[m]agit-find-file"
             (lambda ()
               (let* ((info vc-msg-previous-commit-info)
                      (git-dir (locate-dominating-file default-directory ".git")))
                 (magit-find-file (plist-get info :id )
                                  (concat git-dir (plist-get info :filename))))))
           vc-msg-git-extra)))
