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

  OMEMO end-to-end encryption requires building a native C module.  You
  need a C compiler, `pkg-config', and `libmbedtls' (the development
  headers).  On first load, Emacs will prompt to build the module
  automatically.


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


3.2 From source
───────────────

  ┌────
  │ git clone https://git.thanosapollo.org/emacs-jabber/
  │ cd emacs-jabber
  │ make module   # optional, for OMEMO support
  └────

  Then add to your init file:

  ┌────
  │ (add-to-list 'load-path "/path/to/emacs-jabber/lisp")
  │ (require 'jabber)
  └────


4 Configuration
═══════════════

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


5 Basic commands
════════════════

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Key                   Command                          
  ────────────────────────────────────────────────────────
   `M-x jabber-connect'  Connect (prompts for account)    
   `C-x C-j C-c'         Connect all accounts             
   `C-x C-j C-d'         Disconnect                       
   `C-x C-j C-r'         Open roster buffer               
   `C-x C-j C-j'         Start or switch to a chat        
   `C-x C-j C-m'         Join/switch to a MUC (groupchat) 
   `C-x C-j C-b'         Switch to a chat buffer          
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
