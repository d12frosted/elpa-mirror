                            ━━━━━━━━━━━━━━━
                             EMACS-FORGEJO
                            ━━━━━━━━━━━━━━━


Emacs front-end for [Forgejo] instances (Codeberg, self-hosted, etc.).

⁃ Browse, filter, and view issues and pull requests
⁃ Submit and merge PRs via [AGit-Flow] push options
⁃ Full code review workflow with threaded comments
⁃ Watch rules with per-repo filter polling and desktop notifications
⁃ Label, assignee, and milestone management
⁃ `SQLite' cache for instant display and offline usage
⁃ Multi-host support with per-instance token configuration
⁃ `#' and `@' completion in composition buffers (`gfm-mode')
⁃ Repository settings editor


[Forgejo] <https://forgejo.org>

[AGit-Flow] <https://forgejo.org/docs/latest/user/agit-support/>


1 Installation
══════════════

1.1 use-package
───────────────

  `emacs-forgejo' is available via [GNU ELPA].

  ┌────
  │ (use-package forgejo
  │   :ensure t
  │   :custom
  │   (forgejo-hosts '(("https://codeberg.org")))
  │   ;; Example watch rules
  │   (forgejo-watch-rules
  │    '(("thanosapollo/emacs-forgejo")
  │      ("guix/guix" . "state:open label:team-emacs")
  │      ("*" . "author:<your username>")))
  │   (forgejo-watch-filter-default "read:no"))
  └────

  Visit a codeberg/forgejo repo and call `M-x forgejo-vc'.  It will
  automatically handle the token creation.


[GNU ELPA] <https://elpa.gnu.org/packages/forgejo.html>


2 Usage
═══════

  From any git repository with a Forgejo remote, `C-x v f'
  (`forgejo-vc') opens the Forgejo popup menu.  All available commands
  are listed there.  Press `h' in any view to see keybindings.

  `M-x forgejo' opens the top-level menu for repo search, issue/PR
  browsing, and watch list.


2.1 Watch rules
───────────────

  Poll specific repos for new issues/PRs on a timer:

  ┌────
  │ (setq forgejo-watch-rules
  │       '("thanosapollo/emacs-forgejo" ;; all for thanosapollo/emacs-forgejo repo
  │         ("guix/guix" . "state:open label:team-emacs") ;; all state:open with team-emacs label
  │         ("*" . "author:<your-username>"))) ;; everything in the db with author:<your-username>
  │ (forgejo-watch-mode 1)
  └────

  A bare string watches everything in that repo.  A cons cell applies a
  filter query.  `*' expands to all repos in your local cache.

  `M-x forgejo-watch-list' to browse watched items.  The initial filter
  is controlled by `forgejo-watch-filter-default':

  ┌────
  │ (setq forgejo-watch-filter-default "read:no")
  └────

  Supported prefixes: `state:', `read:', `type:', `author:', `label:',
  `search:'.


2.2 Composition
───────────────

  Composition buffers use `gfm-mode' for markdown highlighting with `#'
  completion for issue/PR references and `@' for user mentions.

  ┌────
  │ (add-hook 'forgejo-compose-hook #'flyspell-mode)
  └────


2.3 Buffer setup
────────────────

  All Forgejo buffers call `forgejo-buffer-setup-functions' after setup,
  passing the buffer as an argument:

  ┌────
  │ (setq forgejo-buffer-setup-functions
  │       (list (lambda (buf)
  │               (with-current-buffer buf
  │                 (display-line-numbers-mode -1)))))
  └────


3 Comparison with other forgejo clients
═══════════════════════════════════════

3.1 fj.el
─────────

  • fj.el takes a direct-API approach while emacs-forgejo uses a local
    SQLite cache as source of truth.
  • fj.el supports the fork/PR workflow while emacs-forgejo supports
    AGit-Flow.


4 Contributing
══════════════

  This project is part of GNU ELPA.

  Contributions of ~15 lines or more require [FSF copyright assignment].

        See [#17] for more.


[FSF copyright assignment]
<https://www.gnu.org/prep/maintain/html_node/Copyright-Papers.html>

[#17] <https://codeberg.org/thanosapollo/emacs-forgejo/issues/17>


5 Screenshots
═════════════

  <https://thanosapollo.org/images/emacs-forgejo--issue-01.png>

  <https://thanosapollo.org/images/emacs-forgejo--issue.png>

  <https://thanosapollo.org/images/emacs-forgejo--review-comment.png>

  <https://thanosapollo.org/images/emacs-forgejo--review-log.png>

  <https://thanosapollo.org/images/emacs-forgejo--review-thread.png>
