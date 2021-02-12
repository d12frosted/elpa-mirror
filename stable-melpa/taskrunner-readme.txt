This package aims to provide a library which can be used to retrieve tasks
from several build systems and task runners.  The output produced can then be
leveraged to create interactive user interfaces(helm/ivy for example) which
will let the user select a task to be ran.

;; Installation

;;; MELPA

If you installed from MELPA, then make sure to also install one of the
available frontends for this.  They are:
- ivy-taskrunner <- Uses ivy as a frontend
- helm-taskrunner <- Uses helm as a frontend
- ido-taskrunner <- Uses Ido as a frontend

;;; Manual

Install these required packages:

projectile
async
cl-lib
And one or more of these:
- ivy-taskrunner <- Uses ivy as a frontend
- helm-taskrunner <- Uses helm as a frontend
- ido-taskrunner <- Uses Ido as a frontend

Then put this folder in your load-path, and put this in your init:

(require 'taskrunner)

;; Usage

Please see README for more details on the interfaces and customizable options
available.  This package is not meant to be used itself unless you are
developing a new frontend or would like to retrieve information about the
available tasks in a project/directory.

;; Credits

This package would not have been possible without the following
packages:
grunt.el[1] which helped me retrieve the tasks from grunt
gulp-task-runner[2] which helped me retrieve the tasks from gulp
helm-make[3] which helped me figure out the regexps needed to retrieve
             makefile targets

 [1] https://github.com/gempesaw/grunt.el
 [2] https://github.com/NicolasPetton/gulp-task-runner/tree/877990e956b1d71e2d9c7c3e5a129ad199b9debb
 [3] https://github.com/abo-abo/helm-make
