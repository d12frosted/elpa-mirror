                       ━━━━━━━━━━━━━━━━━━━━━━━━━
                        EAT: EMULATE A TERMINAL
                       ━━━━━━━━━━━━━━━━━━━━━━━━━


Eat's name self-explanatory, it stands for "Emulate A Terminal".  Eat is
a terminal emulator.  It can run most (if not all) full-screen terminal
programs, including Emacs.

It is pretty fast, more than three times faster than Term, despite being
implemented entirely in Emacs Lisp.  So fast that you can comfortably
run Emacs inside Eat, or even use your Emacs as a terminal multiplexer.

It has many features that other Emacs terminal emulator still don't
have, for example Sixel support, complete mouse support, shell
integration, etc.

It flickers less than other Emacs terminal emulator, so you get more
performance and a smoother experience.

To get the most out of Eat, you should also setup shell integration.


1 Usage
═══════

  To start Eat, run `M-x eat'.  Eat has four input modes:

  • "semi-char" mode: This is the default input mode.  Most keys are
    bound to send the key to the terminal, except the following keys:
    `C-\', `C-c', `C-x', `C-g', `C-h', `C-M-c', `C-u', `C-q', `M-x',
    `M-:', `M-!', `M-&' and some other keys (see the user option
    `eat-semi-char-non-bound-keys' for the complete list).  The
    following special keybinding are available:

    • `C-q': Send next key to the terminal.
    • `C-y': Like `yank', but send the text to the terminal.
    • `M-y': Like `yank-pop', but send the text to the terminal.
    • `C-c C-k': Kill process.
    • `C-c C-e': Switch to "emacs" input mode.
    • `C-c M-d': Switch to "char" input mode.
    • `C-c C-l': Switch to "line" input mode.

  • "emacs" mode: No special keybinding, except the following:

    • `C-c C-j': Switch to "semi-char" input mode.
    • `C-c M-d': Switch to "char" input mode.
    • `C-c C-l': Switch to "line" input mode.
    • `C-c C-k': Kill process.

  • "char" mode: All supported keys are bound to send the key to the
    terminal, except `C-M-m' or `M-RET', which is bound to switch to
    "semi-char" input mode.

  • "line" mode: Similar to Comint, Shell mode and Term line mode.  In
    this input mode, terminal input is sent one line at once, and you
    can edit input line using the usual Emacs commands.

    • `C-c C-e': Switch to "emacs" input mode
    • `C-c C-j': Switch to "semi-char" input mode.
    • `C-c M-d': Switch to "char" input mode.

  If you like Eshell, then there is a good news for you.  Eat integrates
  with Eshell.  Eat has two global minor modes for Eshell:

  • `eat-eshell-visual-command-mode': Run visual commands with Eat
    instead of Term.

  • `eat-eshell-mode': Run Eat inside Eshell.  After enabling this, you
    can run full-screen terminal programs directly in Eshell.  You have
    the above input modes here too, except line mode and that `C-c C-k'
    is not special (i.e. not bound by Eat) in "emacs" mode and "line"
    mode.

  You can add any of these to `eshell-load-hook' like the following:

  ┌────
  │ ;; For `eat-eshell-mode'.
  │ (add-hook 'eshell-load-hook #'eat-eshell-mode)
  │ 
  │ ;; For `eat-eshell-visual-command-mode'.
  │ (add-hook 'eshell-load-hook #'eat-eshell-visual-command-mode)
  └────

  To setup shell integration for GNU Bash, put the following at the end
  of your `.bashrc':

  #+begin_src sh [ -n "$EAT_SHELL_INTEGRATION_DIR" ] && \ source
  "$EAT_SHELL_INTEGRATION_DIR/bash" #+end_src sh

  For Zsh, put the following in your `.zshrc':

  #+begin_src sh [ -n "$EAT_SHELL_INTEGRATION_DIR" ] && \ source
  "$EAT_SHELL_INTEGRATION_DIR/zsh" #+end_src sh

  There's a Info manual available with much more information, which can
  be accessed with `C-h i m Eat', also available [here on the internet].


[here on the internet]
<https://elpa.nongnu.org/nongnu-devel/doc/eat.html>


2 Installation
══════════════

  Eat requires at least Emacs 26.1 or above.


2.1 NonGNU ELPA
───────────────

  Eat is available on NonGNU ELPA.  So you can just do `M-x
  package-install RET eat RET'.

  If you're on Emacs 27 or earlier, you'll need to add NonGNU ELPA to
  your `package-archives' by putting the following in your `init.el':

  ┌────
  │ (add-to-list 'package-archives
  │ 	     '("nongnu" . "https://elpa.nongnu.org/nongnu/"))
  └────


2.2 Quelpa
──────────

  ┌────
  │ (quelpa '(eat :fetcher git
  │ 	      :url "https://codeberg.org/akib/emacs-eat"
  │ 	      :files ("*.el" ("term" "term/*.el") "*.texi"
  │ 		      "*.ti" ("terminfo/e" "terminfo/e/*")
  │ 		      ("terminfo/65" "terminfo/65/*")
  │ 		      ("integration" "integration/*")
  │ 		      (:exclude ".dir-locals.el" "*-tests.el"))))
  └────


2.3 Straight.el
───────────────

  ┌────
  │ (straight-use-package
  │  '(eat :type git
  │        :host codeberg
  │        :repo "akib/emacs-eat"
  │        :files ("*.el" ("term" "term/*.el") "*.texi"
  │ 	       "*.ti" ("terminfo/e" "terminfo/e/*")
  │ 	       ("terminfo/65" "terminfo/65/*")
  │ 	       ("integration" "integration/*")
  │ 	       (:exclude ".dir-locals.el" "*-tests.el"))))
  └────


2.4 Manual
──────────

  Clone the repository and put it in your `load-path'.


3 Comparison With Other Terminal Emulators
══════════════════════════════════════════

3.1 Term
────────

  Term is the Emacs built-in terminal emulator.  Its terminal emulation
  is pretty good too.  But it's slow.  It is so slow that Eat can beat
  native-compiled Term even without byte-compilation, and when Eat is
  byte-compiled, Eat is more than three times fast.  Also, Term
  flickers, just try to run `emacs -nw' in it.  It doesn't support
  remote connections, for example over Tramp.  However, it's builtin
  from the early days of Emacs, while Eat needs atleast Emacs 26.1.


3.2 Vterm
─────────

  Vterm is powered by a C library, libvterm.  For this reason, it can
  process huge amount of text quickly.  It is about 1.5 times faster
  than Eat (byte-compiled or native-compiled) (and about 2.75 faster
  then Eat without byte-compilation).  But it doesn't have a char mode
  (however you can make a char mode by putting some effort).  And it too
  flickers like Term, so despite being much faster that Eat, it seems to
  be slow.  If you need your terminal to handle huge bursts (megabytes)
  of data, you should use Vterm.


3.3 Coterm + Shell
──────────────────

  Coterm adds terminal emulation to Shell mode.  Although the terminal
  Coterm emulates is same as Term, it is much faster, about three times,
  just a bit slow than Eat.  However, it too flickers like other
  terminals.  Since it's an upgrade to Shell, you get all the features
  of Shell like "line" mode, completion using your favorite completion
  UI (Company, Corfu, etc), etc.  Most of these features are available
  in Eat, and also in Eat-Eshell-Mode as Eshell is similar to Shell,
  however it's not Shell mode.  Recommended if you like Shell.


4 Acknowledgements
══════════════════

  This wouldn't have been possible if the following awesome softwares
  didn't exist:

  • [GNU Operating System]
  • [St]
  • [Kitty]
  • [XTerm]
  • [Linux-libre]
  • [Term]
  • [Coterm]
  • [Shell]
  • [Vterm]
  • [Eshell]
  • Numerous terminal programs
  • And obviously, [GNU Emacs]


[GNU Operating System] <https://gnu.org>

[St] <https://st.suckless.org/>

[Kitty] <https://sw.kovidgoyal.net/kitty/>

[XTerm] <https://invisible-island.net/xterm/>

[Linux-libre] <https://www.gnu.org/software/linux-libre/>

[Term]
<https://www.gnu.org/software/emacs/manual/html_node/emacs/Terminal-emulator.html>

[Coterm] <https://repo.or.cz/emacs-coterm.git>

[Shell]
<https://www.gnu.org/software/emacs/manual/html_node/emacs/Interactive-Shell.html>

[Vterm] <https://github.com/akermu/emacs-libvterm>

[Eshell]
<https://www.gnu.org/software/emacs/manual/html_node/eshell/index.html>

[GNU Emacs] <https://www.gnu.org/software/emacs/>
