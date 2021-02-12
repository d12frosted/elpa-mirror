This provides an edit server to respond to requests from the Chrome
Emacs Chrome plugin. This is my first attempt at doing something
with sockets in Emacs. I based it on the following examples:

  http://www.emacswiki.org/emacs/EmacsEchoServer
  http://nullprogram.com/blog/2009/05/17/

To use it ensure the file is in your load-path and add something
like the following examples to your .emacs:

To open pages for editing in new buffers in your existing Emacs
instance:

  (when (require 'edit-server nil t)
    (setq edit-server-new-frame nil)
    (edit-server-start))

To open pages for editing in new frames using a running emacs
started in --daemon mode:

  (when (and (require 'edit-server nil t) (daemonp))
    (edit-server-start))

Buffers are edited in `text-mode' by default; to use a different
major mode, change `edit-server-default-major-mode' or customize
`edit-server-url-major-mode-alist' to specify major modes based
on the remote URL:

  (setq edit-server-url-major-mode-alist
        '(("github\\.com" . markdown-mode)))

Alternatively, set the mode in `edit-server-start-hook'.  For
example:

(add-hook 'edit-server-start-hook
          (lambda ()
            (when (string-match "github.com" (buffer-name))
              (markdown-mode))))
