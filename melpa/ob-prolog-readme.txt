Org-babel support for prolog.

To activate ob-prolog add the following to your init.el file:

 (add-to-list 'load-path "/path/to/ob-prolog-dir")
 (org-babel-do-load-languages
   'org-babel-load-languages
   '((prolog . t)))

It is unnecessary to add the directory to the load path if you
install using the package manager.

In addition to the normal header arguments ob-prolog also supports
the :goal argument.  :goal is the goal that prolog will run when
executing the source block.  Prolog needs a goal to know what it is
going to execute.
