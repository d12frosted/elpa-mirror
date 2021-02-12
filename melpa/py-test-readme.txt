py-test gives you the ability to define testing projects and, based
on those projects, run a single test that's defined in the current
buffer, all of the tests that you have defined in the current buffer,
or all of the tests that you have defined in the current buffers's
parent directory.

; Installation

From MELPA:

M-x package-install RET py-test RET

Manually:

Clone the repo:

git clone https://github.com/Bogdanp/py-test.el ~/sandbox/py-test.el

Add it to your `.emacs`:

(add-to-list 'load-path (expand-file-name "~/sandbox/py-test.el"))
(require 'py-test)

; Usage

Define a project.

(py-test-define-project
 :name "My Project"
 :python-command "python"
 :base-directory (expand-file-name "~/sandbox/my-project-home/")
 :test-runner (expand-file-name "~/sandbox/my-project-home/tests/runner.py")
 :working-directory (expand-file-name "~/sandbox/my-project-home/tests/"))

Open a file belonging to that project:

C-x C-f ~/sandbox/my-project-home/tests/subdirectory/test_something.py RET

Run all of the tests that were defined in that file:

M-x py-test-run-file RET

Run all of the tests that were defined in that file's parent directory:

M-x py-test-run-directory RET

Jump to a single test function, method or class and run just that:

M-x py-test-run-test-at-point RET

; Extras

`py-test' is also configurable through the following variables (use
`describe-variable' for more info):

  * py-test-*mode-line-face-shenanigans-on*
  * py-test-*mode-line-face-shenanigans-timer*
  * py-test-*default-buffer-name*
  * py-test-*default-test-runner*
  * py-test-*test-path-separator*

In addition, `py-test' defines the following faces:

  * py-test-*mode-line-green-face*
  * py-test-*mode-line-inactive-green-face*
  * py-test-*mode-line-red-face*
  * py-test-*mode-line-inactive-red-face*
