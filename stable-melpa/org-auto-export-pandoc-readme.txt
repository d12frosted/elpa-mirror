This package provides the functionality to automatically export
with org-pandoc-export-* modes.
Add this hook if you want to execute it on save:
(add-hook 'after-save-hook 'org-auto-export-pandoc)
It adds a hook to exute it when you save the file. It will look
for the following tag:
#+auto-export-pandoc: to-markdown
You can add the tag muliple times to export to multiple formats:
#+auto-export-pandoc: to-markdown
#+auto-export-pandoc: to-latex-pdf
#+auto-export-pandoc: to-html5
