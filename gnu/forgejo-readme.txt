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

      Requires Emacs 29.1+ (native JSON, native SQLite),
      `markdown-mode', and [keymap-popup].


[Forgejo] <https://forgejo.org>

[AGit-Flow] <https://forgejo.org/docs/latest/user/agit-support/>

[keymap-popup] <https://codeberg.org/thanosapollo/emacs-keymap-popup>


1 Installation
══════════════

1.1 use-package (Emacs 30+, recommended)
────────────────────────────────────────

  Install `keymap-popup' first:

  ┌────
  │ (use-package keymap-popup
  │   :vc (:url "https://codeberg.org/thanosapollo/emacs-keymap-popup"
  │           :branch "master"
  │           :rev :newest))
  └────

  Then install `forgejo':

  ┌────
  │ (use-package forgejo-vc
  │   :vc (:url "https://codeberg.org/thanosapollo/emacs-forgejo"
  │             :branch "master"
  │           :rev :newest
  │           :lisp-dir "lisp")
  │   :custom
  │   (forgejo-hosts '(("https://codeberg.org")))
  │   (forgejo-watch-rules '(("thanosapollo/emacs-forgejo")
  │                          ("guix/guix" . "state:open label:team-emacs")
  │                          ("*" . "author:<your username>")))
  │   (forgejo-watch-filter-default "read:no"))
  └────

  Store your token in `~/.authinfo.gpg':

  ┌────
  │ machine codeberg.org login YOUR_USERNAME password YOUR_TOKEN
  └────

  Or provide tokens inline:

  ┌────
  │ (setq forgejo-hosts '(("https://codeberg.org" "your-token")
  │                        ("https://git.myorg.com" "other-token")))
  └────


1.2 Manual
──────────

  Clone [keymap-popup] and add both to your load path:

  ┌────
  │ (add-to-list 'load-path "/path/to/emacs-keymap-popup")
  │ (add-to-list 'load-path "/path/to/emacs-forgejo/lisp")
  │ (require 'forgejo-vc)
  └────


[keymap-popup] <https://codeberg.org/thanosapollo/emacs-keymap-popup>


1.3 Guix
────────

  ┌────
  │ guix package -f guix.scm
  └────


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
  │       '("thanosapollo/forgejo.el"
  │         ("guix/guix" . "state:open label:team-emacs")
  │         ("*" . "author:thanosapollo")))
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


3 Screenshots
═════════════

  <https://thanosapollo.org/images/emacs-forgejo--issue-01.png>

  <https://thanosapollo.org/images/emacs-forgejo--issue.png>

  <https://thanosapollo.org/images/emacs-forgejo--review-comment.png>

  <https://thanosapollo.org/images/emacs-forgejo--review-log.png>

  <https://thanosapollo.org/images/emacs-forgejo--review-thread.png>
