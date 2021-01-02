This packages provides ivy as the interface for selection from xref results.

;; Setup

(require 'ivy-xref) ; unless installed from a package
(setq xref-show-xrefs-function 'ivy-xref-show-xrefs)
