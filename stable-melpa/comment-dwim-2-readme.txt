
# Description

This package provides a replacement for `comment-dwim' called
`comment-dwim-2', which includes more features and allows you to
comment / uncomment / insert comment / kill comment and indent
comment depending on the context.  The command can be repeated
several times to switch between the different possible behaviors.

# Demonstration

You can find several gifs showing how the command works on Github:
https://github.com/remyferre/comment-dwim-2

# How to use

You need to add your own key binding first, for instance:

  (global-set-key (kbd "M-;") 'comment-dwim-2)

# Customization

## Commenting region

When commenting a region, `comment-dwim-2' will by default comment
the entirety of the lines that the region spans (i.e. a line will
be fully commented even if it is partly selected).  In Lisp modes,
however, `comment-dwim-2' will strictly comment the region as
commenting whole lines could easily lead to unbalanced parentheses.
You can customize this behavior.

If you always want to fully comment lines (Lisp modes included),
add this to your configuration file:

  (setq cd2/region-command 'cd2/comment-or-uncomment-lines)

If you only want to comment the selected region (like
`comment-dwim' does), add this:

  (setq cd2/region-command 'cd2/comment-or-uncomment-region)

# Org-mode

For org-mode, consider using `org-comment-dwim-2':

  (define-key org-mode-map (kbd "M-;") 'org-comment-dwim-2)

## Behavior when command is repeated

`comment-dwim-2' will by default try to kill any end-of-line
comments when repeated. If you wish to reindent these comments
instead, add this to your configuration file:

  (setq comment-dwim-2--inline-comment-behavior 'reindent-comment)

If you use this setting, you will still be able to kill comments by
calling `comment-dwim-2' with a prefix argument.
