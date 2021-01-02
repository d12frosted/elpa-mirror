OSX notifications via the terminal-notifier gem for Emacs ERC.


; Install

Install terminal notifier:

$ sudo gem install terminal-notifier
or download a binary from here https://github.com/alloy/terminal-notifier/downloads
or $ brew install terminal-notifier

Install the package:

$ cd ~/.emacs.d/vendor
$ git clone git://github.com/julienXX/erc-terminal-notifier.el.git

In your emacs config:

(add-to-list 'load-path "~/.emacs.d/vendor/erc-terminal-notifier.el")
(require 'erc-terminal-notifier)
