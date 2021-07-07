Enable inline PDF preview in Org buffers.

Usage:

You need to have pdf2svg command installed in exec-path.

  pdf2svg: https://cityinthesky.co.uk/opensource/pdf2svg/

Download org-inline-pdf.el and install it using package.el.

  (package-install-file "/path-to-download-dir/org-inline-pdf.el")

Enable this feature in an Org buffer with M-x org-inline-pdf-mode.
Add the following line in your init file to automatically enable
the feature in newly opened Org buffers.

  (add-hook 'org-mode-hook 'org-inline-pdf-mode)

Links to PDF files in Org buffers are now displayed inline.

Also, when the file is exported to HTML using ox-html, PDF will be
embedded using img tag.  Note that PDF with img tag is not standard
and will be rendered only in particular browsers.  Safari.app is
only the one I know.
