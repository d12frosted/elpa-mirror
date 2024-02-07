An implementation of xdg-desktop-portal filechooser in Emacs. This allows
for choosing files in applications like firefox (with GTK_USE_PORTAL set)
from an Emacs frame. The default is to use `read-file-name' for choosing
a single file and a pair of Dired buffers for choosing multiple files.