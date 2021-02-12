Use `ivy-mode' to input email address from BBDB efficiently.
Smart to know some ethic groups display family name before given name
Since It's not using any API from `bbdb', it's always fast and stable.

`M-x counsel-bbdb-complete-mail' to input email address.
`M-x counsel-bbdb-reload' to reload contacts from BBDB database.
`M-x counsel-bbdb-expand-mail-alias' to expand mail alias.  Mail Alias
is also called "Contact Group" or "Address Book Group" in other email clients.

Since counsel-bbdb is based ivy-mode.  All ivy key bindings are supported.
For example, after `C-u M-x counsel-bbdb-complete-mail', you can press
`C-M-n' to input multiple mail address.

You can also customize `counsel-bbdb-customized-insert' to insert
email in your own way:
  (setq counsel-bbdb-customized-insert
        (lambda (r append-comma)
          (let* ((family-name (nth 1 r))
                 (given-name (nth 2 r))
                 (display-name (nth 3 r))
                 (mail (nth 4 r))))
          (insert (format "%s:%s:%s:%s%s"
                          given-name
                          family-name
                          display-name
                          mail
                          (if append-comma ", " " ")))))

BTW, `ivy-resume' is fully supported.
