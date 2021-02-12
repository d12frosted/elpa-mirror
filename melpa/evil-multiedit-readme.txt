
This plugin was an answer to the lack of proper multiple cursor support in
Emacs+evil. It allows you to select and edit matches interactively,
integrating `iedit-mode' into evil-mode with an attempt at sensible defaults.

Since then, [evil-mc] has matured, and now that I use both I've found they
can coexist, filling different niches, complimenting evil's built-in
column/line-wise editing operations.

; Usage

Evil-multiedit does not automatically bind any keys. Call
`evil-multiedit-default-keybinds' to bind my recommended configuration:

  ;; Highlights all matches of the selection in the buffer.
  (define-key evil-visual-state-map "R" 'evil-multiedit-match-all)

  ;; Match the word under cursor (i.e. make it an edit region). Consecutive presses will
  ;; incrementally add the next unmatched match.
  (define-key evil-normal-state-map (kbd "M-d") 'evil-multiedit-match-and-next)
  ;; Match selected region.
  (define-key evil-visual-state-map (kbd "M-d") 'evil-multiedit-match-and-next)
  ;; Insert marker at point
  (define-key evil-insert-state-map (kbd "M-d") 'evil-multiedit-toggle-marker-here)

  ;; Same as M-d but in reverse.
  (define-key evil-normal-state-map (kbd "M-D") 'evil-multiedit-match-and-prev)
  (define-key evil-visual-state-map (kbd "M-D") 'evil-multiedit-and-prev)

  ;; OPTIONAL: If you prefer to grab symbols rather than words, use
  ;; `evil-multiedit-match-symbol-and-next` (or prev).

  ;; Restore the last group of multiedit regions.
  (define-key evil-visual-state-map (kbd "C-M-D") 'evil-multiedit-restore)

  ;; RET will toggle the region under the cursor
  (define-key evil-multiedit-state-map (kbd "RET") 'evil-multiedit-toggle-or-restrict-region)

  ;; ...and in visual mode, RET will disable all fields outside the selected region
  (define-key evil-motion-state-map (kbd "RET") 'evil-multiedit-toggle-or-restrict-region)

  ;; For moving between edit regions
  (define-key evil-multiedit-state-map (kbd "C-n") 'evil-multiedit-next)
  (define-key evil-multiedit-state-map (kbd "C-p") 'evil-multiedit-prev)
  (define-key evil-multiedit-insert-state-map (kbd "C-n") 'evil-multiedit-next)
  (define-key evil-multiedit-insert-state-map (kbd "C-p") 'evil-multiedit-prev)

  ;; Ex command that allows you to invoke evil-multiedit with a regular expression, e.g.
  (evil-ex-define-cmd "ie[dit]" 'evil-multiedit-ex-match)
