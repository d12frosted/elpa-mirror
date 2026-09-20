
See Hugo's commentary for original goals and further discussion,
at http://larve.net/people/hugo/2003/scratchpad/NotationThreeEmacsMode.html
Also draws on http://dishevelled.net/elisp/turtle-mode.el (which is for the _other_ turtle!)

Project hosted at <https://bitbucket.org/nxg/ttl-mode>.  See there for updates.

For documentation on Notation 3, see:
http://www.w3.org/DesignIssues/Notation3.html

Current features:
- *Turtle* grammar subset
- approximate syntax highlighting
- comment/uncomment block with M-;
- indentation

To use:

(autoload 'ttl-mode "ttl-mode")
(add-hook 'ttl-mode-hook 'turn-on-font-lock)
(add-to-list 'auto-mode-alist '("\\.\\(n3\\|ttl\\|trig\\)\\'" . ttl-mode))
