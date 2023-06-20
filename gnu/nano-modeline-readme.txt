Nano modeline is a an alterntive to the GNU/Emacs modeline. It can
be displayed at the bottom (mode-line) or at the top (header-line)
depending on the nano-modeline-position custom setting. There are
several modelines that can be installed on a per-mode basis or as
the default one.

Usage example:

Install prog mode modeline:
(add-hook 'prog-mode-hook #'nano-modeline-prog-mode)

Make text mode modeline the default:
(nano-modeline-text-mode t)

Install all available modes:
(add-hook 'prog-mode-hook            #'nano-modeline-prog-mode)
(add-hook 'text-mode-hook            #'nano-modeline-text-mode)
(add-hook 'org-mode-hook             #'nano-modeline-org-mode)
(add-hook 'pdf-view-mode-hook        #'nano-modeline-pdf-mode)
(add-hook 'mu4e-headers-mode-hook    #'nano-modeline-mu4e-headers-mode)
(add-hook 'mu4e-view-mode-hook       #'nano-modeline-mu4e-message-mode)
(add-hook 'mu4e-compose-mode-hook    #'nano-modeline-mu4e-compose-mode)
(add-hook 'elfeed-show-mode-hook     #'nano-modeline-elfeed-entry-mode)
(add-hook 'elfeed-search-mode-hook   #'nano-modeline-elfeed-search-mode)
(add-hook 'elpher-mode-hook          #'nano-modeline-elpher-mode)
(add-hook 'term-mode-hook            #'nano-modeline-term-mode)
(add-hook 'eat-mode-hook             #'nano-modeline-eat-mode)
(add-hook 'xwidget-webkit-mode-hook  #'nano-modeline-xwidget-mode)
(add-hook 'messages-buffer-mode-hook #'nano-modeline-message-mode)
(add-hook 'org-capture-mode-hook     #'nano-modeline-org-capture-mode)
(add-hook 'org-agenda-mode-hook      #'nano-modeline-org-agenda-mode)