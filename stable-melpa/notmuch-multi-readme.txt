
This package extends the Notmuch Emacs UI to handle multiple mail
accounts cleanly.  Stock Notmuch shows all saved searches in a flat
list; notmuch-multi groups them by account on the hello screen,
adds an unread/total count display, and scopes `notmuch-jump' key
bindings per account.  It also provides a soft-delete/expire
tagging workflow and prettier subject formatting for search and tree
views.

SETUP

1. Declare your accounts and per-account searches via the
   `notmuch-multi-accounts-saved-searches' custom variable (or the
   corresponding Customize UI).  Each entry pairs an account plist
   (:name, :query, :key-prefix, optionally :get-command) with a
   list of saved searches in the standard `notmuch-saved-searches'
   format.  Setting this variable automatically flattens the
   per-account searches into `notmuch-saved-searches' with prefixed
   names and keys.

2. Add `notmuch-multi-hello-insert-accounts-searches' to
   `notmuch-hello-sections' to display one collapsible section per
   account on the Notmuch hello screen.

TAGGING AND DELETION

Interactive tagging commands are generated for four tag sets
(delete / expire / flag / spam) across three Notmuch modes:

  notmuch-multi-search-{delete,expire,flag,spam}-thread  -- search-mode
  notmuch-multi-tree-{delete,expire,flag,spam}-message   -- tree-mode
  notmuch-multi-show-{delete,expire,flag,spam}-message   -- show-mode

Calling any command with a prefix argument reverses (untags) the
operation.  In tree-mode a numeric prefix repeats the operation N
times.

Actual file removal is separate and explicit:
  `notmuch-multi-delete-mail'          -- rm files tagged for deletion
  `notmuch-multi-delete-expirable-mail' -- rm files tagged expire + old
  `notmuch-multi-delete-d+e-mail'      -- both of the above

SUBJECT FORMATTING

`notmuch-multi-search-format-subject' and
`notmuch-multi-tree-format-subject' can be plugged into
`notmuch-search-result-format' and `notmuch-tree-result-format'
respectively.  They truncate subjects at a word boundary, strip
emoji, and highlight by read/unread/match state.

SUGGESTED KEYBINDINGS

This package does not bind any keys by default to avoid overwriting
user configuration.  Suggested bindings to add to your init file:

  ;; Fetch mail for the account at point in the hello screen:
  (with-eval-after-load 'notmuch-hello
    (define-key notmuch-hello-mode-map (kbd "M-g")
                #'notmuch-multi-get-mail-at-point))

  ;; Address completion scoped to the sending account:
  (with-eval-after-load 'notmuch-message
    (define-key notmuch-message-mode-map (kbd "C-c TAB")
                #'notmuch-multi-address-complete))

Most of the tagging logic is adapted from Protesilaos Stavrou's
Notmuch configuration:
https://gitlab.com/protesilaos/dotfiles/-/blob/master/emacs/.emacs.d/prot-emacs-modules/prot-emacs-notmuch.el
https://git.sr.ht/~protesilaos/dotfiles/tree/master/item/emacs/.emacs.d/prot-lisp/prot-notmuch.el
