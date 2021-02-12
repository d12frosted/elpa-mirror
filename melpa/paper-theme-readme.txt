
Paper is a  little, minimal emacs theme that is  meant to be simple
and consistent.

It  was first  intended  to resemble  the look  of  paper, but  has
diverged from  that objective.   Still, though,  I keep  calling it
Paper, as I like that name.

Paper  uses a  small colour  palette  over all  the elements.   Org
headings  are  specially  treated  with a  palette  of  equidistant
colours.  The colours  and heading font sizes  are calculated using
base and factor values which can be edited.  See source.

It's most adapted for ELisp-Org users, as I'm one such user, though
it  works fine  with Markdown,  Textile, Python,  JavaScript, Html,
Diff, Magit, etc.

; Installation:

Install it into a directory that's in the `custom-theme-load-path'.
I recommend  that you  put that directory  also in  `load-path', so
that you can `require' the  `paper-theme'.  Then adapt this snippet
to your configuration.

  ;; Not necessary, but silences flycheck errors for referencing free
  ;; variables.
  (require 'paper-theme)
  ;; It's not necessary to modify these variables, they all have sane
  ;; defaults.
  (setf paper-paper-colour 'paper-parchment ; Custom background.
        paper-tint-factor 45)      ; Tint factor for org-level-* faces
  ;; Activate the theme.
  (load-theme 'paper t)

; Customisation:

It is possible to modify the  base font size and the scaling factor
for `org-level-faces' via  the variables `paper-base-font-size' and
`paper-font-factor' respectively.

The factor  for org-level-*  colours are also  configurable, adjust
the variable `paper-tint-factor'.

Various background colours  are provided, see the  docstring of the
variable `paper-paper-colour'  in order to  find out how  to switch
them.   You  can add  your  custom  colour for  background  without
modifying this module:

  (push (list 'my-bgcolour "#000000") paper-colours-alist)
  (setf paper-paper-colour 'my-bgcolour)

The following snippet will modify org-level-* faces so that initial
stars in  org headings are  hidden and  a Sans-serif font  is used.
Because  the combination  of heading  font sizes  and colours  make
levels  obvious, it  may be  considered superfluous  to have  stars
indicating depth:

  (setq org-hide-leading-stars nil)
  (set-face-attribute
   'org-hide nil
   :height 0.1 :weight 'light :width 'extracondensed)
  (dolist (face org-level-faces)
    (set-face-attribute
     face nil
     :family "Sans Serif"))
