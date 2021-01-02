org-runbook provides heirarchical runbook commands from org file accessible directly from buffers.
Main entry points include `org-runbook-execute', `org-runbook-switch-to-major-mode-file',
and `org-runbook-switch-to-projectile-file'

org-runbook lets you take org files structured like

#### MAJOR-MODE.org
```
* Build
#+BEGIN_SRC shell
cd {{project_root}}
#+END_SRC

** Quick
#+BEGIN_SRC shell
make quick
#+END_SRC

** Clean
#+BEGIN_SRC shell
make clean
#+END_SRC

** Prod
#+BEGIN_SRC shell
make prod
#+END_SRC
```
and exposes them for easy access in buffers with corresponding major mode.
So, the function [org-runbook-execute](org-runbook-execute) has the following completions when the current buffer's major mode is MAJOR-MODE:
```
Build >> Quick
Build >> Clean
Build >> Prod
```
Each of these commands is the concatenation of the path of the tree.  So for example, Build >> Quick would resolve to:
```
cd {{project_root}}
make quick
```
If projectile-mode is installed, org-runbook also pulls the file named PROJECTILE-PROJECT-NAME.org.
All files in [org-runbook-files] are also pulled.
Commands will resolve placeholders before evaluating.  Currently the only available placeholder is {{project_root}}
which corresponds to the projectile-project-root of the buffer that called `org-runbook-execute'
