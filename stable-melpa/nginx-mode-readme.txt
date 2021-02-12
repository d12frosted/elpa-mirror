This is a quick mode for editing Nginx config files, as I didn't find
anything else around that did quite this much.

Many thanks to the authors of puppet-mode.el, from where I found a
useful indentation function that I've modified to suit this situation.

Put this file into your load-path and the following into your ~/.emacs:
  (require 'nginx-mode)
