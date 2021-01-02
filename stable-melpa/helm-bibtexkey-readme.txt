Please install pybtex which is python bibtex parser.
For example, `sudo easy_install pybtex`.

; Installation:

(add-to-list 'load-path "/path/to/this/filedirectory")
(require 'helm-bibtexkey)
(setq helm-bibtexkey-filelist '("/path/to/bibtexfile1" "/path/to/bibtexfile2"))
