; Installation:

1- Put opencl-mode.el in your load path or optionally add this line to your Emacs init file:
   (add-to-list 'load-path "/path/to/directory/where/opencl-mode.el/resides")
2- Add these lines to your Emacs init file
   (require 'opencl-mode)
   (add-to-list 'auto-mode-alist '("\\.cl\\'" . opencl-mode))
