Run compile in org-mode.
Example:
#+begin_src compile :name uname :output uname.txt :comint t
uname -a
#+end_src

To enable saving the output, you have to config:
(add-hook 'compilation-finish-functions #'ob-compile-save-file)
