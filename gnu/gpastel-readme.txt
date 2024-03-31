1 gpastel
═════════

  <p> <a href="<https://stable.melpa.org/#/gpastel>"> <img alt="MELPA
    Stable"
    src="<https://stable.melpa.org/packages/gpastel-badge.svg"/>> </a>

  <a href="<https://melpa.org/#/gpastel>"> <img alt="MELPA"
    src="<https://melpa.org/packages/gpastel-badge.svg"/>> </a>

    <a
      href="<https://gitlab.petton.fr/DamienCassou/gpastel/commits/master>">
      <img alt="pipeline status"
      src="<https://gitlab.petton.fr/DamienCassou/gpastel/badges/master/pipeline.svg>"
      /> </a> </p>


1.1 Summary
───────────

  [GPaste] is a clipboard management system.  The Emacs package gpastel
  makes sure that every copied text in GPaste is also in the Emacs
  `kill-ring'.

  Emacs has built-in support for synchronizing the system clipboard with
  the `kill-ring' (see the variables `interprogram-paste-function' and
  `save-interprogram-paste-before-kill').  This support is not optimal
  because it makes the `kill-ring' only contain the last text of
  consecutive copied texts.  In other words, a user cannot copy multiple
  pieces of text from an external application without going back to
  Emacs in between.

  On the contrary, gpastel supports this scenario by hooking into the
  GPaste clipboard manager.  This means that the `kill-ring' will always
  contain everything the user copies in external applications, not just
  the last piece of text.

  Additionally, when using [EXWM] (the Emacs X Window Manager), gpastel
  makes it possible for the user to use the `kill-ring' from external
  applications.


[GPaste] <https://github.com/Keruspe/GPaste/>

[EXWM] <https://github.com/ch11ng/exwm>


1.2 Installing
──────────────

  Add the following to your initialization file:

  ┌────
  │ (add-to-list 'load-path "~/.emacs.d/lib/gpastel/")
  └────

  You also have to tell gpastel to start listening for GPaste events. If
  you are using EXWM, add `gpastel-mode' to `exwm-init-hook'. Otherwise,
  just add this line to your initialization file:

  ┌────
  │ (gpastel-mode)
  └────


1.3 Usage
─────────

  There is nothing more to do than copying text the normal way. All
  copied texts should appear in the Emacs `kill-ring' now.


1.3.1 For EXWM users
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  If you use EXWM and you want to access the `kill-ring' from any
  application (instead of the less powerful system clipboard), I
  recommend you either install and configure [counsel] or
  [browse-kill-ring]. Then, you can add one of the following two
  configuration snippets to your initialization file.


[counsel] <http://oremacs.com/swiper/>

[browse-kill-ring]
<https://github.com/browse-kill-ring/browse-kill-ring>

◊ 1.3.1.1 For EXWM+counsel users

  Add the following to your initialization file:

  ┌────
  │ (exwm-input-set-key (kbd "M-y") #'my/exwm-counsel-yank-pop)
  │ 
  │ (defun my/exwm-counsel-yank-pop ()
  │   "Same as `counsel-yank-pop' and paste into exwm buffer."
  │   (interactive)
  │   (let ((inhibit-read-only t)
  │ 	;; Make sure we send selected yank-pop candidate to
  │ 	;; clipboard:
  │ 	(yank-pop-change-selection t))
  │     (call-interactively #'counsel-yank-pop))
  │   (when (derived-mode-p 'exwm-mode)
  │     ;; https://github.com/ch11ng/exwm/issues/413#issuecomment-386858496
  │     (exwm-input--set-focus (exwm--buffer->id (window-buffer (selected-window))))
  │     (exwm-input--fake-key ?\C-v)))
  └────


◊ 1.3.1.2 For EXWM+browse-kill-ring users

  [Ram Krishnan] gives us the following piece of code for
  browse-kill-ring users:

  ┌────
  │ (define-advice browse-kill-ring-insert-and-highlight
  │     (:around (old-function str) exwm-paste)
  │   "Paste the selection appropriately in exwm mode buffers."
  │   (if (not (derived-mode-p 'exwm-mode))
  │       (funcall old-function str)
  │     (kill-new str)
  │     (exwm-input--fake-key ?\C-v)))
  └────


  [Ram Krishnan] <https://github.com/kriyative>


1.4 License
───────────

  See [COPYING]. Copyright (c) 2018 Damien Cassou.

  <a href="<https://liberapay.com/DamienCassou/donate>"> <img
    alt="Donate using Liberapay"
    src="<https://liberapay.com/assets/widgets/donate.svg>"> </a>


[COPYING] <file:COPYING>
