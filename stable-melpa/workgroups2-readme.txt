
This program can save&load multiple named workspaces (or "workgroups").

If you find a bug - please post it here:
https://github.com/pashinin/workgroups2/issues

Quick start,

- `wg-create-workgroup' to save window&buffer layout as a work group
- `wg-open-workgroup' to open an existing work group
- `wg-kill-workgroup' to delete an existing work group

Optionally, you can use minor-mode `workgroups-mode' by put below
line into .emacs ,

(workgroups-mode 1)

Most commands start with prefix `wg-prefix-key'.
You can change it before activating workgroups.
Change prefix key (before activating WG)

(setq wg-prefix-key "C-c z")

By default prefix is: "C-c z"

<prefix> C-c    - create new workgroup
<prefix> C-v    - open existing workgroup
<prefix> C-k    - delete existing workgroup

Change workgroups session file,

  (setq wg-session-file "~/.emacs.d/.emacs_workgroups")

Support any special buffer (say `ivy-occur-grep-mode'),

  (with-eval-after-load 'workgroups2
    ;; provide major mode, package to require, and functions
    (wg-support 'ivy-occur-grep-mode 'ivy
                `((serialize . ,(lambda (_buffer)
                                  (list (base64-encode-string (buffer-string) t))))
                  (deserialize . ,(lambda (buffer _vars)
                                    (switch-to-buffer (wg-buf-name buffer))
                                    (insert (base64-decode-string (nth 0 _vars)))
                                    ;; easier than `ivy-occur-grep-mode' to set up
                                    (grep-mode)
                                    ;; need return current buffer at the end of function
                                    (current-buffer))))))
