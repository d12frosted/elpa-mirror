**WARNING: This virtualenv package has been deprecated!**

I haven't maintained https://github.com/aculich/virtualenv.el in a
long time since I use docker and LXC for a better virtual
environment for my development purposes that provides stronger
isolation, first-class network interfaces, and support for
non-python stacks.

If you still want to work with virtualenv there are at least 3
newer, actively maintained packages available on MELPA
<http://melpa.milkbox.net/> that are superior to my old one that
have taken its place:

pyvenv:             https://github.com/jorgenschaefer/pyvenv
virtualenvwrapper:  https://github.com/porterjamesj/virtualenvwrapper.el
python-environment: https://github.com/tkf/emacs-python-environment


This is a minor mode for setting the virtual environment for the
Python shell using virtualenv and supports both python-mode.el and
python.el. This minor mode was inspired by an earlier
implementation by Jesse Legg and Jeremiah Dodds, however this code
is a complete re-write with a GPLv3 license consistent with
GNU Emacs and python-mode.el.

There are two ways to use virtualenv.

1) The quickest way to get started is to simply type:
     M-x virtualenv-workon
   Which will prompt you to enter the name of a directory in
   ~/.virtualenvs that contains your chosen environment. You can
   hit tab to show the available completions.

   You'll know that you're in virtualenv mode now when you see the
   name of the virtualenv you selected in brackets. So if I were to
   select my turbogears environment that I call tg2.1 then I would
   see [tg2.1] appear in the mode line. To make sure you're new
   python shell is set up correctly you can try running this little
   snippet of python code:

     import os, sys
     print os.environ
     print sys.path

2) The recommended way to use virtualenv minor mode is to use a
.dir-locals.el file in the root of your project directory, however that
requires Emacs 23.1 or higher. There are two buffer-local variables that you
can set for virtualenv as shown in this example:

in file /path/to/project/.dir-locals.el:
((nil . ((virtualenv-workon . "tg2.1")
	    (virtualenv-default-directory . "/path/to/project/subdir"))))

The .dir-locals.el is new in Emacs23 and is useful for other
things, too. You should read the dir-locals docs to understand the
format. The variable virtualenv-workon should just be a string the
same as you'd give to the interactive function. The variable
virtualenv-default-directory is useful when you want to have your
python process rooted in a particular directory when it starts, so
that no matter where you are in your project's hierarchy, if you
launch a python shell. This method is recommended because it is
more flexible and will allow multiple virtualenvs running at once
in future versions.
