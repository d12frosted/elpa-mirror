           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              AUCTEX-LABEL-NUMBERS.EL: NUMBERING FOR LATEX
                           PREVIEWS AND FOLDS
           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━





1 Overview
══════════

  The package provides a function,
  `auctex-label-numbers-label-to-number', that retrieves label numbers
  in LaTeX documents.  This function is used to implement a global minor
  mode, `auctex-label-numbers-mode', that augments the preview and
  folding features of [AUCTeX]:

  • Previews of labeled equations are numbered as in the compiled
    document.

  • The macros `\ref', `\eqref', and `\label' are folded with the
    corresponding numbers.

  • `completion-at-point' annotations for the contents of `\ref' and
    `\eqref' include equation numbers.

  • Annotations for the command `reftex-goto-label'.


[AUCTeX]
<https://www.gnu.org/software/auctex/manual/auctex/Installation.html#Installation>


2 Configuration
═══════════════

  This package requires [AUCTeX], so install that first.

  Download this repository, install using `M-x package-install-file' (or
  package-vc-install, straight, elpaca, …), and add something like the
  following to your [init file]:
  ┌────
  │ (use-package auctex-label-numbers
  │   :after latex
  │   :config
  │   (auctex-label-numbers-mode 1))
  └────
  With this, the package activates automatically.

  You could alternatively use simply `(use-package
  auctex-label-numbers)' and activate via `M-x
  auctex-label-numbers-mode' or `(auctex-label-numbers-mode 1)' whenever
  you'd like (e.g., in the middle of some other customizations of
  `TeX-fold-mode').  If you'd like to enable some (but not all) of the
  provided functionality, then you can extract from the definition of
  `auctex-label-numbers-mode' the pieces that you'd like and put those
  in your config.


[AUCTeX]
<https://www.gnu.org/software/auctex/manual/auctex/Installation.html#Installation>

[init file] <https://www.emacswiki.org/emacs/InitFile>


3 Usage
═══════

  The label numbers are retrieved from the aux file of the compiled
  document.  To update them, one should compile the document, regenerate
  the previews and refresh the folds.

  The previews should be numbered automated.  To activate the folds,
  you'll want to make sure `TeX-fold-mode' is enabled (`C-c C-o C-f' to
  toggle) and then fold the buffer (`C-c C-o C-b') – see the [folding
  section] of AUCTeX's manual for details.

  I use the packages [tex-continuous.el] and [preview-auto.el] (with the
  variable `preview-auto-refresh-after-compilation' is set to its
  default value, `t') to compile the document and regenerate the
  previews automatically, and refresh the folds as needed using
  `TeX-fold-section' (`C-c C-o C-s').


[folding section]
<https://www.gnu.org/software/auctex/manual/auctex/Folding.html >

[tex-continuous.el] <https://github.com/ultronozm/tex-continuous.el>

[preview-auto.el] <https://github.com/ultronozm/preview-auto.el>


4 Customization
═══════════════

  By customizing the variable
  `auctex-label-numbers-label-to-number-function', one could specify a
  different way to retrieve label numbers, e.g., by querying an LSP
  server.
