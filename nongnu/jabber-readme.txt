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
    ⁃ [git.thanosapollo.org]


[XMPP] <http://xmpp.org>

[xmpp.org page] <https://xmpp.org/software/jabber-el/>

[Homepage] <https://thanosapollo.org/projects/jabber/>

[git.thanosapollo.org]
<https://git.thanosapollo.org/emacs-jabber/about/>


2 Requirements
══════════════

  ⁃ Emacs 29.1 or later, compiled with dynamic module support
  ⁃ [fsm] 0.2.0 or later
  ⁃ [keymap-popup] 0.2 or later


[fsm] <https://elpa.gnu.org/packages/fsm.html>

[keymap-popup] <https://elpa.gnu.org/packages/keymap-popup.html>

2.1 OMEMO encryption (optional)
───────────────────────────────

  OMEMO end-to-end encryption uses a native C module built from the
  vendored [picomemo] source.  Build dependencies: a C compiler,
  `pkg-config', and Mbed TLS 3.0 or later (`mbedcrypto').

  Build the module from the ELPA package directory:

  ┌────
  │ cd /path/to/elpa/jabber-VERSION
  │ make module
  └────

  The resulting `jabber-omemo-core.so' (or `.dylib' on macOS) lands
  beside the Elisp files and is loaded automatically.  If the module is
  missing, OMEMO use signals `OMEMO module not compiled'.


[picomemo] <https://github.com/mierenhoop/picomemo>


3 Installation
══════════════

  `jabber.el' is available via [NonGNU ELPA].  That is the only
  supported install path.

  ┌────
  │ (use-package jabber
  │   :ensure t
  │   :config
  │   (setq jabber-account-list
  │         `(("user@example.org"
  │            (:password . ,(auth-source-pass-get 'secret "xmpp/example.org")))))
  │   (jabber-modeline-mode 1)
  │   :bind-keymap (("C-x C-j" . jabber-global-keymap))
  │   :hook (kill-emacs . jabber-disconnect))
  └────


[NonGNU ELPA] <https://elpa.nongnu.org/nongnu/jabber.html>


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


4.2 SOCKS5 proxy
────────────────

  An account can connect through an unauthenticated SOCKS5 proxy:

  ┌────
  │ (setq jabber-account-list
  │       '(("user@example.org"
  │          (:proxy . (:type socks5 :host "127.0.0.1" :port 9050)))))
  └────

  The destination hostname is sent to the proxy rather than resolved
  locally.  Proxy connections bypass SRV lookup and use the JID domain
  on port 5222, or `:network-server' and `:port' when those are
  configured.  STARTTLS is supported.  Direct TLS discovery, proxy
  authentication, and other proxy protocols are not supported for
  proxied accounts.


4.3 Bug references
──────────────────

  ┌────
  │ (add-hook 'jabber-chat-mode-hook #'bug-reference-mode)
  │ 
  │ ;; Customize references
  │ (setq jabber-bug-reference-alist
  │       '(("jabber-el@conference\\.hmm\\.st"
  │          "\\(#\\([0-9]+\\)\\)"
  │          "https://todos.thanosapollo.org/r/emacs-jabber/%s")))
  └────


5 Basic commands
════════════════

  ⁃ Use `M-x jabber-roster' or `C-x C-j C-r' to get started.
