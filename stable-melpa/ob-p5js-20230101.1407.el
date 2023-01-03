;;; ob-p5js.el --- Support for p5js in org-babel

;; Licence: MIT
;; Author: Alejandro Gallo <aamsgallo@gmail.com>
;; Version: 1.0
;; Package-Version: 20230101.1407
;; Package-Commit: f4456b6533bcf2d41caffb267721ef00a0ef16c2
;; Package-Requires: ((emacs "25.1"))
;; Keywords: javascript, graphics, multimedia, p5js, processing, org-babel
;; URL: https://github.com/alejandrogallo/p5js

;;; Commentary:

;; This package provides a minor mode for p5js
;; and a way to export javascript code to an iframe
;; containing a p5js ready environment to export to html.

;; [[file:readme.org::*Implementation][Implementation:2]]
(require 'ob)

;;; Code:
;; Implementation:2 ends here



;; All the options for this package are reachable through the group =ob-p5js=


;; [[file:readme.org::*Implementation][Implementation:3]]
(defgroup ob-p5js nil
  "Options for org-babel p5.js package."
  :prefix "ob-p5js-"
  :group 'org-babel)
;; Implementation:3 ends here




;; The defaults for every src block are given by


;; [[file:readme.org::*Implementation][Implementation:4]]
(defvar org-babel-default-header-args:p5js
  '((:exports . "results")
    (:results . "verbatim html replace value")
    (:eval . "t")
    (:width . "100%")))
;; Implementation:4 ends here



;; where the most notable one is the =:results=,
;; in that it creates an =html= export block.

;; The custom block arguments are the =width= and =height=
;; for the =iframe= where the {{{p5js}}} is embedded in,
;; and also a =center= boolean field in order to insert
;; *both* the =iframe= and the =main= tag inside an =html=
;; =center= element.


;; [[file:readme.org::*Implementation][Implementation:5]]
(defconst org-babel-header-args:p5js
 '((width . :any)
   (height . :any)
   (center . :any))
  "Header arguments specific to p5js.")
;; Implementation:5 ends here



;; We also need to set and define the mode that should be used
;; for the src-blocks, in this case probably one would like to
;; use the =js= mode, but in the future one might want
;; to use a dedicated =p5js= mode, so we can make it configurable


;; [[file:readme.org::*Implementation][Implementation:6]]
(defcustom ob-p5js-mode
  'js
  "The major mode that should be used in the src blocks."
  :type '(symbol :tag "Mode name")
  :group 'ob-p5js)

(add-to-list 'org-src-lang-modes `("p5js" . ,ob-p5js-mode))
;; Implementation:6 ends here




;; We need to include the script in the =iframe= environment,
;; and you can customize where you want to get your =p5js=
;; from. By default it points to the default one from the website


;; [[file:readme.org::*Implementation][Implementation:7]]
(defcustom ob-p5js-src "https://cdn.jsdelivr.net/npm/p5@1.4.2/lib/p5.js"
  "The source of p5js."
  :type 'string
  :group 'ob-p5js)
;; Implementation:7 ends here



;; and I also give every =iframe= the class =org-p5js= by default,
;; so that you can customize it via =css= or =js=.


;; [[file:readme.org::*Implementation][Implementation:8]]
(defcustom ob-p5js-iframe-class "org-p5js"
  "Default class for iframes containing a p5js sketch."
  :type 'string
  :group 'ob-p5js)
;; Implementation:8 ends here



;; The body of the input for the =iframe= is a minimal
;; =html= document containing the src script for {{{p5js}}}
;; and yours:


;; [[file:readme.org::*Implementation][Implementation:9]]
(defun ob-p5js--create-sketch-body (params body)
  "Create the main body for the iframe content.

   PARAMS contains the parameters of the src block.
   BODY contains the sketch."
  (format "
<html>
<head>
  <script src=%S></script>
  <script>
    %s
  </script>
</head>
<body>
  %s
</body>
</html>
" ob-p5js-src body (ob-p5js--maybe-center params "<main></main>")))

(defun ob-p5js--maybe-center (params body)
  "Center the content whenever params wants it.

   PARAMS contains the parameters of the src block.
   BODY contains the sketch."
  (if (alist-get :center params)
      (format "<center>%s</center>" body)
    body))
;; Implementation:9 ends here



;; Now an important aspect arises, how do we embed the
;; =html= document containing the sketch into the =iframe=.
;; From all my testing I found that including the whole script
;; as a base64 encoding hunk works best, so this is the approach I took


;; [[file:readme.org::*Implementation][Implementation:10]]
(defun ob-p5js--create-iframe (params body &optional width height)
  "Create iframe by encoding base64 the sketch in body.

   PARAMS contains the parameters of the src block.
   BODY contains the sketch.
   WIDTH is a string containing an html-valid width.
   HEIGHT is a string containing an html-valid height."
  (let ((sketch (base64-encode-string (ob-p5js--create-sketch-body params
                                                                   body)
                                      t)))
    (ob-p5js--maybe-center params
                        (format "<iframe class=\"%s\"
                                         frameBorder='0'
                                         %s
                                         src=\"data:text/html;base64,%s\">
                                         </iframe>"
                                ob-p5js-iframe-class
                                (concat (if width
                                            (format "width=\"%s\" " width)
                                          "")
                                        (if height
                                            (format "height=\"%s\" " height)
                                          ""))
                                sketch))))
;; Implementation:10 ends here



;; #+RESULTS:
;; : p5js--create-iframe

;; Last but not least, comes the part that tells =org-babel=
;; how to execute =p5js= blocks, which entails simply defining
;; a function prefixed by =orb-babel-execute= with the name of the
;; src block.


;; [[file:readme.org::*Implementation][Implementation:11]]
(defun org-babel-execute:p5js (body params)
  "Execute a p5js src block.

   PARAMS contains the parameters of the src block.
   BODY contains the sketch."
  (let ((width (alist-get :width params))
        (height (alist-get :height params)))
    (ob-p5js--create-iframe params body width height)))
;; Implementation:11 ends here




;; And just provide the package:


;; [[file:readme.org::*Implementation][Implementation:12]]
(provide 'ob-p5js)
;;; ob-p5js.el ends here
;; Implementation:12 ends here
