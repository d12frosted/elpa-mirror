
Workgroups2 is an Emacs session manager.  It is based on the
experimental branch of the original "workgroups" extension.

If you find a bug - please post it here:
https://github.com/pashinin/workgroups2/issues

Quick start,

- `wg-create-workgroup' to save current windows layout
- `wg-open-workgroup' to open saved windows layout

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

Change workgroups session file,

  (setq wg-session-file "~/.emacs.d/.emacs_workgroups")
