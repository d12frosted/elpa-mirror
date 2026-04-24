This package (org-links) provides facilities to help create and
 manage Org-mode links, add new link types, have speed optimization
 for large files.  Have facility to message if two lines was found,
 control wheter to search for full line or by the begining of it.

org-mode supports  file links  with line numbers  and line  via the
 following syntax:
[[PATH::NUM][Link description]]
[[PATH::LINE][Link description]]

This package (org-links) The syntax above is extended with
 following formats and facilities provided to help create and
 manage them all.
- [[PATH::NUM::LINE]]
- [[PATH::NUM-NUM::LINE]]
- [[PATH::NUM-NUM]]

For ex.  `[[file:./notes/warehouse.el::23::(defun alina (pic))]]`

Known issue: Org export not working properly with new formats.

[[::LINE]] is equal to [[LINE]]

Also provided:
1) The command `org-links-store-extended' copies a link to the
   current file, at the current point.
2) A helpful warning is triggered when a link has an ambiguous target
   (e.g., in the case where two targets are found).

Why? Allow to point more flexible to use links with AI.

How  [[PATH::NUM::LINE]] links works?
  First, we search for LINE, if not found we use NUM line number.

[[NUM-NUM]] - used for region selection.

Also, Emacs have `find-file-at-point` functions globally (ffap.el)
to follow PATHs.

*Configuration*:
(require 'org-links)
(add-hook 'org-execute-file-search-functions #'org-links-additional-formats)
(advice-add 'org-open-file :around #'org-links-org-open-file-advice)
(global-set-key (kbd "C-c w") #'org-links-store-extended)

You may advanced configuration in README.md file.

*Features provided*:
- respect org-link-context-for-files, if not set store only number.
- correctly store file in image-dired-thumbnail-mode
- Add support for image-dired-thumbnail-mode and image-dired-image-mode
- fuzzy search by the begining of ::LINE, not full match

I recommend to set those Org ol.el options for clarity:
(setopt org-link-file-path-type 'absolute) ; create links with full path
(setopt org-link-search-must-match-exact-headline nil) ; fuzzy search
(setopt org-link-descriptive nil) ; show links in raw, don't hide

*How this works*:
Provided new function `org-links-store-extended' to create and copy
 link to clipboard kill-ring and we add advices and hooks to handle
 opeing of new links types.

For opening links we add hook to org-execute-file-search-functions
 that called from `org-link-search' function, used by Org function
 for oppening files: `org-open-at-point' (that bound to C-c C-o by
 default in Org mode.)  and `org-open-at-point-global'.

Other packages:
- Modern navigation in major modes https://github.com/Anoncheg1/firstly-search
- Search with Chinese	https://github.com/Anoncheg1/pinyin-isearch
- Ediff no 3-th window	https://github.com/Anoncheg1/ediffnw
- Dired history		https://github.com/Anoncheg1/dired-hist
- Selected window contrast	https://github.com/Anoncheg1/selected-window-contrast
- Copy link to clipboard	https://github.com/Anoncheg1/emacs-org-links
- Solution for "callback hell"	https://github.com/Anoncheg1/emacs-async1
- Restore buffer state	https://github.com/Anoncheg1/emacs-unmodified-buffer1
- outline.el usage		https://github.com/Anoncheg1/emacs-outline-it
- ai_block for Org mode for chat.  https://github.com/Anoncheg1/emacs-oai

*DONATE MONEY* to sponsor author directly with crypto currencies:
- BTC (Bitcoin) address: 1CcDWSQ2vgqv5LxZuWaHGW52B9fkT5io25
- USDT (Tether) address: TVoXfYMkVYLnQZV3mGZ6GvmumuBfGsZzsN
- TON (Telegram) address: UQC8rjJFCHQkfdp7KmCkTZCb5dGzLFYe2TzsiZpfsnyTFt9D
