Tempel implements a simple template/snippet system.  The template format
is compatible with the template format of the Emacs Tempo library.  Your
templates are stored in the `tempel-path' (by default the file
"templates" in the `user-emacs-directory').  Bind the commands
`tempel-complete', `tempel-expand' or `tempel-insert' to some keys in
your user configuration.  You can jump with the keys M-{ and M-} from
field to field.  `tempel-complete' and `tempel-expand' work best with
the Corfu completion UI, while `tempel-insert' uses `completing-read'
under the hood.  You can also use `tempel-complete' and `tempel-expand'
as `completion-at-point-functions'.
