Testeable elisp API that wraps GNU global calls and integration to editor
using this API with project.el and xref.el
You can setup using GNU global as backend with any of the following two
lines:

;; to use GNU Global automagically, regardless of Emacs default configuration
(add-hook 'ruby-mode-hook #'global-tags-exclusive-backend-mode)
;; to use GNU Global automagically, respecting other backends
(add-hook 'ruby-mode-hook #'global-tags-shared-backend-mode)

Alternatively, you can manually configure project.el and xref.el, add their
"recognize this global handled project" to the proper places like so:

;; xref (finding definitions, references)
(add-to-list 'xref-backend-functions 'global-tags-xref-backend)
;; project.el (finding files)
(add-to-list 'project-find-functions 'global-tags-try-project-root)
;; configure Imenu
(add-hook 'ruby-mode-hook #'global-tags-imenu-mode)
;; to update database after save
(add-hook 'c++-mode-hook (lambda ()
                           (add-hook 'after-save-hook
                                     #'global-tags-update-database-with-buffer
                                     nil
                                     t)))

By default, the global-tags backend will pre-fetch expensive calls (list
files, get all symbols) to keep a snappy flow.  It is assumed that files
or symbols being looked up don't change much within an Emacs session.

Also, when standing on a include file like «#include "someheader.h"», if
you do M-. `xref-find-definitions' it will look for that header file.
This is a feature based on `ggtags-find-tag-dwim'.
