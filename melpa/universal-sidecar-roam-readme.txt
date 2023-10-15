
This file can be used to show sections from the `org-roam-mode'
buffer in `universal-sidecar'.  This can be done either through
manual use of the `universal-sidecar-roam-section' function, or
through taking an existing configuration
(`org-roam-mode-sections').

To use `universal-sidecar-roam-section', a minimum configuration
is:

(add-to-list 'universal-sidecar-sections
             '(universal-sidecar-roam-section org-roam-backlinks-section))

Note, that if you would pass arguments to the normal org-roam
section, you may do so after the section name in
`universal-sidecar-org-roam-section'.

Finally, your sections can be added en-masse with:

(setq universal-sidecar-sections
      (universal-sidecar-roam-convert-roam-sections org-roam-mode-sections))

Additionally, the `universal-sidecar-buffer-id-formatters' variable
can have a "node title or buffer name" formatter, using the
`universal-sidecar-roam-buffer-name' function.
