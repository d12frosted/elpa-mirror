
Emacs built-in `completion-at-point' completion mechanism has no
support for go by default. This package helps solve the problem by
with a custom `completion-at-point' function, that should be added to
`completion-at-point-functions' as so:

  (add-to-list 'completion-at-point-functions #'go-capf)

Note that this requires gocode (https://github.com/mdempsky/gocode)
to be installed on your system, that's compatible with the version of
go you are using.
