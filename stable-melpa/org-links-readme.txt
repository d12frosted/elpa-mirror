*About*:
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
(add-hook 'org-open-link-functions #'org-links-fix-open-target-not-org)
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
We provide new function `org-links-store-extended' that use
 standard ol.el function and we add additional format for
 programming modes.

For opening links we add hook to org-execute-file-search-functions
 that called from `org-link-search' function, used by Org function
 for oppening files: `org-open-at-point' (that bound to C-c C-o by
 default in Org mode.)  and `org-open-at-point-global'.

Other packages:
- Modern navigation in major modes https://github.com/Anoncheg1/firstly-search
- Search with Mandarin Chinese pinying https://github.com/Anoncheg1/pinyin-isearch
- Ediff fix			https://github.com/Anoncheg1/ediffnw
- Dired history		https://github.com/Anoncheg1/dired-hist
- Mark window with contrast https://github.com/Anoncheg1/selected-window-contrast
- Org hyperlinks enhanced	https://github.com/Anoncheg1/org-links
- Solution for "callback hell"	 https://github.com/Anoncheg1/emacs-async1
- Call LLMs & AIfrom Org-mode block.  https://github.com/Anoncheg1/emacs-oai

*DONATE MONEY* to sponsor author directly with crypto currencies:
- BTC (Bitcoin) address: 1CcDWSQ2vgqv5LxZuWaHGW52B9fkT5io25
- USDT (Tether) address: TVoXfYMkVYLnQZV3mGZ6GvmumuBfGsZzsN
- TON (Telegram) address: UQC8rjJFCHQkfdp7KmCkTZCb5dGzLFYe2TzsiZpfsnyTFt9D
