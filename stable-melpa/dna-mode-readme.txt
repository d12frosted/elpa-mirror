* A collection of functions for editing DNA sequences.  It
  provides functions to make editing dna in Emacs easier.

Dna-mode will:
 * Fontify keywords and line numbers in sequences.
 * Fontify bases when font-lock-mode is disabled.
 * Incrementally search dna over pads and numbers.
 * Complement and reverse complement a region.
 * Move over bases and entire sequences.
 * Detect sequence files by content.

; Installation:
--------------------
Here are two suggested ways for installing this package.
You can choose to autoload it when needed, or load it
each time emacs is started.  Put one of the following
sections in your .emacs:

---Autoload:
 (autoload 'dna-mode "dna-mode" "Major mode for dna" t)
 (add-to-list 'magic-mode-alist '("^>\\|ID\\|LOCUS\\|DNA" . dna-mode))
 (add-to-list
    'auto-mode-alist
    '("\\.\\(fasta\\|fa\\|exp\\|ace\\|gb\\)\\'" . dna-mode))
 (add-hook 'dna-mode-hook 'turn-on-font-lock)

---Load:
 (setq dna-do-setup-on-load t)
 (load "/pathname/dna-mode")

The dna-isearch-forward function (and isearch in general)
is much more useful with something like the following:
 (make-face 'isearch)
 (set-face-background 'isearch "yellow")
 (setq-default search-highlight t)
