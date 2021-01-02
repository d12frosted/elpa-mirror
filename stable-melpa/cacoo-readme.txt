A minor mode for editing a document with Cacoo diagrams.  Diagrams
are saved for local cache so that you can use the diagrams in the
offline environment. Diagrams are re-sized by ImageMagick
automatically and displayed in-line.

Integrating Emacs with Cacoo, the diagramming tool on the Web,
I'm sure that Emacs becomes the most powerful documentation tool.

Not only Cacoo diagrams, but also any images those are indicated by
the URL can be displayed.

; Installation:

This program is dependent on followings:
- anything.el (http://www.emacswiki.org/emacs/Anything)
- deferred.el (http://github.com/kiwanami/emacs-deferred/raw/master/deferred.el)
- concurrent.el (http://github.com/kiwanami/emacs-deferred/raw/master/concurrent.el)
- wget, ImageMagick(convert, identify, display)

Put cacoo.el and cacoo-plugins.el in your load-path, and add following code.

(require 'cacoo)
(require 'cacoo-plugins)      ; option
(setq cacoo:api-key "APIKEY") ; option
(global-set-key (kbd "M--") 'toggle-cacoo-minor-mode) ; key bind example
