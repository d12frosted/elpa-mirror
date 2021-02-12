Put this script into a "load-path"ed directory, and load it in your
init file.

  (require 'magic-latex-buffer)

Then you can enable highlighting with "M-x magic-latex-buffer" in a
latex-mode-buffer. If you may enable highlighting automatically,
add to the mode hook.

  (add-hook 'latex-mode-hook 'magic-latex-buffer)

For more informations, see Readme.org.
