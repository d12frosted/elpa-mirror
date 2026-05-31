                ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                 JABBER.EL - THE XMPP CLIENT FOR EMACS
                ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


1 About
═══════

  <https://elpa.nongnu.org/nongnu/jabber.svg>

  `jabber.el' is an [XMPP] client for Emacs.

  See the [xmpp.org page] for the full list of supported XEPs.

  ⁃ [Homepage]

  ⁃ Source:
    ⁃ [Upstream]
    ⁃ [Codeberg] /Mirror/


[XMPP] <http://xmpp.org>

[xmpp.org page] <https://xmpp.org/software/jabber-el/>

[Homepage] <https://thanosapollo.org/projects/jabber/>

[Upstream] <https://git.thanosapollo.org/emacs-jabber/>

[Codeberg] <https://codeberg.org/emacs-jabber/emacs-jabber/>


2 Requirements
══════════════

  ⁃ Emacs 29.1 or later, compiled with dynamic module support


2.1 OMEMO encryption (optional)
───────────────────────────────

  OMEMO end-to-end encryption uses a native C module.  Build
  dependencies: a C compiler, `pkg-config', and `libmbedtls'.

  On first use of OMEMO, Emacs offers to fetch [picomemo] and build
  `jabber-omemo-core' in place.  This works for all install methods
  (`git clone', `package-vc', and NonGNU ELPA) provided the install
  directory is writable and the build dependencies are present.

  If you prefer to build manually:

  ┌────
  │ cd /path/to/jabber-source-or-elpa-dir
  │ make module
  └────

  The resulting `jabber-omemo-core.so' (or `.dylib' on macOS) lands
  beside the Elisp files and is loaded automatically.


[picomemo] <https://github.com/mierenhoop/picomemo>


3 Installation
══════════════

  `jabber.el' is available via [NonGNU ELPA].

  You can install it via `M-x package-install RET jabber'


[NonGNU ELPA] <https://elpa.nongnu.org/nongnu/jabber.html>

3.1 package-vc (Emacs 30+)
──────────────────────────

  ┌────
  │ (use-package jabber
  │   :ensure nil
  │   :vc (:url "https://git.thanosapollo.org/emacs-jabber/"
  │             :branch "master"
  │             :rev :newest
  │             :lisp-dir "lisp")
  │   :custom
  │   (jabber-account-list '(("user@example.org")))
  │   :config
  │   (jabber-modeline-mode 1)
  │   :bind-keymap (("C-x C-j" . jabber-global-keymap))
  │   :hook (kill-emacs . jabber-disconnect))
  └────


3.2 GNU Guix
────────────

  The repository ships a `guix.scm' that builds straight from the
  current working tree, so you never need to update hashes or pin a
  commit.  Whatever is checked out is what gets installed.  Picomemo is
  fetched as a pinned input by `guix.scm', so the optional OMEMO
  submodule does not need to be initialised.

  ┌────
  │ git clone https://git.thanosapollo.org/emacs-jabber/
  │ cd emacs-jabber
  └────

  One-shot install into your user profile:

  ┌────
  │ guix package -f guix.scm
  └────

  A development shell with all build dependencies:

  ┌────
  │ guix shell -D -f guix.scm
  └────

  To use `emacs-jabber' from a Guix Home configuration, load the package
  definition and reference it from your services:

  ┌────
  │ (use-modules (gnu home)
  │              (gnu home services)
  │              (gnu home services guix)
  │              (gnu services)
  │              (guix channels)
  │              (guix gexp))
  │ 
  │ (define emacs-jabber-git
  │   (load "/path/to/emacs-jabber/guix.scm"))
  │ 
  │ (home-environment
  │  (packages (list emacs-jabber-git)))
  └────

  Re-run `guix home reconfigure' after pulling new commits and the
  package will be rebuilt from the updated checkout.


4 Configuration
═══════════════

4.1 Authentication
──────────────────

  Accounts are configured via `jabber-account-list'.  The simplest form
  uses auth-source `~/.authinfo.gpg' for passwords:

  ┌────
  │ (setq jabber-account-list '(("user@example.org")
  │                              ("second@account.org")))
  └────

  With `pass' (password-store):

  ┌────
  │ (setq jabber-account-list
  │       `(("user@example.org"
  │          (:password . ,(auth-source-pass-get 'secret "xmpp/example.org/user")))))
  └────


4.2 Bug references
──────────────────

  ┌────
  │ (add-hook 'jabber-chat-mode-hook #'bug-reference-mode)
  │ 
  │ ;; Customize references
  │ (setq jabber-bug-reference-alist
  │       '(("jabber-el@conference\\.hmm\\.st"
  │          "\\(#\\([0-9]+\\)\\)"
  │          "https://codeberg.org/emacs-jabber/emacs-jabber/issues/%s")
  │         ("#guix%irc\\.libera.chat@irc\\.biboumi-gateway\\.example"
  │          "\\(#\\([0-9]+\\)\\)"
  │          "https://codeberg.org/guix/guix/issues/%s")))
  └────


5 Basic commands
════════════════

  ⁃ Use `M-x jabber-roster' or `C-x C-j C-r' to get started.
