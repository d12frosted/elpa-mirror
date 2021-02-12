This is a simple package for capturing and visiting todo items for
the repository you are currently within.  Under the hood it uses
`org-capture' to provide a popup window for inputting `org-mode'
checkboxed todo items (http://orgmode.org/manual/Checkboxes.html)
or regular ** TODO items that get saved to a TODO.org file in the
root of the repository.

Install is as easy as dropping this file into your load path and setting
the relevent functions to keybindings of your choice, i.e.:

  (global-set-key (kbd "C-;") 'ort/capture-todo)
  (global-set-key (kbd "C-'") 'ort/capture-checkitem)
  (global-set-key (kbd "C-`") 'ort/goto-todos)
