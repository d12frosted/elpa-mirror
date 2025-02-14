An XML tokenizer that does not use any global variables.

xmltokf provides similar functions to the standard xmltok library
included in Emacs, but without relying on global variables
(functional, sort of).  There are also functions to
programmatically edit XML tokens and elements.

Example usage:

Use ‘xmltokf-scan-here’ to construe a token, and
‘xmltokf-scan-element’ to construe an element-ish sort of structure.

Functions that don’t end in an “!” aim to be free of any
side-effects: they do *not* set global variables (see
‘xmltok-save’), or move the point, but just return information
about the current token or element.  They are functional in that
respect.

 To scan through a document, you could call something like this:

(defun xmltokf-scan-doc ()
  (let ((current-token (xmltokf-scan-here (point-min)))
        stack)
    (while (and current-token (xmltokf-token-type current-token))
      ;; Do your stuff...
      (push current-token stack)
      (setq current-token (xmltokf-scan-here (xmltokf-token-end current-token))))
    (nreverse stack)))

See tests.el for more examples.

To run the tests from the command line: make test
