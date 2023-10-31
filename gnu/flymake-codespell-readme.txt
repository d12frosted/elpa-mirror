                                                              2022-12-09


1 flymake-codespell
═══════════════════

  This is a [codespell] backend for [Flymake] in Emacs, used to
  automatically highlight errors as you type.  It requires Emacs version
  26.1 or newer.

  Unlike most other spellcheckers, codespell does not have a dictionary
  of known words.  Instead it has a list of common typos, and checks
  only for those.  This means that it's far less likely to generate
  false positives, especially when used on source code, or any file with
  a lot of specific terms like documentation or research.


[codespell] <https://github.com/codespell-project/codespell>

[Flymake]
<https://www.gnu.org/software/emacs/manual/html_node/flymake/index.html>


2 Prerequisites
═══════════════

  First, install `codespell' on your system.  For example, if you're
  using Debian GNU/Linux, run this command in a terminal:

  ┌────
  │ sudo apt install codespell
  └────


  Once codespell is installed, install this package by typing the
  following in Emacs:

  ┌────
  │ M-x package-install RET flymake-codespell RET
  └────


3 Usage
═══════

  You must make sure the `flymake-codespell-setup-backend' function is
  called in the modes where you want to use it.  For example, to make
  sure it is run in all programming language modes, add the following
  line to your init file:

  ┌────
  │ (add-hook 'prog-mode-hook 'flymake-codespell-setup-backend)
  └────


  You can substitute `prog-mode-hook' for any mode hook.  For example,
  to add it to all text modes:

  ┌────
  │ (add-hook 'text-mode-hook 'flymake-codespell-setup-backend)
  └────


  You must also make sure `flymake' is enabled in the same modes.  Type
  `M-x flymake-mode' to enable it for the running session, or set up
  hooks.  For example:

  ┌────
  │ (add-hook 'prog-mode-hook 'flymake-mode)
  └────


  See the [Flymake manual] for more details.


[Flymake manual]
<Https://www.gnu.org/software/emacs/manual/html_node/flymake/index.html>


4 Usage with use-package
════════════════════════

  The `use-package' can simplify your init file, and is available
  out-of-the-box starting with Emacs 29.1.  For older versions, you must
  first install `use-package'.  Here is a `use-package' declaration that
  you can copy into your init file:

  ┌────
  │ (use-package flymake-codespell
  │   :ensure t
  │   :hook (prog-mode . flymake-codespell-setup-backend))
  └────


  This enables `flymake-codespell' in all programming language modes,
  and automatically installs it the next time you restart Emacs, if it
  isn't already.

  To add this to several modes, use something like the following:

  ┌────
  │ (use-package flymake-codespell
  │   :ensure t
  │   :hook ((prog-mode . flymake-codespell-setup-backend)
  │          (text-mode . flymake-codespell-setup-backend)))
  └────


  Here's a `use-package' declaration to unable flymake in the same
  modes:

  ┌────
  │ (use-package flymake
  │   :hook (prog-mode text-mode))
  └────


5 Customization
═══════════════

  To customize `flymake-codespell', type:

  ┌────
  │ M-x customize-group RET flymake-codespell RET
  └────


  If you prefer adding customizations to your init file, try setting the
  variables `flymake-codespell-program' and
  `flymake-codespell-program-arguments'.  These are their default
  values:

  ┌────
  │ (setq flymake-codespell-program "codespell")
  │ (setq flymake-codespell-program-arguments "")
  └────


  You could also use this `use-package' declaration:

  ┌────
  │ (use-package flymake-codespell
  │   :ensure t
  │   :custom ((flymake-codespell-program "codespell")
  │            (flymake-codespell-program-arguments ""))
  │   :hook ((prog-mode . flymake-codespell-setup-backend)
  │          (text-mode . flymake-codespell-setup-backend)))
  └────


6 Alternatives
══════════════

  Here are some alternatives to `flymake-codespell':

  • [flyspell-prog-mode], which comes with Emacs out-of-the-box.


[flyspell-prog-mode]
<https://www.gnu.org/software/emacs/manual/html_node/emacs/Spelling.html#index-flyspell_002dprog_002dmode>


7 Contribute
════════════

  This library is part of [GNU ELPA] and therefore requires a [copyright
  assignment] to the [Free Software Foundation] for any non-trivial
  contributions.

  Please email me a patch, or open a pull request on GitHub, according
  to your preferences.


[GNU ELPA] <https://elpa.gnu.org/packages/url-scgi.html>

[copyright assignment]
<https://www.gnu.org/software/emacs/manual/html_node/emacs/Copyright-Assignment.html>

[Free Software Foundation] <https://www.fsf.org/>


8 Contact
═════════

  You can find the latest version of flymake-codespell here:

  <https://www.github.com/skangas/flymake-codespell>

  Bug reports, comments, and suggestions are welcome!  Send them to
  Stefan Kangas <stefankangas@gmail.com> or report them on GitHub.
