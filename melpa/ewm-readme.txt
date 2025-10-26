            1 2 3 4 5 6 7 8 9 (workspaces)
                       ^ UP
                 (split/previous)
             (quit) q  k  TAB (last-workspace)
                     \ ^ /
  < LEFT (s/res) h  <- M -> l  (split/resize) > RIGHT
                       v \
                       j  SPC (Monocle)
                 (split/next)
                       v DOWN

Keybind behaves differently based on the number of windows in the current workspace.

usage: (global-ewm-mode 1)
