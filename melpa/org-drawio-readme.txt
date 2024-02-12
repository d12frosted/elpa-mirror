When you are drawing with draw.io and you want to insert the svg
image exported from drawio file, the operation is nontrivial.  This
extension provide two commands to reduce the manual work:

- `org-drawio-add' convert drawio to svg, and insert it to org
- `org-drawio-open' open drawio file at the point

; Installation:

To enable, add the following:

  (use-package org-drawio
    :custom ((org-drawio-input-dir "./draws")
             (org-drawio-output-dir "./images")
             (org-drawio-output-crop t) ;; crop the image
             (org-drawio-output-page "0")))

You may need to install drawio and pdf2svg in your PATH.

; Customization:

`org-drawio-command-drawio': customzie drawio cli path
`org-drawio-command-pdf2svg': customize pdf2svg cli path
`org-drawio-input-dir': drawio input folder, default is ./draws
`org-drawio-output-dir': default svg output folder, default is ./images
`org-drawio-page': page from drawio file, default is page 0
`org-drawio-crop': whether crop the image, default is nil
`org-drawio-dir-regex': customize folder regex
`org-drawio-file-regex': customize file name regex
