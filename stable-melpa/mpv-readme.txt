This package is a potpourri of helper functions to control a mpv
process via its IPC interface.  You might want to add the following
to your init file:

(org-add-link-type "mpv" #'mpv-play)
(defun org-mpv-complete-link (&optional arg)
  (replace-regexp-in-string
   "file:" "mpv:"
   (org-file-complete-link arg)
   t t))
(add-hook 'org-open-at-point-functions #'mpv-seek-to-position-at-point)
