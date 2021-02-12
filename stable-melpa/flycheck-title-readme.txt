flycheck-title lets you view flycheck messages in the frame title,
keeping the minibuffer free for other things.

This is particularly useful if you're using your minibuffer for
eldoc, and using pop-ups for completion.

To install, simply add to your configuration:

(with-eval-after-load 'flycheck
  (flycheck-title-mode))

See https://github.com/Wilfred/flycheck-frame-title for full docs
and gratuitous screenshots.
