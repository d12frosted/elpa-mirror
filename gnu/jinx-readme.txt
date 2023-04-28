		  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
		   JINX.EL - ENCHANTED SPELL CHECKER
		  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


Jinx is a fast just-in-time spell-checker for Emacs. Jinx highlights
misspelled words in the text of the visible portion of the buffer. For
efficiency, Jinx highlights misspellings lazily, recognizes window
boundaries and text folding, if any. For example, when unfolding or
scrolling, only the newly visible part of the text is checked if it has
not been checked before. Each misspelling can be corrected from a list
of dictionary words presented as a completion menu.

Installing Jinx is straight-forward and configuring takes not much
intervention.  Jinx can safely co-exist with Emacs's built-in
spell-checker.

Jinx's high performance and low resource usage comes from directly
calling the widely-used API of the Enchant library (see
[libenchant]). Jinx automatically compiles `jinx-mod.c' and loads the
dynamic module at startup. By binding directly to the native Enchant
API, Jinx avoids the slower backend process communication with
Aspell. Thanks to the Enchant API, this method is widely used by other
text editors and supports [Nuspell], [Hunspell], [Aspell] and a few
lesser known backends.

Jinx supports spell-checking multiple languages in the same buffer. See
the `jinx-languages' variable to customize for multiple languages. Jinx
can flexibly ignore misspellings via faces (`jinx-exclude-faces' and
`jinx-include-faces'), regular expressions (`jinx-exclude-regexps'), and
programmable predicates. Jinx comes preconfigured for the most important
Emacs major modes. For modes listed in `jinx-camel-modes' composite
words in camelCase and PascalCase are accepted.


[libenchant] <https://abiword.github.io/enchant/>

[Nuspell] <https://nuspell.github.io/>

[Hunspell] <http://hunspell.github.io/>

[Aspell] <http://aspell.net/>


1 Installation
══════════════

  Jinx can be installed from GNU ELPA and MELPA directly or with
  `package-install'.

  Jinx requires `libenchant'. Enchant library is a required dependency
  for Jinx to compile its module at install time. If `pkg-config' is
  available when installing Jinx, Jinx will use `pkg-config' to locate
  `libenchant'.

  On Debian or Ubuntu, install the packages `libenchant-2-dev' and
  `pkg-config'. On Fedora or RHEL, install the package
  `enchant2-devel'. On Mac, install `enchant2' and `pkgconfig'.


2 Configuration
═══════════════

  Jinx has two modes: the command, `global-jinx-mode' activates
  globally; and the command, `jinx-mode', for activating for specific
  modes.

  ┌────
  │ ;; Alternative 1: Enable Jinx globally
  │ (add-hook 'emacs-startup-hook #'global-jinx-mode)
  │ 
  │ ;; Alternative 2: Enable Jinx per mode
  │ (dolist (hook '(text-mode-hook prog-mode-hook conf-mode-hook))
  │   (add-hook hook #'jinx-mode))
  └────

  Jinx autoloads the commands `jinx-correct' and
  `jinx-languages'. Invoking `jinx-correct' corrects the
  misspellings. Binding `jinx-correct' to `M-$' chord takes over that
  chord from Emacs's default assignment to `ispell word'. Since Jinx is
  independent of the Emacs's Ispell package, `M-$' can be re-used.

  ┌────
  │ (keymap-global-set "<remap> <ispell-word>" #'jinx-correct)
  └────

  • `M-$' triggers correction for the misspelled word before point.
  • `C-u M-$' triggers correction for the entire buffer.

  A sample configuration with the popular `use-package' macro is shown
  here:

  ┌────
  │ (use-package jinx
  │   :hook (emacs-startup . global-jinx-mode)
  │   :bind ([remap ispell-word] . jinx-correct))
  └────


3 Correcting words
══════════════════

  Suggested corrections are displayed as a completion menu. You can
  press digit keys to quickly select a suggestion. Furthermore the menu
  offers options to save the word temporarily for the current session,
  in the personal dictionary or in the file-local variables. Note that
  you can enter arbitrary input at the correction prompt in order to
  make the correction. By pressing `M-n' (`M-p') again in the correction
  menu, you can skip to the next (previous) misspelling.

  The completion menu is compatible with all popular completion UIs:
  Vertico, Mct, Icomplete, Ivy, Helm and of course default
  completion. In case you use Vertico I suggest that you tweak the
  completion display via `vertico-multiform-mode' for the completion
  category `jinx'. You can for example use the grid display such that
  more suggestions fit on the screen.

  ┌────
  │ (add-to-list 'vertico-multiform-categories
  │ 	     '(jinx grid (vertico-grid-annotate . 25)))
  │ (vertico-multiform-mode 1)
  └────


4 Enchant backends and personal dictionaries
════════════════════════════════════════════

  Enchant uses different backends for different languages. The backends
  are ordered as specified in the personal configuration file
  `~/.config/enchant/enchant.ordering' and the system-wide configuration
  file `/usr/share/enchant-2/enchant.ordering'. Enchant uses Hunspell as
  default backend for most languages. There are a few exceptions. For
  English Enchant prefers Aspell and for Finnish and Turkish special
  backends called Voikko and Zemberek are used. On non-Linux operating
  systems Enchant may also integrate with the spell-checker provided by
  the operating system.

  Depending on the backend the personal dictionary will be taken from
  different locations, e.g., `~/.aspell.LANG.pws' or
  `~/.config/enchant/'. It is possible to symlink different personal
  dictionaries such that they are shared by different spell
  checkers. See the [Enchant manual] for details.


[Enchant manual] <https://abiword.github.io/enchant/src/enchant.html>


5 Alternative spell-checking packages
═════════════════════════════════════

  There exist multiple alternative spell-checking packages for Emacs,
  most famously the builtin ispell.el and flyspell.el packages. The main
  advantages of Jinx are its automatic checking of the visible text, its
  sharp focus on performance and the ability to easily use multiple
  dictionaries at once. The following three alternative packages come
  closest to the behavior of Jinx.

  • [jit-spell]: Jinx UI borrows ideas from Augusto Stoffel's
    Jit-spell. Jit-spell uses the less efficient Ispell process
    communication instead Jinx's calling native API. Since Jit-spell
    highlights misspellings in the entire buffer and does not confine to
    just the visible text, Jit-spell affected load and latency
    negatively in my tests ([issue on github]).

  • [spell-fu]: The idea to check words just in the visible text came
    from Campbell Barton's spell-fu package. Spell-fu is fast but incurs
    high memory overhead on account of its dictionary in a hash
    table. For languages with compound words and inflected word forms,
    this overhead magnifies ([issue on codeberg]). By accessing the
    Enchant API directly, Jinx avoids any overhead. Jinx also benefits
    from the advanced spell-checker algorithms of Enchant (affixation,
    compound words, etc.).

  • flyspell: Flyspell is Emacs's built-in package. Flyspell highlights
    misspellings while typing. Only the word under the cursor is
    spell-checked.  Jinx, on the other hand, is more effective because
    it automatically checks for misspellings in the entire visible text
    of the buffer at once. Flyspell can check the entire buffer but must
    be instructed to do so via the command `flyspell-buffer'.


[jit-spell] <https://github.com/astoff/jit-spell>

[issue on github] <https://github.com/astoff/jit-spell/issues/9>

[spell-fu] <https://codeberg.org/ideasman42/emacs-spell-fu>

[issue on codeberg]
<https://codeberg.org/ideasman42/emacs-spell-fu/issues/40>


6 Contributions
═══════════════

  Since this package is part of [GNU ELPA] contributions require a
  copyright assignment to the FSF.


[GNU ELPA] <https://elpa.gnu.org/packages/jinx.html>
