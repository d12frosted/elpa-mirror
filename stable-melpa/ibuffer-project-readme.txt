This pacakage provides ibuffer filtering and sorting functions to group buffers
by function or regexp applied to `default-directory'.  By default buffers are
grouped by `project-current' or by `default-directory'.

Buffer group and group type name is determined by function or regexp listed
in `ibuffer-project-root-functions'.  E.g. by adding `file-remote-p' like this:

   (add-to-list 'ibuffer-project-root-functions '(file-remote-p . "Remote"))

remote buffers will be grouped by protocol and host.


To group buffers set `ibuffer-filter-groups' to result of
`ibuffer-project-generate-filter-groups' function:

   (add-hook 'ibuffer-hook
             (lambda ()
               (setq ibuffer-filter-groups (ibuffer-project-generate-filter-groups))))

This package also provides column with filename relative to project.  If there are no
file in buffer then column will display `buffer-name' with `font-lock-comment-face' face.
Add project-file-relative to `ibuffer-formats':

   (custom-set-variables
    '(ibuffer-formats
      '((mark modified read-only locked " "
              (name 18 18 :left :elide)
              " "
              (size 9 -1 :right)
              " "
              (mode 16 16 :left :elide)
              " " project-file-relative))))

It's also possible to sort buffers by that column by calling `ibuffer-do-sort-by-project-file-relative'
or:

   (add-hook 'ibuffer-hook
             (lambda ()
               (setq ibuffer-filter-groups (ibuffer-project-generate-filter-groups))
               (unless (eq ibuffer-sorting-mode 'project-file-relative)
                 (ibuffer-do-sort-by-project-file-relative))))

To avoid calculating project root each time, one can set `ibuffer-project-use-cache'.
Root info per directory will be stored in the `ibuffer-project-roots-cache' variable.
Command `ibuffer-project-clear-cache' allows to clear project info cache.
