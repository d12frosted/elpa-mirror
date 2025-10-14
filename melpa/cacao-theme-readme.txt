This theme was inspired by an image I looked at on Alorica's Service Dispatch Desk.
 I had a practice of inverted the colors of an image to look for cracks on television screen.
I reversed an image of a television screen I recieved and the colors I saw struck me as being good colors for an Emacs theme.

This image is primarily a light image, as the main background is a light tan color.
Light tan and dark brown (both colors found on a cacao bean) are primary colors (light tan for the background and dark brown as a highlight.
I have also made the fonts a big larger (for older eyes!)

** WARNING **

This theme WILL cause org tables to go out of alignment, this IS
fixable with additional code inserted into your .emacs file:

(defun set-buffer-variable-pitch ()
 (interactive)
 (variable-pitch-mode t)
 (setq line-spacing 3)
 (set-face-attribute 'org-table nil :inherit 'fixed-pitch)
 (set-face-attribute 'org-code nil :inherit 'fixed-pitch)
 (set-face-attribute 'org-block nil :inherit 'fixed-pitch)
(set-face-attribute 'org-block-background nil :inherit 'fixed-pitch)
 )

 (add-hook 'org-mode-hook 'set-buffer-variable-pitch)
 (add-hook 'eww-mode-hook 'set-buffer-variable-pitch)
 (add-hook 'markdown-mode-hook 'set-buffer-variable-pitch)
(add-hook 'Info-mode-hook 'set-buffer-variable-pitch)


Hex color codes  provided from https://imagecolorpicker.com
An excellent site that allows you to upload a pic and it turns the colors into
css color representations!

If you DON'T use this, anything with org-tables will give you tables that won't line up.

Suggestions welcome, feel free to visit my github at
https://github.com/Michael-Garibaldi/cacao-theme


To use it, put it  the following in your Emacs configuration file:
(load-theme 'cacao-theme t)

OR
download it from MELPA!
