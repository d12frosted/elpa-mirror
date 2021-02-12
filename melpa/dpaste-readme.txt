dpaste.el provides functions to post a region or buffer to
<http://dpaste.com> and put the paste URL into the kill-ring.

Inspired by gist.el

Current dpaste.com API usage example:

    curl -si -F 'content=<-' http://dpaste.com/api/v2/ \
      | grep ^Location: | colrm 1 10

Thanks to Paul Bissex (http://news.e-scribe.com) for a great paste
service.

Installation and setup:

Put this file in a directory where Emacs can find it. On GNU/Linux
it's usually /usr/local/share/emacs/site-lisp/ and on Windows it's
something like "C:\Program Files\Emacs<version>\site-lisp". Then
add the follow instructions in your .emacs.el:

    (require 'dpaste nil)
    (global-set-key (kbd "C-c p") 'dpaste-region-or-buffer)
    (setq dpaste-poster "Guido van Rossum")

Then with C-c p you can run `dpaste-region-or-buffer'. With a prefix
argument (C-u C-c p), your paste will use the hold option.
