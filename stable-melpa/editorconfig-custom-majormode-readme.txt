An EditorConfig extension that defines a property to specify which
Emacs major-mode to use for files.

For example, add emacs_mode to your .editorconfig as follows, and
`nginx-mode' will be always enabled when visiting *.conf files.

[*.conf]
emacs_mode = nginx

Also this library has an experimental mmm-mode support.
To use it, add properties like:

[*.conf.j2]
emacs_mode = nginx
emacs_mmm_classes = jinja2

Multiple mmm_classes can be specified by separating classes with
commmas.

To enable this plugin, add `editorconfig-custom-majormode' to
`editorconfig-custom-hooks':

(add-hook 'editorconfig-custom-hooks
          'editorconfig-custom-majormode)
