           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  AUCTEX-CONT-LATEXMK.EL: RUN LATEXMK
                CONTINUOUSLY, REPORT ERRORS VIA FLYMAKE
           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━





1 Overview
══════════

  This package provides a minor mode where [latexmk] continuously
  compiles the document in the background and the errors/warnings are
  reported via [Flymake].


[latexmk] <https://ctan.org/pkg/latexmk?lang=en>

[Flymake]
<https://www.gnu.org/software/emacs/manual/html_node/emacs/Flymake.html>


2 Configuration and usage
═════════════════════════

  Download this repository, install using `M-x package-install-file' (or
  package-vc-install, straight, elpaca, …), and add something like the
  following to your [init file]:
  ┌────
  │ (use-package auctex-cont-latexmk
  │   :after latex
  │   :bind
  │   (:map LaTeX-mode-map
  │ 	("C-c k" . auctex-cont-latexmk-toggle)))
  └────
  Replace the keybinding with whatever you prefer (or delete it and just
  run the command via `M-x').

  The command `auctex-cont-latexmk-toggle' behaves the way that I prefer
  – it enables both `auctex-cont-latexmk-mode' and `flymake-mode',
  restricting the backends for the latter to those coming from the
  former.  If you want to use continuous compilation but no flymake,
  then you might instead wish to bind a key to
  `auctex-cont-latexmk-mode' or simply do `M-x
  auctex-cont-latexmk-mode'.  If you already use flymake for something
  else in tex buffers, then you might wish to write your own "wrapper"
  for `auctex-cont-latexmk-mode' akin to `auctex-cont-latexmk-toggle'.

  The way the Flymake backend works, it will update only when the
  latexmk process reaches a "watching for changes" state and the buffer
  is unmodified.  The workflow is thus to save the file, wait a few
  seconds for the compilation to complete, and then to use Flymake to
  navigate the errors.  I configure Flymake to use `M-n' and `M-p' for
  navigation, and also use `(setq
  flymake-show-diagnostics-at-end-of-line t)' (available in Flymake
  1.3.6, part of Emacs 30+), which displays the error/warning messages
  in the buffer itself rather than just in the minibuffer:

  ┌────
  │ (use-package flymake
  │   :custom
  │   (flymake-show-diagnostics-at-end-of-line t)
  │   :bind
  │   (:map flymake-mode-map
  │ 	("M-n" . flymake-goto-next-error)
  │ 	("M-p" . flymake-goto-prev-error)))
  └────

  I also bind `flymake-show-diagnostics-buffer', which gives an overview
  of all errors.  You can find my current setup in [my config].

  That's all.  I prefer this workflow to the alternative in which one
  compiles the document manually via `TeX-command-master' (`C-c C-c')
  and navigates the warning/error messages using `next-error' (`M-n')
  and `previous-error' (`M-p').  It also gives a handy way to keep the
  .aux files up-to-date; I take advantage of this feature in the
  packages [czm-preview.el] and [czm-tex-fold.el] to annotate the TeX
  buffer with label numbers.


[init file] <https://www.emacswiki.org/emacs/InitFile>

[my config] <https://github.com/ultronozm/emacsd/blob/main/init-main.el>

[czm-preview.el] <https://github.com/ultronozm/czm-preview.el>

[czm-tex-fold.el] <https://github.com/ultronozm/czm-tex-fold.el>


3 Tips
══════

  • TeX compilers are not so good at locating errors involving braces.
    For this, the Emacs commands `check-parens', `tex-validate-buffer'
    and `tex-validate-region' are indispensable.  In particular, you
    should always try these commands when you encounter errors at the
    bottom of a file concerning an incomplete argument or environment.
  • You can use the command `M-x auctex-cont-latexmk-help-at-point' (or
    bind it to a key) if you want to see AUCTeX's help message (if any)
    for the error at point.


4 Customization
═══════════════

  • You can tweak the underlying `latexmk' command via `M-x
    customize-variable auctex-cont-latexmk-command'.
  • This package respects the AUCTeX variable `TeX-output-dir': you can
    use that variable to control where the output files generated via
    latexmk are placed.


5 Troubleshooting
═════════════════

  • The compilation takes place in a buffer *pvc-filename*, so look
    there if you need to see the output.
  • AUCTeX's error parsing doesn't work well with filenames (or paths)
    that contain parentheses, so don't put parentheses in your
    filenames.
