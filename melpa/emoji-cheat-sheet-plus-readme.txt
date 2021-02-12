This is an improved and somewhat rewritten version of
`emacs-emoji-cheat-sheet' from Shingo Fukuyama

Features available only in this version are:
- emoji buffer has its own major-mode
- automatic display of emoji code in the minibuffer while browsing the
  emoji buffer
- new minor mode `emoji-cheat-sheet-plus-display-mode' which replaces
  emoji codes in buffer by the corresponding image
- new function `emoji-cheat-sheet-plus-insert' to insert an emoji at point
  using an helm front-end. It is possible to insert several emoji with helm
  persistent action mechanism or multiple selection.

This version is stand-alone and does not require the original package
`emacs-emoji-cheat-sheet'.

Configuration
(add-to-list 'load-path "/path/to/emacs-emoji-cheat-sheet-plus")
(require 'emoji-cheat-sheet-plus)


Notices

Images are from arvida/emoji-cheat-sheet.com
https://github.com/arvida/emoji-cheat-sheet.com

octocat, squirrel, shipit
Copyright (c) 2012 GitHub Inc. All rights reserved.
bowtie
Copyright (c) 2012 37signals, LLC. All rights reserved.
neckbeard
Copyright (c) 2012 Jamie Dihiansan. Creative Commons Attribution 3.0 Unported
feelsgood, finnadie, goberserk, godmode, hurtrealbad, rage 1-4, suspect
Copyright (c) 2012 id Software. All rights reserved.
trollface
Copyright (c) 2012 whynne@deviantart. All rights reserved.
All other emoji images
Copyright (c) 2012 Apple Inc. All rights reserved.
