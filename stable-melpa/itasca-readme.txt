Emacs modes for editing Itasca software data files.
---------------------------------------------------
FLAC FLAC3D UDEC 3DEC PFC www.itascacg.com/software

This package defines Emacs major modes for editing Itasca software
data files. The focus is on making FISH programming easier. Code
specific keyword and FISH intrinsic highlighting is provided along
with indenting and code navigation support.

These file extensions are mapped to the following major modes:

 .dat .fis .fin  :  itasca-general-mode
 .fdat           :  itasca-flac-mode
 .f3dat          :  itasca-flac3d-mode
 .udat           :  itasca-udec-mode
 .pdat           :  itasca-pfc-mode
 .p3dat .p2dat   :  itasca-pfc5-mode
 .3ddat          :  itasca-3dec-mode

itasca-general-mode does not have any code-specific keyword/FISH
highlighting. To associate a specific file extension with a
specific mode (for example to open all .dat files in
itasca-flac-mode) use:

(add-to-list 'auto-mode-alist '("\\.dat$'" . itasca-flac-mode))

To set the major mode on a per-file basis: put a comment in the
following form at the top of the file.

;; -*- mode: itasca-general -*-
;; -*- mode: itasca-flac -*-
;; -*- mode: itasca-flac3d -*-
;; -*- mode: itasca-pfc -*-
;; -*- mode: itasca-pfc5 -*-
;; -*- mode: itasca-udec -*-
;; -*- mode: itasca-3dec -*-

Code navigation, auto-complete and snippets are provided. For a
detailed introduction see:
https://github.com/jkfurtney/itasca-emacs/

to do:
redo FLAC mode
case insensitivity for highlighting
