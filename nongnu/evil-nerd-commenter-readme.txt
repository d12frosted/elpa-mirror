1 evil-nerd-commenter
═════════════════════

  [https://github.com/redguardtoo/evil-nerd-commenter/actions/workflows/test.yml/badge.svg]
  [file:https://elpa.nongnu.org/nongnu/evil-nerd-commenter.svg]
  [file:http://melpa.org/packages/evil-nerd-commenter-badge.svg]
  [file:http://stable.melpa.org/packages/evil-nerd-commenter-badge.svg]

  This program can be used *WITHOUT* [evil-mode]!

  A [Nerd Commenter] emulation, help you comment code efficiently. For
  example, you can press "99,ci" to comment out 99 lines.

  I recommend using it with Evil though Evil is optional.

  Tested on Emacs 25, 26, 27, 28


[https://github.com/redguardtoo/evil-nerd-commenter/actions/workflows/test.yml/badge.svg]
<https://github.com/redguardtoo/evil-nerd-commenter/actions/workflows/test.yml>

[file:https://elpa.nongnu.org/nongnu/evil-nerd-commenter.svg]
<https://elpa.nongnu.org/nongnu/evil-nerd-commenter.html>

[file:http://melpa.org/packages/evil-nerd-commenter-badge.svg]
<http://melpa.org/#/evil-nerd-commenter>

[file:http://stable.melpa.org/packages/evil-nerd-commenter-badge.svg]
<http://stable.melpa.org/#/evil-nerd-commenter>

[evil-mode] <https://www.emacswiki.org/emacs/Evil>

[Nerd Commenter] <http://www.vim.org/scripts/script.php?script_id=1218>


2 Why?
══════

2.1 A simple use case on the efficiency
───────────────────────────────────────

  The old way to comment out 9 lines is `C-space M-9 C-n M-;' ("M-;" is
  the default key binding of `comment-dwim'.

  With this package's help, you can press "M-9 M-;" or ",,9j" or "9,ci"
  instead. It's much faster because you donot need mark any text first!

  demo:

  <https://raw.github.com/redguardtoo/evil-nerd-commenter/master/evil-nerd-commenter-demo.gif>


2.2 It fixes Emacs bug for you
──────────────────────────────

  Long-term support is provided for *ANY programming language*. Here is
  an example to fix [a bug in autoconf.el].


[a bug in autoconf.el]
<https://github.com/redguardtoo/evil-nerd-commenter/issues/3>


2.3 Perfect integration with org-mode
─────────────────────────────────────

  The code snippet embedded in org file is automatically detected and
  *correct* comment syntax will be used!


3 Install
═════════

  This package is already uploaded to <http://melpa.org>. The best way
  to install is Emacs package manager.


4 Setup
═══════

  Please note NO key bindings are setup automatically. You need use
  following ways to setup key bindings.

  Please note v3.2.1 is the last version supporting Emacs 24.3.


4.1 Use recommended key bindings
────────────────────────────────

  Insert `(evilnc-default-hotkeys)' into `~/.emacs' to use key bindings
  preset for both evil and non-evil mode. This is recommended way.

  Use `(evilnc-default-hotkeys t)' to use key binding only for non-evil
  mode if you want to define key bindings in evil-mode by yourself.

  Use `(evilnc-default-hotkeys nil t)' to use key binding only for evil
  mode if you want to define key bindings in Emacs mode by yourself.

  You can also use third party package [general.el] instead of calling
  `evilnc-default-hotkeys'.


[general.el] <https://github.com/noctuid/general.el>


4.2 Assign key bindings manually
────────────────────────────────

  Manual setup is necessary for certain major modes (matlab-mode, for
  example)

  Here is the minimum setup,
  ┌────
  │ (defun matlab-mode-hook-config ()
  │   (local-set-key (kbd "M-;") 'evilnc-comment-or-uncomment-lines))
  │ (add-hook 'matlab-mode-hook 'matlab-mode-hook-config)
  └────


5 Usage
═══════

5.1 Commands and hotkeys
────────────────────────

  Here are available commands which are NOT dependent on [evil-mode]:


[evil-mode] <http://emacswiki.org/emacs/Evil>

5.1.1 evilnc-comment-or-uncomment-lines (RECOMMENDED)
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Comment/uncomment lines. This command supports negative arguments.

  The hotkey is ",cl" in evil-mode and "M-;" in all modes. "M" means ALT
  key.

  If a region selected, the region is expand to make sure the region
  contain whole lines. Then we comment/uncomment the expanded
  region. NUM is ignored.

  If the region is inside of ONE line, we comment/uncomment that
  region. In this case, CORRECT comment syntax will be used for
  C++/Java/Javascript.

  This may be the *only command* you need to learn!


5.1.2 evilnc-quick-comment-or-uncomment-to-the-line
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  comment/uncomment from current line to the user-specified line. You
  can input the rightest digit(s) to specify the line number if you want
  to type less.

  For example, say current line number is 497. `C-u 3 M-x
  evilnc-quick-comment-or-uncomment-to-the-line' will comment to the
  line 503 because the rightest digit of "503" is 3.

  The hotkey is ",cl" or ",ll" in evil-mode and `C-c l' (C means Ctrl
  key) in emacs normal mode.


5.1.3 evilnc-comment-or-uncomment-paragraphs
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  comment/uncomment paragraphs which is separated by empty lines.


5.1.4 evilnc-copy-and-comment-lines
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Copy and paste lines, then comment out original lines. This command
  supports negative arguments.

  The hotkey is ",cc" in evil-mode and `C-c c' in emacs normal mode.


5.1.5 evilnc-comment-and-kill-ring-save
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Comment lines and insert original lines into `kill-ring'.


5.1.6 evilnc-comment-or-uncomment-to-the-line
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Comment to the specified line.


5.1.7 evilnc-comment-or-uncomment-html-tag
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Comment or uncomment current html tag or selected region.

  It supports html and jsx without any set up. It's not dependent on any
  third party package.

  Please note you don't need force the whole line selection (pressing
  `V') in `evil-mode'. This command is smart to select whole lines if
  needed.

  Comment or uncomment html tag(s).

  If no region is selected, current tag under focus is automatically
  selected.  In this case, only one tag is selected.

  If user manually selects region, the region could cross multiple
  sibling tags and automatically expands to include complete tags. So
  user only need press `v' key in `evil-mode' to select multiple tags.

  Or you can use `evilnc-comment-or-uncomment-html-paragraphs' to
  comment/uncomment paragraphs containing html tags.

  Paragraph is text separated by empty lines.

  Sample to combine `evilnc-comment-or-uncomment-html-paragraphs' and
  `evilnc-comment-or-uncomment-paragraphs':
  ┌────
  │ (defun my-current-line-html-p (paragraph-region)
  │   (let* ((line (buffer-substring-no-properties (line-beginning-position)
  │ 					       (line-end-position)))
  │ 	 (re (format "^[ \t]*\\(%s\\)?[ \t]*</?[a-zA-Z]+"
  │ 		     (regexp-quote (evilnc-html-comment-start)))))
  │     ;; current paragraph does contain html tag
  │     (if (and (>= (point) (car paragraph-region))
  │ 	     (string-match-p re line))
  │ 	t)))
  │ 
  │ (defun my-evilnc-comment-or-uncomment-paragraphs (&optional num)
  │   "Comment or uncomment NUM paragraphs which might contain html tags."
  │   (interactive "p")
  │   (unless (featurep 'evil-nerd-commenter) (require 'evil-nerd-commenter))
  │   (let* ((paragraph-region (evilnc--get-one-paragraph-region))
  │ 	 (html-p (or (save-excursion
  │ 		       (sgml-skip-tag-backward 1)
  │ 		       (my-current-line-html-p paragraph-region))
  │ 		     (save-excursion
  │ 		       (sgml-skip-tag-forward 1)
  │ 		       (my-current-line-html-p paragraph-region)))))
  │     (if html-p (evilnc-comment-or-uncomment-html-paragraphs num)
  │       (evilnc-comment-or-uncomment-paragraphs num))))
  └────


5.1.8 evilnc-toggle-comment-empty-lines
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Toggle the flag to comment/uncomment empty lines.

  The hotkey is ",cv" in evil-mode.


5.1.9 evilnc-copy-to-line
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Copy from the current line to the user-specified line.

  It's *for non-evil user only*.

  You need assign hotkey for it.

  For example:
  ┌────
  │ (global-set-key (kbd "C-c C-t C-l") 'evilnc-copy-to-line)
  └────


5.1.10 evilnc-toggle-invert-comment-line-by-line
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Toggle flag `evilnc-invert-comment-line-by-line'.

  When the flag is true, the command
  `evilnc-comment-or-uncomment-lines',
  `evilnc-comment-or-uncomment-to-the-line', and
  `evilnc-comment-or-uncomment-paragraphs' will be influenced. They will
  *invert* each line's comment status instead comment the whole thing.

  Please note this command may NOT work on complex evil text object.


5.1.11 evilnc-kill-to-line
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Kill from the current line to the user-specified line.

  It's *for non-evil user only*.

  You need assign hotkey for it.

  For example:
  ┌────
  │ (global-set-key (kbd "C-c C-t C-l") 'evilnc-kill-to-line)
  └────


5.1.12 evilnc-comment-both-snippet-html
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  If a line is snippet wrapped HTML tags in HTML template, only the HTML
  syntax is used to comment out the line by default.

  But if you `(setq evilnc-comment-both-snippet-html t)', snippet will
  be commented out with its own syntax at first. Then the wrapped html
  tag will be comment out using HTML syntax. This flag has effect on all
  above commands.  [Web-mode] should be enabled to use this flag.


[Web-mode] <http://web-mode.org/>


5.1.13 evilnc-comment-box
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Comment out N lines, putting it inside a box. N could be negative. If
  N is nil, comment out current paragraph.  This command uses builtin
  API `comment-box'.

  The hotkey is ",cs" in evil-mode


5.1.14 Use imenu to list and jump to comments in current file
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Please setup `imenu-create-index-function' to
  `evilnc-imenu-create-index-function'.

  Setup on using `counsel-imenu' to list comments in current buffer,
  ┌────
  │ (defun counsel-imenu-comments ()
  │   (interactive)
  │   (let* ((imenu-create-index-function 'evilnc-imenu-create-index-function))
  │     (unless (featurep 'counsel) (require 'counsel))
  │     (counsel-imenu)))
  └────


5.2 Examples
────────────

5.2.1 Comment lines
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  `C-u NUM M-x evilnc-comment-or-uncomment-lines', comment/uncomment
  next NUM lines.


5.2.2 Comment region
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Select a region and `M-x evilnc-comment-or-uncomment-lines'. The
  region will be *automatically expanded to contain whole lines*. Then
  we comment/uncomment the region.


5.2.3 Comment to the line number
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  `C-u 56 M-x evilnc-comment-or-uncomment-to-the-line',
  comment/uncomment *from current line* to line 56.


5.2.4 Copy and comment
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  `C-u 2 M-x evilnc-copy-and-comment-lines', copy 2 lines and paste them
  below the original line. Then comment out original lines. The focus
  will be moved to the new lines.


5.2.5 Comment paragraph
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  `C-u 2 M-x evilnc-comment-or-uncomment-paragraphs', comment out two
  paragraphs. This is useful if you have large hunk of data to be
  commented out as below:
  ┌────
  │ var myJson={
  │   "key1":"v1",
  │   "key2":"v2",
  │   "key3":"v3"
  │ }
  └────


5.2.6 Invert comment
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Say there are two lines of javascript code,
  ┌────
  │ if(flag==true){ doSomething(); }
  │ //if(flag==false){ doSomething(); }
  └────
  The first line is production code. The second line is your debug
  code. You want to invert the comment status of these two lines (for
  example, comment out first line and uncomment the second line) for
  debug purpose.

  All you need to is `M-x evilnc-toggle-invert-comment-line-by-line'
  then `C-u 2 evilnc-comment-or-uncomment-lines'. The first command turn
  on some flag, so the behavior of (un)commenting is different.


6 Evil usage
════════════

  If you use [Evil], you can use [text objects and motions]. But if you
  only *deals with lines*, I suggest using
  `evilnc-comment-or-uncomment-lines' instead.


[Evil] <http://emacswiki.org/emacs/Evil>

[text objects and motions]
<http://vimdoc.sourceforge.net/htmldoc/motion.html#text-objects>

6.1 commenter text object "c"
─────────────────────────────

  We defined commenter text object "c" which can have *multi-lines*.

  Press `vac' to select outer object (comment with limiters).

  Press `vic' to select inner object (comment without limiter).

  The comment text object is created automatically in
  `evilnc-default-hotkeys'.

  You can assign other key instead of "c" to the text object by changing
  `evilnc-comment-text-object'.
  ┌────
  │ (setq evilnc-comment-text-object "c")
  │ (evilnc-default-hotkeys)
  └────

  You can also manually created the comment text object using below
  code,
  ┌────
  │ (setq evilnc-comment-text-object "a")
  │ (define-key evil-inner-text-objects-map evilnc-comment-text-object 'evilnc-inner-commenter)
  │ (define-key evil-outer-text-objects-map evilnc-comment-text-object 'evilnc-outer-commenter)
  └────


6.2 evilnc-comment-operator
───────────────────────────

  `evilnc-comment-operator' acts much like the delete/change
  operator. Takes a motion or text object and comments it out, yanking
  its content in the process.

  Example 1: ",,," to comment out the current line.

  Example 2: ",,9j" to comment out the next 9 lines.

  Example 3: ",,99G" to comment from the current line to line 99.

  Example 4: ",,a(" to comment out the current s-expression, or ",,i("
  to only comment out the s-expression's content.  Similarly for blocks
  ",,a{", etc.

  Example 5: ",,ao" to comment out the current symbol, or ",,aW" to
  comment out the current WORD.  Could be useful when commenting out
  function parameters, for instance.

  Example 6: ",,w" comment to the beginning of the next word, ",,e" to
  the end of the next word, ",,b" to the beginning of the previous word.

  Example 7: ",,it", comment the region inside html tags (all html major
  modes are supported , *including [web-mode]*)


[web-mode] <http://web-mode.org/>


6.3 evilnc-copy-and-comment-operator
────────────────────────────────────

  `evilnc-copy-and-comment-operator' is another evil-mode
  operator. Instead of commenting out the text in the operator-range, it
  inserts an copy of the text in the range and comments out that
  copy. Its hot key is ",.". For example, ",.," to comment out the
  current line.


6.4 evilnc-yank-and-comment-operator
────────────────────────────────────

  Operator to comment or uncomment the text and yank the original text
  at the same time.


7 Tips
══════

7.1 Yank in evil-mode
─────────────────────

  You can yank to line 99 using hotkey `y99G' or `y99gg'. That's the
  feature from evil-mode.

  Please read vim manual on "text objects and motions".


7.2 Change comment style
────────────────────────

  For example, if you prefer double slashes `//' instead of slash-stars
  `/* ... */' in `c-mode', insert below code into your `~/.emacs':
  ┌────
  │ (add-hook 'c-mode-common-hook
  │   (lambda ()
  │     ;; Preferred comment style
  │     (setq comment-start "// "
  │ 	  comment-end "")))
  └────

  Thanks for [Andrew Pennebaker (aka mcandre)] providing this tip.


[Andrew Pennebaker (aka mcandre)] <https://github.com/mcandre>


7.3 Comment code snippet
────────────────────────

  Please install [evil-matchit]. You can press `vi=%' to select a region
  between tags and press `M-;' to comment the region.

  Most popular programming languages are supported.


[evil-matchit] <https://github.com/redguardtoo/evil-matchit>


7.4 Comment and uncomment Lisp code
───────────────────────────────────

  • Make sure Evil installed
  • Press ",,a("


7.5 Choose the style of copy and comment
────────────────────────────────────────

  You can set up `evilnc-original-above-comment-when-copy-and-comment'
  to decide which style to use when `evilnc-copy-and-comment-lines' or
  `evilnc-copy-and-comment-operator',
  • Place the commented out text above original text
  • Or place the original text above commented out text


7.6 Customize comment style
───────────────────────────

  Most commands call `evilnc-comment-or-uncomment-region-function'.

  You can modify this variable to customize the comment style.

  ┌────
  │ (with-eval-after-load 'evil-nerd-commenter
  │   (defun my-comment-or-uncomment-region (beg end)
  │     (let* ((comment-start "aaa")
  │ 	   (comment-end "bbb"))
  │       (evilnc-comment-or-uncomment-region-internal beg end)))
  │   (setq evilnc-comment-or-uncomment-region-function
  │ 	'my-comment-or-uncomment-region))
  └────


8 Credits
═════════

  • [Lally Oppenheimer (AKA lalopmak)] added the support for text-object
    in Evil
  • [Tom Willemse (AKA ryuslash)] provided the fix to make Emacs 24.4
    work
  • [Eivind Fonn (AKA TheBB)] fixed the web-mode issue #45
  • [Dickby] provided `evilnc-copy-and-comment-operator'


[Lally Oppenheimer (AKA lalopmak)] <https://github.com/lalopmak>

[Tom Willemse (AKA ryuslash)] <https://github.com/ryuslash>

[Eivind Fonn (AKA TheBB)] <https://github.com/TheBB>

[Dickby] <https://github.com/Dickby>


9 Contact me
════════════

  Report bug at <https://github.com/redguardtoo/evil-nerd-commenter>.
