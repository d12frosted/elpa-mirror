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

Installing Jinx is straight-forward and configuring should not need much
intervention. Jinx can be used completely on its own, but can also
safely co-exist with Emacs's built-in spell-checker Ispell.

Jinx's high performance and low resource usage comes from directly
calling the widely-used API of the Enchant library (see
[libenchant]). Jinx automatically compiles `jinx-mod.c' and loads the
dynamic module at startup. By binding directly to the native Enchant
API, Jinx avoids the slower backend process communication with
Aspell. Enchant is widely used by other text editors and supports
[Nuspell], [Hunspell], [Aspell] and a few language-specific backends.

Jinx supports spell-checking multiple languages in the same buffer. See
the `jinx-languages' variable to customize for multiple languages. Jinx
can flexibly ignore misspellings via faces (`jinx-exclude-faces' and
`jinx-include-faces'), regular expressions (`jinx-exclude-regexps'), and
programmable predicates. Jinx comes preconfigured for the most important
Emacs major modes. Modes like Java, Ruby or Rust are listed in
`jinx-camel-modes'. For these modes composite words in `camelCase' and
`PascalCase' are accepted.


[libenchant] <https://abiword.github.io/enchant/>

[Nuspell] <https://nuspell.github.io/>

[Hunspell] <http://hunspell.github.io/>

[Aspell] <http://aspell.net/>


1 Installation
══════════════

  Jinx can be installed from GNU ELPA or MELPA directly with
  `package-install'.

  Jinx requires `libenchant'. Enchant library is a required dependency
  for Jinx to compile its module at install time. If `pkgconf' or
  `pkg-config' is available when installing Jinx, Jinx will use it to
  locate `libenchant'. Depending on your BSD or Linux distribution you
  have to install different packages:

  • Debian, Ubuntu: `libenchant-2-dev', `pkgconf'
  • Arch, Gentoo: `enchant', `pkgconf'
  • Guix: `emacs-jinx' or `enchant', `pkgconf'
  • NixOS: `jinx' from `elpa-packages.nix'
  • Void, Fedora: `enchant2-devel', `pkgconf'
  • FreeBSD, OpenBSD: `enchant2', `pkgconf'

  There have been reports of hangups when loading the native module on
  unofficial Emacs Mac ports. On Windows the installation of the native
  module may require manual intervention.


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

  The commands `jinx-correct' and `jinx-languages' are marked as
  autoloads. Invoking `jinx-correct' corrects the misspellings. Binding
  `jinx-correct' to `M-$' takes over that key from the default
  assignment to `ispell-word'. Since Jinx is independent of the Ispell
  package, `M-$' can be re-used.

  ┌────
  │ (keymap-global-set "M-$" #'jinx-correct)
  │ (keymap-global-set "C-M-$" #'jinx-languages)
  └────

  • `M-$' triggers correction for the misspelled word before point.
  • `C-u M-$' triggers correction for the entire buffer.
  • `C-u C-u M-$' forces correction of the word at point, even if it is
    not misspelled.

  A sample configuration with the popular `use-package' macro is shown
  here:

  ┌────
  │ (use-package jinx
  │   :hook (emacs-startup . global-jinx-mode)
  │   :bind (("M-$" . jinx-correct)
  │ 	 ("C-M-$" . jinx-languages)))
  └────

  See also the [Jinx Wiki] for additional configuration tips. The wiki
  documents configurations to save misspellings as global abbreviations
  and support for Ispell `LocalWords'.


[Jinx Wiki] <https://github.com/minad/jinx/wiki>


3 Correcting misspellings
═════════════════════════

  After invoking the command `jinx-correct', suggested corrections are
  displayed as a completion menu. You can press the displayed digit keys
  to quickly select a suggestion. Furthermore the menu offers options to
  save the word temporarily for the current session, in the personal
  dictionary or in the file-local variables.

  Note that you can enter arbitrary input at the correction prompt in
  order to make the correction or to store a modified word in the
  personal dictionary.  For example if you typed `alotriomorpc', the
  prompt offers you the option `@alotriomorpc' which would add this word
  to your personal dictionary upon selection. You can then correct the
  option to `@allotriomorphic' and add it to the dictionary.

  While inside the `jinx-correct' prompt, the keys `M-n' and `M-p' are
  bound to `jinx-next' and `jinx-previous' respectively and allow you to
  move the next and previous misspelled word.

  The completion menu is compatible with all popular completion UIs:
  Vertico, Mct, Icomplete, Ivy, Helm and the default completions
  buffer. In case you use Vertico I suggest that you tweak the
  completion display via `vertico-multiform-mode' for the completion
  category `jinx'. You can for example use the grid display such that
  more suggestions fit on the screen and enable annotations.

  ┌────
  │ (add-to-list 'vertico-multiform-categories
  │ 	     '(jinx grid (vertico-grid-annotate . 20)))
  │ (vertico-multiform-mode 1)
  └────


4 Navigating between misspellings
═════════════════════════════════

  As mentioned before, when correcting a word with `jinx-correct', the
  movement commands `jinx-next' and `jinx-previous' are available on the
  keys `M-n' and `M-p' to navigate to the next and previous misspelling
  respectively. The movement commands work from within the minibuffer
  during `jinx-correct' and also globally outside the minibuffer
  context.

  While the commands are not bound globally by default, they are
  available as `M-n' and `M-p' if point is placed on top of a misspelled
  word overlay. If you want you can add them and other commands to the
  `jinx-mode-map', such that they are always available independent of
  point placement. If `repeat-mode' from Emacs 28 is enabled, the
  movement can be repeated with the keys `n' and `p'.


5 Enchant backends and personal dictionaries
════════════════════════════════════════════

  Enchant uses different backends for different languages. The backends
  are ordered as specified in the personal configuration file
  `~/.config/enchant/enchant.ordering' and the system-wide configuration
  file `/usr/share/enchant-2/enchant.ordering'. Enchant uses Hunspell as
  default backend for most languages. There are a few exceptions. For
  English Enchant prefers Aspell and for Finnish and Turkish special
  backends called Voikko and Zemberek are used. On some operating
  systems Enchant may also integrate with the system spell-checker.

  Depending on the backend the personal dictionary will be taken from
  different locations, e.g., `~/.aspell.LANG.pws' or
  `~/.config/enchant/LANG.dic'. It is possible to symlink different
  personal dictionaries such that they are shared by different spell
  checkers. See the [Enchant manual] for details.


[Enchant manual] <https://abiword.github.io/enchant/src/enchant.html>


6 Alternative spell-checking packages
═════════════════════════════════════

  There exist multiple alternative spell-checking packages for Emacs,
  most famously the builtin ispell.el and flyspell.el packages. The main
  advantages of Jinx are its automatic checking of the visible text, its
  sharp focus on performance and the ability to easily use multiple
  dictionaries at once. The following three alternative packages come
  closest to the behavior of Jinx.

  • [jit-spell]: Jinx UI borrows ideas from Augusto Stoffel's
    Jit-spell. Jit-spell uses the less efficient Ispell process
    communication instead of Jinx's calling a native API. Since
    Jit-spell does not restrict spell checking to the visible text only,
    it may enqueue the entire buffer too eagerly for checking. This
    happens when scrolling around or when stealth font locking is
    enabled. For this reason, Jit-spell affected load and latency in my
    tests ([issue on Github]).

  • [spell-fu]: The idea to check words just in the visible text came
    from Campbell Barton's spell-fu package. Spell-fu is fast but incurs
    high memory overhead on account of its dictionary in a hash
    table. For languages with compound words and inflected word forms,
    this overhead magnifies ([issue on Codeberg]). By accessing the
    Enchant API directly, Jinx avoids any overhead. Jinx also benefits
    from the advanced spell-checker algorithms of Enchant (affixation,
    compound words, etc.).

  • flyspell: Flyspell is a built-in package. Flyspell highlights
    misspellings while typing. Only the word under the cursor is
    spell-checked. Jinx, on the other hand, is more effective because it
    automatically checks for misspellings in the entire visible text of
    the buffer at once. Flyspell can check the entire buffer but must be
    instructed to do so via the command `flyspell-buffer'.


[jit-spell] <https://github.com/astoff/jit-spell>

[issue on Github] <https://github.com/astoff/jit-spell/issues/9>

[spell-fu] <https://codeberg.org/ideasman42/emacs-spell-fu>

[issue on Codeberg]
<https://codeberg.org/ideasman42/emacs-spell-fu/issues/40>


7 Contributions
═══════════════

  Since this package is part of [GNU ELPA] contributions require a
  copyright assignment to the FSF.


[GNU ELPA] <https://elpa.gnu.org/packages/jinx.html>
