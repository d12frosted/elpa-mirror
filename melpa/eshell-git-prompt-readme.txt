This package provides some themes of Emacs Shell (Eshell) prompt.

Usage:
In Eshell, type ~use-theme~ to list and preview available themes, then
type ~use-theme name~ to choose a theme.

You can also choose a theme in your init file by using
~eshell-git-prompt-use-theme~, then Eshell will use theme at the
startup. For example, put the following in you init file

TODO
- [ ] For `eshell-prompt-regexp' hack, replace '$' with '' ('\x06')
- [ ] Make it easier to make new theme (that is, improve API)
- [ ] Test with recent version Emacs and in text-base Emacs

Note
1 You must kill all Eshell buffers and re-enter Eshell to make your new
  prompt take effect.
2 You must set `eshell-prompt-regexp' to FULLY match your Eshell prompt,
  sometimes it is impossible, especially when you don't want use any special
  characters (e.g., '$') to state the end of your Eshell prompt
3 If you set `eshell-prompt-function' or `eshell-prompt-regexp' incorrectly,
  Eshell may crashes, if it happens, you can M-x `eshell-git-prompt-use-theme'
  to revert to the default Eshell prompt, then read Note #1.
