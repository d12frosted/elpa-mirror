This program can register multiple functions to a keybind easily.
For example:
(mykie:set-keys global-map ; <- you can specify nil to bind to global-map
  "C-j" ; You don't need kbd macro
  :default newline-and-indent   ; <- normal behavior
  :region  query-replace-regexp ; <- do query-replace-regexp in region
  "C-a"
  :default beginning-of-line
  :C-u     (message "hello") ; <- C-u + C-a, then you can see hello
  ;; You can add more keybinds
  ;; ...
  )

Above function call newline-and-indent by default,
But call query-replace-regexp function if you select region.

There are other way to bind a keybind:
(mykie:global-set-key "C-j" ; You don't need kbd macro
  :default newline-and-indent
  :region query-replace-regexp)

You can see more example : https://github.com/yuutayamada/mykie-el
