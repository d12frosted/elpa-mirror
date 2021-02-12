Support for saving and opening last known pdf position in pdfview mode.
Information  will be saved relative to the pdf being viewed so ensure
`pdf-view-restore-filename' is in the same directory as the viewing pdf.

To enable, add the following:
  (add-hook 'pdf-view-mode-hook 'pdf-view-restore-mode)
