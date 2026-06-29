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
    ⁃ [Codeberg]

  ⁃ Discuss the project in these XMPP MUCs:
    ⁃ `jabber-el@conference.hmm.st' for the project
    ⁃ `emacs@conference.conversations.im' for Emacs peer support
      including jabber.el


[XMPP] <http://xmpp.org>

[xmpp.org page] <https://xmpp.org/software/jabber-el/>

[Homepage] <https://thanosapollo.org/projects/jabber/>

[Codeberg] <https://codeberg.org/emacs-jabber/emacs-jabber/>


2 Requirements
══════════════

  ⁃ Emacs 29.1 or later, compiled with dynamic module support


2.1 OMEMO encryption (optional)
───────────────────────────────

  OMEMO end-to-end encryption uses a native C module built from the
  vendored [picomemo] source.  Build dependencies: a C compiler,
  `pkg-config', and Mbed TLS 3.0 or later (`mbedcrypto').

  Build the module manually from the jabber source or ELPA/package
  directory:

  ┌────
  │ cd /path/to/jabber-source-or-elpa-dir
  │ make module
  └────

  The resulting `jabber-omemo-core.so' (or `.dylib' on macOS) lands
  beside the Elisp files and is loaded automatically.  If the module is
  missing, OMEMO use signals `OMEMO module not compiled'.


[picomemo] <https://github.com/mierenhoop/picomemo>


3 Installation
══════════════

  `jabber.el' is available via [NonGNU ELPA].

  You can install it via `M-x package-install RET jabber'


[NonGNU ELPA] <https://elpa.nongnu.org/nongnu/jabber.html>

3.1 package-vc (Emacs 30+)
──────────────────────────

  Emacs honors package-vc build commands such as `:make' only when
  `package-vc-allow-build-commands' allows the package.

  ┌────
  │ (setq package-vc-allow-build-commands '(jabber))
  │ 
  │ (use-package jabber
  │   :ensure nil
  │   :vc (:url "https://codeberg.org/emacs-jabber/emacs-jabber.git"
  │             :branch "master"
  │             :rev :newest
  │             :lisp-dir "lisp"
  │             :doc "README.org"
  │             :make "module")
  │   :custom
  │   (jabber-account-list '(("user@example.org")))
  │   :config
  │   (jabber-modeline-mode 1)
  │   :bind-keymap (("C-x C-j" . jabber-global-keymap))
  │   :hook (kill-emacs . jabber-disconnect))
  └────


3.2 straight.el
───────────────

  ┌────
  │ (use-package jabber
  │   :straight `(jabber
  │               :type git
  │               :host codeberg
  │               :repo "emacs-jabber/emacs-jabber"
  │               :branch "master"
  │               :files ("lisp/*.el"
  │                       "lisp/jabber-omemo-core.so"
  │                       "lisp/jabber-omemo-core.dylib")
  │               :pre-build ,(pcase system-type
  │                             ('berkeley-unix '(("gmake" "module" "CC=clang")))
  │                             ('darwin '(("make" "module" "CC=clang")))
  │                             (_ '(("make" "module")))))
  │   :custom
  │   (jabber-account-list '(("user@example.org")))
  │   :config
  │   (jabber-modeline-mode 1)
  │   :bind-keymap (("C-x C-j" . jabber-global-keymap))
  │   :hook (kill-emacs . jabber-disconnect))
  └────


3.3 Nix
───────

  The repository ships a `flake.nix' with Emacs, test, lint, and
  native-module build dependencies.

  ┌────
  │ make test
  │ make module
  └────

  To enter the same environment manually:

  ┌────
  │ nix develop
  └────

  To run the isolated Nix checks:

  ┌────
  │ nix flake check
  └────


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
