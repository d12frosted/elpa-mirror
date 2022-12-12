This program provides an interface to the boxes application which can be found at
https://boxes.thomasjensen.com/

To use this, add the following lines to your startup file:

         (global-set-key "\C-cb" 'boxes-command-on-region)
         (global-set-key "\C-cq" 'boxes-create)
         (global-set-key "\C-cr" 'boxes-remove)

If you didn't install the package version then you will also need to put this file somewhere in your load path and
add these lines to your startup file:

         (autoload 'boxes-command-on-region "boxes" nil t)
         (autoload 'boxes-remove "boxes" nil t)
         (autoload 'boxes-create "boxes" nil t)

If `use-package' is installed you can automatically install the boxes binary and elisp package with:

         (use-package boxes
           :ensure t
           :ensure-system-package boxes
           :bind (("C-c b" . boxes-command-on-region)
                  ("C-c q" . boxes-create)
                  ("C-c r" . boxes-remove)))
