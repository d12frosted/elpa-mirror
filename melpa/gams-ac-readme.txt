This package provides auto-complete feature in GAMS mode.  To use this
package, you first need GAMS mode (gams-mode.el) and auto-complete mode.  You
can install GAMS mode and auto-complete mode from MELPA.


Put this file into your load-path and add the following into your init.el
file.

  (require 'gams-ac)
  (gams-ac-after-init-setup)


If you want to add more keywords, for example, "computable", "general",
"equilibrium", Add the following into your init.el.

 (setq gams-ac-source-user-keywords-list
        '("computable" "general" "equilibrium"))
