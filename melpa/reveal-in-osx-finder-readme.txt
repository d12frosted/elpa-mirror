
Usage:

If M-x reveal-in-osx-finder is invoked in a file-associated buffer,
it will open the folder enclosing the file in the OS X Finder.
It will also highlight the file the buffer is associated with within the folder.

If M-x reveal-in-osx-finder is invoked in a dired buffer,
it will open the current folder in the OS X Finder.
It will also highlight the file at point if available.

If M-x reveal-in-osx-finder is invoked in a buffer not associated with a file,
it will open the folder defined in the default-directory variable.


Special thanks:

This is a modified version of the open-finder found at the URL below.
Thank you elemakil and lawlist for introducing this nice piece of code,
http://stackoverflow.com/questions/20510333/in-emacs-how-to-show-current-file-in-finder
and Peter Salazar for pointing out a useful link about AppleScript (below),
http://stackoverflow.com/questions/11222501/finding-a-file-selecting-it-in-finder-issue
and mikeypostman and purcell for auditing the code for MELPA approval.
