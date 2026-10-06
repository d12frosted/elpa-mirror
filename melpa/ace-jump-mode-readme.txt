; INTRODUCTION


What's this?

It is a minor mode for Emacs.  It can help you to move your cursor
to ANY position in Emacs by using only 3 times key press.

Where does ace jump mode come from ?

I firstly see such kind of moving style is in a vim plugin called
EasyMotion.  It really attract me a lot.  So I decide to write
one for Emacs and MAKE IT BETTER.

So I want to thank to :
        Bartlomiej P.   for his PreciseJump
        Kim Silkebækken for his EasyMotion


What's ace-jump-mode ?

ace-jump-mode is an fast/direct cursor location minor mode.  It will
create the N-Branch search tree internal and marks all the possible
position with predefined keys in within the whole Emacs view.
Allowing you to move to the character/word/line almost directly.


; Usage

Bind the commands to keys of your choice, for instance:

  (use-package ace-jump-mode
    :bind (("M-a" . ace-jump-mode)       ; instead of `backward-sentence'
           ("C-c M-a" . ace-jump-mode-pop-mark))
    :config
    (ace-jump-mode-enable-mark-sync))

M-a asks for the first character of a word and labels the words in
view that start with it: type a label to jump there.  RET instead of
a character labels the lines.  C-u M-a does the same for any
character, C-u C-u M-a for the lines, and C-c M-a jumps back.

If you use evil or viper:

  (define-key evil-normal-state-map (kbd "SPC") 'ace-jump-mode)
  (define-key viper-vi-global-user-map (kbd "SPC") 'ace-jump-mode)

M-x customize-group RET ace-jump RET lists the options.

; For more information
README: https://github.com/winterTTr/ace-jump-mode
FAQ   : https://github.com/winterTTr/ace-jump-mode/wiki/AceJump-FAQ
