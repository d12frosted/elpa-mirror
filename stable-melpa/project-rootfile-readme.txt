A project backend that uses a root file (e.g. Gemfile) for detection.

Usage:
If you prefer VCS root over root file for project detection, add the following to your init file:

     (add-to-list 'project-find-functions #'project-rootfile-try-detect t)

Otherwise, if you prefer a root file, add the following:

     (add-to-list 'project-find-functions #'project-rootfile-try-detect)
