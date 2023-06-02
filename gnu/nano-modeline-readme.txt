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