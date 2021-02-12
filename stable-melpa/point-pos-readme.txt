The package provides commands for managing the history of saved point
positions.

To install the package, add the following to your emacs init file:

  (add-to-list 'load-path "/path/to/point-pos")
  (autoload 'point-pos-save "point-pos" nil t)

Commands:

"M-x point-pos-save"     - save current position;
"M-x point-pos-goto"     - return to the last saved position;
"M-x point-pos-next"     - return to the next saved position;
"M-x point-pos-previous" - return to the previous saved position;
"M-x point-pos-delete"   - delete current position from history.
