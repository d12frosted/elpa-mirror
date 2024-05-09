
This Emacs package provides a way to show retraction information
for citations and citation data at point.  This is done using the
Crossref REST API
(https://www.crossref.org/documentation/retrieve-metadata/rest-api/)
(experimental version until the feature is available on the regular
version).  At the moment, it explicitly supports detection of DOI
from `ebib' (http://joostkremers.github.io/ebib/) as well as
`bibtex-mode'.

It is possible to show retraction information as a Universal
Sidecar Section
(https://git.sr.ht/~swflint/emacs-universal-sidecar), and support
for `eldoc' is forthcoming.

;; Configuration

For general use, there is one major variable that must be
customized.  `retraction-viewer-crossref-email' should be set to
your email address (or an email address that will be checked, see
https://github.com/CrossRef/rest-api-doc#good-manners--more-reliable-service).
In particular, it may be helpful to set it to `user-mail-address',
as follows.

    (setopt retraction-viewer-crossref-email user-mail-address)

;;; Notice Formatting

It is possible to customize how notices are formatted using the
`retraction-viewer-notice-format' variable.  The % escapes are
defined in `retraction-viewer-format-spec', which can be customized
as well.

The `retraction-viewer-format-spec' is an alist of (unique)
characters to either variable names or functions taking a
retraction notice message.  In either case, they should return a
string, or nil (which will become the empty string).  Retraction
notice data is a direct translation from the JSON output of the
CrossRef REST API.  As it is at present using the experimental
version of the API keys are subject to change.

;;; Performance Tuning

Additionally, there are two variables which can be used to tune
performance: `retraction-viewer-connect-timeout' and
`retraction-viewer-timeout'.  These can either be a number of
seconds, or nil.  If nil, the variables `plz-connect-timeout' and
`plz-timeout', respectively are used to provide the values.

;;; Eldoc Configuration

Retraction notices can also be showed using `eldoc', by enabling
both `eldoc-mode' and `retraction-viewer-eldoc-mode'.  Note, this
operates asynchronously, and will format notices using
`retraction-viewer-notice-format'.  Additionally, collecting
retraction data is subject to collecting a DOI (see
`retraction-viewer-get-doi-functions' described below).

;;; DOI Getters

Finally, it's possible to configure how the "current DOI" is
detected using the `retraction-viewer-get-doi-functions' hook.  The
functions are evaluated until one returns non-nil.  By default, it
will get the DOI from ebib if called in an ebib buffer
(`retraction-viewer-get-ebib-doi'), from the bibtex entry-at-point
if within a bibtex buffer (`retraction-viewer-get-bibtex-doi'),
from the currently shown elfeed entry if in an `elfeed-show' buffer
(`retraction-viewer-get-elfeed-doi'), or if point is on a DOI (see
`retraction-viewer-doi-regexp').  Additional functions can be
written to select a current DOI, and should operate by: a) not
adjusting match data; b) not adjust point/mark; c) not adjust
narrowing, and d) fail early (i.e., return nil ASAP).

;; Use as a Library

Additionally, `retraction-viewer' is intended to be a way for other
packages to get retraction information and related data easily.  To
this end, there are three categories of functions it provides: DOI
detection, retraction status, and notice formatting.

DOIs can be detected using `retraction-viewer-current-doi' to
determine if there is a DOI in the current context (whatever that
may be given mode, etc.), for more information about how this can
be extended, see above.  Additionally, the
`retraction-viewer-doi-at-point' can be used directly to determine
if there is a DOI at point (using `retraction-viewer-doi-regexp').

The retraction status of a DOI can be determined with
`retraction-viewer-doi-status', which will return a list of alists
describing any retraction notices found in the RetractionWatch
database.  These alists are at present subject to change.
Additionally, a callback, taking the status record can be passed as
an optional second argument; for an example of use, see
`retraction-viewer-eldoc-function'.

Finally, retraction notices can be formatted easily using a
format-string like construct using
`retraction-viewer-format-notice', (see above section, "Notice
Formatting" for more information).

;; Errors and Patches

If you find an error, or have a patch to improve this package (or
are able to add additional DOI getters), please send an email to
~swflint/emacs-utilities@lists.sr.ht.
