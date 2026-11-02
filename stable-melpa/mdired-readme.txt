mdired is an Elisp package that provides commands for running SIMD-style
operations on marked Dired items.

Please be advised: mdired can make irreversible changes to the file system if
no prior checkpoint (typically via a source code management or backup tool)
is available. Exercise caution.

INSTALL

If manually installed then ensure that mdired.el is in `load-path'.

If installed via `package-install', then all mdired commands are auto-loaded.
