temporary-persistent.el -  easy way to switch temp buffers and keep them
persistent. It provides `temporary-persistent-switch-buffer' function
to create temporary buffers named *temp*, *temp-1* and so on, witch is
associated to files and will be saved any time you run `kill-buffer' or
`kill-emacs'.
Furtermore, you can save them manually any time via `save-buffer' function.
If `consult' is installed, `temporary-persistent-consult-switch-buffer'
lists the temp buffers annotated with their contents summary.
See README.md for more information.
