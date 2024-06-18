           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
             PREVIEW-TAILOR: TAILOR AUCTEX PREVIEW SCALE TO
                           MONITOR/TEXT SCALE
           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━





1 Overview
══════════

  The [preview] feature of [AUCTeX] provides live rendering of TeX code
  at a user-specified preview scale.  This package makes the preview
  scale vary in a natural way with the text scale and the monitor.  In
  particular, it provides the command `M-x
  preview-tailor-set-multiplier' that allows you to adjust the preview
  scale for a given monitor.


[preview]
<https://www.gnu.org/software/auctex/manual/preview-latex/preview-latex.html>

[AUCTeX] <https://www.gnu.org/software/auctex/>


2 Configuration
═══════════════

  Download this repository, install using `M-x package-install-file' (or
  package-vc-install, straight, elpaca, …), and add something like the
  following to your [init file]:
  ┌────
  │ (use-package preview-tailor
  │   :demand
  │   :config
  │   (preview-tailor-init)
  │   :hook
  │   (kill-emacs . preview-tailor-save))
  └────
  The function `preview-tailor-init' sets the customization variable
  `preview-scale-function' to a function internal to this package that
  provides the calculation, so make sure you don't modify that variable
  elsewhere in your init file.


[init file] <https://www.emacswiki.org/emacs/InitFile>


3 Usage
═══════

  To adjust the multiplier for the current monitor, use `M-x
  preview-tailor-set-multiplier'.


4 Implementation details and refinements
════════════════════════════════════════

  The monitor-specific multipliers are stored in the variable
  `preview-tailor-multipliers', an association list mapping lists of
  monitor attributes to numbers.  The multiplier is calculated by
  finding the first entry in the list that matches the current monitor's
  attributes.  These multipliers are saved for future sessions in the
  dotfile `.preview-tailor' inside your `user-emacs-directory'.  This
  separation keeps monitor settings, which may be specific to a given
  computer, independent of your init file, which you might synchronize
  across multiple computers.

  The preview scale is determined by multiplying five factors:

  1. The result of `preview-scale-from-face'.
  2. The current text scale factor (adjusted via the `text-scale-adjust'
     commands, default bindings `C-x C-+' and `C-x C--').
  3. A multiplier based on the current frame's monitor attributes, set
     via `M-x preview-tailor-set-multiplier', defaulting to 1.
  4. An additional factor provided by the user customization
     `preview-tailor-additional-factor-function' (default is `nil',
     meaning this factor is omitted).
  5. The buffer-local variable `preview-tailor-local-multiplier', which
     defaults to 1.

  The last two factors add convenience for varying the preview scale in
  different settings.  For example, I use preview in both `LaTeX-mode'
  and `lean4-mode', with different preview scales. This is because I use
  `buffer-face-mode' in `LaTeX-mode', but not in `lean4-mode'. To
  achieve this, I add a function to `lean4-mode-hook' that sets
  `preview-tailor-local-multiplier' to 0.7.
