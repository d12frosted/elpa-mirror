For hardline Luddite editing!

Feebleline removes the modeline and replaces it with a slimmer proxy
version, which displays some basic information in the echo area
instead.  This information is only displayed if the echo area is not used
for anything else (but if you switch frame/window, it will replace whatever
message is currently displayed).

Feebleline now has a much improved customization interface. Simply set
feebleline-msg-functions to whatever you want! Example:

(setq
 feebleline-msg-functions
 '((feebleline-line-number)
   (feebleline-column-number)
   (feebleline-file-directory)
   (feebleline-file-or-buffer-name)
   (feebleline-file-modified-star)
   (magit-get-current-branch)
   (projectile-project-name)))

The elements should be functions, accepting no arguments, returning either
nil or a valid string. Even lambda functions work (but don't forget to quote
them). Optionally, you can include keywords  after each function, like so:

(feebleline-line-number :post "" :fmt "%5s")

Accepted keys are pre, post, face, fmt and align.
See source code for inspiration.
