This library lists the branches in a Git repository.  Then you can
operate on them with a dired-like interface.

The command `gited-list-branches' prompts for the kind of branch
(local branches, remote branches or tags) and lists them.
This command is used quite often, thus it might be convenient
to give it a key binding.  For instance, if `gited.el' is in
your `load-path', then you can bind it to `C-x C-g' in Dired buffers
by adding the following lines into your .emacs file:

(require 'gited)
(define-key dired-mode-map "\C-x\C-g" 'gited-list-branches)

If you are familiar with Dired, then you already know how to use
Gited; that's because most of the Gited commands with a Dired equivalent
share same keybindings.
For instance `gited-rename-branch' is bound to `R' as `dired-do-rename'.
Similarly, `gited-mark' is bound to `m' as `dired-mark'.

=== How to push to the remote repo. your local changes ===

Suppose you want to update a file 'foo' (*).
From the Gited buffer:
0) c master RET ;  Checkout master branch (**).
  *< ; Synchronize with remote repository.

  <<< Update 'foo' with your changes and save it. >>>

From the Gited buffer:
1) A ; Stage your changes.
2) C-c c "Updated foo" RET ; Commit them.
3) *> ; Public your changes into the remote repository.
---
(*) We have restricted to 1 file for simplicity.  The recipe works
    for N>=1 files.
(**) For changes that require several commits you might prefer to
     work in a separated branch 'feature'.  In that case you'd
     merge the master branch with 'feature' before 3).


Bugs/TODO
=========
* Currently, 'origin' is assumed as the remote repository:
  Remove some hardcode 'origin' around, and extend it
  to handle multiple remotes.
  
* Pull requests are not implemented.


 Internal variables defined here:

  `gited--hide-details-set', `gited--last-remote-prune',
  `gited--op', `gited--revert-commit',
  `gited--running-async-op', `gited-actual-switches',
  `gited-after-change-hook', `gited-async-operation-callback',
  `gited-author-face', `gited-author-idx',
  `gited-bisect-buf-name', `gited-bisect-buffer',
  `gited-bisect-buffer', `gited-bisect-output-name',
  `gited-branch-after-op', `gited-branch-alist',
  `gited-branch-idx', `gited-branch-name-face',
  `gited-buffer', `gited-buffer-name',
  `gited-commit-idx', `gited-commit-msg-face',
  `gited-current-branch', `gited-current-remote-rep',
  `gited-date-idx', `gited-date-regexp',
  `gited-date-time-face', `gited-del-char',
  `gited-deletion-branch-face', `gited-deletion-face',
  `gited-edit-commit-mode-map', `gited-flag-mark-face',
  `gited-flag-mark-line-face', `gited-header',
  `gited-list-format', `gited-list-refs-format-command',
  `gited-log-buffer', `gited-mark-col-size',
  `gited-mark-face', `gited-mark-idx',
  `gited-marker-char', `gited-mode',
  `gited-mode-map', `gited-modified-branch',
  `gited-new-or-deleted-files-re', `gited-op-string',
  `gited-original-buffer', `gited-output-buffer',
  `gited-output-buffer-name', `gited-re-mark',
  `gited-ref-kind', `gited-section-highlight-face',
  `gited-toplevel-dir', `gited-trunk-branch'.

 Coustom variables defined here:

  `gited-add-untracked-files', `gited-author-col-size',
  `gited-branch-col-size', `gited-commit-col-size',
  `gited-current-branch-face', `gited-date-col-size',
  `gited-date-format', `gited-delete-unmerged-branches',
  `gited-expert', `gited-one-trunk-repository',
  `gited-patch-options', `gited-patch-program',
  `gited-protected-branches', `gited-prune-remotes',
  `gited-reset-mode', `gited-short-log-cmd',
  `gited-show-commit-hash', `gited-switches',
  `gited-use-header-line', `gited-verbose'.

 Macros defined here:

  `gited-map-over-marks', `gited-mark-if',
  `gited-with-current-branch'.

 Commands defined here:

  `gited--mark-merged-branches-spec', `gited--mark-unmerged-branches-spec',
  `gited-add-patched-files', `gited-amend-commit',
  `gited-apply-add-and-commit-patch', `gited-apply-patch',
  `gited-async-operation', `gited-bisect',
  `gited-branch-clear', `gited-change-current-remote-rep',
  `gited-checkout-branch', `gited-commit',
  `gited-copy-branch', `gited-copy-branchname-as-kill',
  `gited-delete-all-stashes', `gited-delete-branch',
  `gited-diff', `gited-do-delete',
  `gited-do-flagged-delete', `gited-do-kill-lines',
  `gited-do-sync-with-trunk', `gited-edit-commit-mode',
  `gited-extract-patches', `gited-fetch-remote-tags',
  `gited-finish-commit-edit', `gited-flag-branch-deletion',
  `gited-goto-branch', `gited-goto-first-branch',
  `gited-goto-last-branch', `gited-kill-line',
  `gited-list', `gited-list-branches',
  `gited-log', `gited-log-last-n-commits',
  `gited-mark', `gited-mark-branches-by-date',
  `gited-mark-branches-containing-commit',
  `gited-mark-branches-containing-regexp', `gited-mark-branches-regexp',
  `gited-mark-local-tags', `gited-mark-merged-branches',
  `gited-mark-unmerged-branches', `gited-merge-branch',
  `gited-move-to-author', `gited-move-to-branchname',
  `gited-move-to-date', `gited-move-to-end-of-author',
  `gited-move-to-end-of-branchname', `gited-move-to-end-of-date',
  `gited-next-line', `gited-next-marked-branch',
  `gited-number-marked', `gited-origin',
  `gited-prev-line', `gited-prev-marked-branch',
  `gited-pull', `gited-push',
  `gited-remote-tag-delete', `gited-rename-branch',
  `gited-reset-branch', `gited-revert-commit',
  `gited-set-object-upstream', `gited-show-commit',
  `gited-stash', `gited-stash-apply',
  `gited-stash-branch', `gited-stash-drop',
  `gited-stash-pop', `gited-status',
  `gited-summary', `gited-sync-with-trunk',
  `gited-tag-add', `gited-tag-delete',
  `gited-toggle-current-remote-rep', `gited-toggle-marks',
  `gited-unmark', `gited-unmark-all-branches',
  `gited-unmark-all-marks', `gited-unmark-backward',
  `gited-update', `gited-visit-branch-sources',
  `gited-why'.

 Non-interactive functions defined here:

  `gited--advice-sort-by-column', `gited--bisect-after-run',
  `gited--bisect-executable-p', `gited--case-ref-kind',
  `gited--check-unmerged-marked-branches', `gited--clean-previous-patches',
  `gited--col-branch-name', `gited--extract-from-commit',
  `gited--fill-branch-alist', `gited--fontify-current-row',
  `gited--fontify-current-row-1', `gited--format-time',
  `gited--get-branch-info', `gited--get-branches-from-command',
  `gited--get-column', `gited--get-mark-for-entry',
  `gited--get-merged-branches', `gited--get-patch-or-commit-buffers',
  `gited--get-unmerged-branches', `gited--goto-column',
  `gited--goto-first-branch', `gited--handle-new-or-delete-files',
  `gited--last-commit-author', `gited--last-commit-date',
  `gited--last-commit-hash', `gited--last-commit-msg',
  `gited--last-commit-title', `gited--last-trunk-commit',
  `gited--list-files', `gited--list-format-init',
  `gited--list-refs-format', `gited--mark-branches-in-region',
  `gited--mark-merged-or-unmerged-branches',
  `gited--mark-merged-or-unmerged-branches-spec', `gited--merged-branch-p',
  `gited--move-to-column', `gited--move-to-end-of-column',
  `gited--output-buffer', `gited--patch-or-commit-buffer',
  `gited--set-output-buffer-mode', `gited--stash-branch',
  `gited--sync-with-trunk-target-name', `gited--update-header-line',
  `gited--update-padding', `gited--valid-ref-p',
  `gited-all-branches', `gited-async-operation-sentinel',
  `gited-at-header-line-p', `gited-bisecting-p',
  `gited-branch-exists-p', `gited-buffer-p',
  `gited-current-branch', `gited-current-branches-with-marks',
  `gited-current-state-list', `gited-dir-under-Git-control-p',
  `gited-edit-commit', `gited-fontify-current-branch',
  `gited-format-columns-of-files', `gited-get-branches',
  `gited-get-branchname', `gited-get-commit',
  `gited-get-date', `gited-get-element-in-row',
  `gited-get-last-commit-time', `gited-get-mark',
  `gited-get-marked-branches', `gited-git-checkout',
  `gited-git-command', `gited-git-command-on-region',
  `gited-hide-details-update-invisibility-spec',
  `gited-insert-marker-char', `gited-internal-do-deletions',
  `gited-listed-branches', `gited-log-msg',
  `gited-log-summary', `gited-map-lines',
  `gited-mark-pop-up', `gited-mark-remembered',
  `gited-modified-files', `gited-modified-files-p',
  `gited-next-branch', `gited-number-of-commits',
  `gited-plural-s', `gited-prev-branch',
  `gited-print-entry', `gited-remember-marks',
  `gited-remote-prune', `gited-remote-repository-p',
  `gited-remote-tags', `gited-repeat-over-lines',
  `gited-stashes', `gited-tabulated-list-entries',
  `gited-trunk-branch', `gited-trunk-branches',
  `gited-untracked-files'.

 Faces defined here:

  `gited-author', `gited-branch-name',
  `gited-commit-msg', `gited-date-time',
  `gited-deletion', `gited-deletion-branch',
  `gited-flag-mark', `gited-flag-mark-line',
  `gited-header', `gited-mark',
  `gited-modified-branch', `gited-section-highlight',
  `gited-status-branch-local', `gited-status-tag'.