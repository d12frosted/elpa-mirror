This is a clone of the popular easymotion package for vim, which
describes itself in these terms:

> EasyMotion provides a much simpler way to use some motions in vim.
> It takes the <number> out of <number>w or <number>f{char} by
> highlighting all possible choices and allowing you to press one key
> to jump directly to the target.

If you're having trouble picturing this, please visit the github repo
for a screencast.

Usage/status
============

evil-easymotion, rather unsurprisingly can use evil. However, you don't
_need_ evil to use it. evil-easymotion can happily define motions for
regular emacs commands. With that said, evil is recommended, not
least because it's awesome.

Currently most motions are supported, and it's easy to define your own easymotions.

  (evilem-define (kbd "SPC w") 'evil-forward-word-begin)

To define easymotions for all motions that evil defines by default, add

  (evilem-default-keybindings "SPC")

This binds all motions under the prefix `SPC` in `evil-motion-state-map`. This is not done by default for motions defined manually. You will need to supply the prefix.

More advanced use-cases are detailed in the github README.
