To integrate this auto-complete backend with Merlin, just (require
'merlin-ac) in your Emacs configuration files.  When `merlin-mode'
is subsequently enabled in buffers, auto-complete will be set up
too.  Some auto-complete settings will be overridden: to avoid this
for finer control, customize the variable `merlin-ac-setup'.
