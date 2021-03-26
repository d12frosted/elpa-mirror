toc-org helps you to have an up-to-date table of contents in org or markdown
files without exporting (useful primarily for readme files on GitHub).

NOTE: Previous name of the package is org-toc. It was changed because of a
name conflict with one of the org contrib modules.

After installation put into your .emacs file something like

(if (require 'toc-org nil t)
    (progn
      (add-hook 'org-mode-hook 'toc-org-mode)

      ;; enable in markdown, too
      (add-hook 'markdown-mode-hook 'toc-org-mode)
      (define-key markdown-mode-map (kbd "\C-c\C-o") 'toc-org-markdown-follow-thing-at-point))
  (warn "toc-org not found"))

And every time you'll be saving an org file, the first headline with a :TOC:
tag will be updated with the current table of contents.

For details, see https://github.com/snosov1/toc-org
