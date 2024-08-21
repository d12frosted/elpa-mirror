Out of the box marginalia enriches package completion with
information from the built-in package manager.  This packages
teaches it to additionally use the Epkgs database, and if the
Borg package manager is available, then it uses information
provided by that as well.

  (with-eval-after-load 'marginalia
    (setcar (alist-get 'package marginalia-annotator-registry)
            #'epkg-marginalia-annotate-package))
