                      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                       README OF VERTICO-POSFRAME
                      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━





1 What is vertico-posframe
══════════════════════════

  vertico-posframe is an vertico extension, which lets vertico use
  posframe to show its candidate menu.

  NOTE: vertico-posframe requires Emacs 26 and do not support mouse
  click.


2 How to enable vertico-posframe
════════════════════════════════

  ┌────
  │ (require 'vertico-posframe)
  │ (vertico-posframe-mode 1)
  └────


3 Tips
══════

3.1 How to let vertico-posframe work well with vertico-multiform.
─────────────────────────────────────────────────────────────────

  ┌────
  │ (setq vertico-multiform-commands
  │       '((consult-line
  │          posframe
  │          (vertico-posframe-poshandler . posframe-poshandler-frame-top-center)
  │          (vertico-posframe-border-width . 10)
  │          ;; NOTE: This is useful when emacs is used in both in X and
  │          ;; terminal, for posframe do not work well in terminal, so
  │          ;; vertico-buffer-mode will be used as fallback at the
  │          ;; moment.
  │          (vertico-posframe-fallback-mode . vertico-buffer-mode))
  │         (t posframe)))
  │ (vertico-multiform-mode 1)
  └────

  NOTE: vertico-posframe-mode will be activated/deactivated by
  vertico-multiform-mode dynamically when you add 'posframe' setting to
  vertico-multiform-commands, please do not enable vertico-posframe-mode
  globally at the moment.


3.2 To conditionally disable posframe
─────────────────────────────────────

  ┌────
  │ (setq vertico-multiform-commands
  │       '((consult-line (:not posframe))
  │         (t posframe)))
  └────


3.3 How to show fringe to vertico-posframe
──────────────────────────────────────────

  ┌────
  │ (setq vertico-posframe-parameters
  │       '((left-fringe . 8)
  │         (right-fringe . 8)))
  └────

  By the way, User can set *any* parameters of vertico-posframe with the
  help of `vertico-posframe-parameters'.
