leadkey.el — a modal leader-key package for Emacs.

It intercepts one or more "leader keys" via `key-translation-map' and
translates subsequent keystrokes into standard Emacs key sequences.
This means you can type SPC f and have it arrive at Emacs as C-c C-f,
using all your existing keybindings with zero rebinding.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Quick start
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  (require 'leadkey)
  (require 'leadkey-which-key)  ; optional which-key integration

  ;;leadkey is not enabled for your insert state
  (add-to-list 'leadkey-pass-through-predicates #'helixel-insert-state-p)

  (leadkey-mode 1)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Configuration (keyword format)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

(setq leadkey-keys
  '((:key "<SPC>" :prefix "C-c" :modifier nil :fallback "C-"
      :dispatch
      ((?x . (:prefix "C-x" :modifier "C-" :fallback nil
               ;SPC always toggle (ignore C-x C-SPC)
               :dispatch ((?\s . :toggle))))
      (?h . (:prefix "C-h" :modifier nil  :fallback "C-"))
      (?s . (:prefix "M-s" :modifier nil  :fallback "M-"))
      (?g . (:prefix "M-g" :modifier nil  :fallback "M-"))
      (?m . (:prefix nil  :modifier "M-" :fallback nil))))
    (:key "," :prefix nil :modifier "M-" :fallback nil)
    (:key "." :prefix nil :modifier "C-M-" :fallback nil
        :pass-through-predicates (vc-dir-mode))))

Each entry is a plist:
  :key       - leader key string ("<SPC>", ",")
  :prefix    - target prefix string ("C-c", "C-x", nil for modifier-only)
  :modifier  - default modifier ("C-", "M-", nil)
  :fallback  - fallback modifier (nil = plain only)
  :toggle    - toggle target modifier (default: inferred)
  :dispatch  - alist (CHAR . PLIST) or (CHAR . :toggle)
  :pass-through-predicates - per-key override, nil = use global

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 How it works
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Unlike packages that bind commands under a custom keymap (general.el,
evil-leader, etc.), leadkey translates keystrokes in
`key-translation-map' — BEFORE they hit any keymap.  This means:

  SPC f  →  C-c C-f    (if C-c C-f is bound, it Just Works™)
  SPC x  →  C-x        (enters the standard C-x prefix)
  , a    →  M-a        (comma becomes M- leader)

No need to manually rebind every command — all your existing C-c,
C-x, M-, etc. bindings work automatically through the leader key.
