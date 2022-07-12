			     ━━━━━━━━━━━━━━
			      EVIL NUMBERS
			     ━━━━━━━━━━━━━━


Table of Contents
─────────────────

1. Features
.. 1. Detected Literals
2. Usage
.. 1. Customization
.. 2. Key Bindings
3. Install
.. 1. Basic Installation
.. 2. Use Package
4. Known Bugs
5. Similar Packages
6. Contributors





1 Features
══════════

  • Increment / Decrement binary, octal, decimal and hex literals.

  • Works like `C-a' / `C-x' in VIM, i.e. searches for number up to
    `eol' and then increments or decrements.

  • When a region is active, as in evil's visual mode, all the numbers
    within that region will be incremented/decremented (unlike in VIM).

  • Increment/decrement numbers incrementally like `g C-a' / `g C-x' in
    VIM.

  • Optionally keep zero padding (off by default).


1.1 Detected Literals
─────────────────────

  • Binary, e.g. `0b0101', `0B0101'.
  • Octal, e.g. `0o755', `0O700'.
  • Hexadecimal, e.g. `0xDEADBEEF', `0XCAFE'.
  • Unicode superscript and subscript, e.g. `²' and `₁'.


2 Usage
═══════

  Once this package is installed, all you need to do is bind keys to
  `evil-numbers/inc-at-pt' and `evil-numbers/dec-at-pt'.

  Position cursor over or before the literal and play with your numbers!

  You may also want to bind keys to the incremental versions of these
  functions.


2.1 Customization
─────────────────

  `evil-numbers-pad-default'
        Set to `t' if you want numbers to be padded with zeros (numbers
        with a leading zero are always padded).  If you want both
        behaviors, all commands take an optional argument `padded'.

  `evil-numbers-separator-chars'
        This option to support separator characters, set to "_" or ","
        to support numeric literals such as: `16_777_216' or
        `4,294,967,296'.

        You may wish to set this as a buffer local variable to enable
        this only for languages that support separators.

  `evil-numbers-case'
        The case to use for hexadecimal numbers.

        • `nil' Current case (default).
        • '`upcase' Always upper case.
        • '`downcase' Always lower case.

  `evil-numbers-use-cursor-at-end-of-number'
        Support matching numbers directly before the cursor.

        This is off by default as it doesn't follow VIM's behavior.


2.2 Key Bindings
────────────────

  Example key bindings:

  ┌────
  │ (global-set-key (kbd "C-c +") 'evil-numbers/inc-at-pt)
  │ (global-set-key (kbd "C-c -") 'evil-numbers/dec-at-pt)
  │ (global-set-key (kbd "C-c C-+") 'evil-numbers/inc-at-pt-incremental)
  │ (global-set-key (kbd "C-c C--") 'evil-numbers/dec-at-pt-incremental)
  └────

  or only in evil's `normal' & `visual' states:

  ┌────
  │ (evil-define-key '(normal visual) 'global (kbd "C-c +") 'evil-numbers/inc-at-pt)
  │ (evil-define-key '(normal visual) 'global (kbd "C-c -") 'evil-numbers/dec-at-pt)
  │ (evil-define-key '(normal visual) 'global (kbd "C-c C-+") 'evil-numbers/inc-at-pt-incremental)
  │ (evil-define-key '(normal visual) 'global (kbd "C-c C--") 'evil-numbers/dec-at-pt-incremental)
  └────

  Keypad `+' and `-' present an alternative that can be directly bound
  without shadowing the regular `+' and `-':

  ┌────
  │ (evil-define-key '(normal visual) 'global (kbd "<kp-add>") 'evil-numbers/inc-at-pt)
  │ (evil-define-key '(normal visual) 'global (kbd "<kp-subtract>") 'evil-numbers/dec-at-pt)
  │ (evil-define-key '(normal visual) 'global (kbd "C-<kp-add>") 'evil-numbers/inc-at-pt-incremental)
  │ (evil-define-key '(normal visual) 'global (kbd "C-<kp-subtract>") 'evil-numbers/dec-at-pt-incremental)
  └────


3 Install
═════════

3.1 Basic Installation
──────────────────────

  Put in `load-path', `(require 'evil-numbers)' and set key bindings.


3.2 Use Package
───────────────

  Assuming you have the `melpa' repository enabled, `use-package' can be
  used as follows.

  ┌────
  │ (use-package evil-numbers)
  └────


4 Known Bugs
════════════

  See <http://github.com/juliapath/evil-numbers/issues>


5 Similar Packages
══════════════════

  • [Mouse Slider Package]
  • [Number Package]
  • [Shift Number Package]
  • [Emacs Wiki (Increment Number)]


[Mouse Slider Package] <https://melpa.org/#/mouse-slider-mode>

[Number Package] <https://melpa.org/#/number>

[Shift Number Package] <https://melpa.org/#/shift-number>

[Emacs Wiki (Increment Number)]
<https://www.emacswiki.org/emacs/IncrementNumber>


6 Contributors
══════════════

  • Matthew Fidler <matthew.fidler@gmail.com>
  • Michael Markert <markert.michael@gmail.com>
  • Julia Path <julia@jpath.de>
  • Campbell Barton <ideasman42@gmail.com>
