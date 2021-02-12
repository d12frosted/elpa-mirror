                          ____________________

                           ACE-JUMP-HELM-LINE

                              Junpeng Qiu
                          ____________________


Table of Contents
_________________

1 Setup
2 Usage
.. 2.1 Keys & UI
.. 2.2 Different Actions: move-only, persistent or select
.. 2.3 Automatic Idle Execution
.. 2.4 Line Hints Preview
3 Example settings
4 Demos(only showing the basic feature)
5 Similar Package
6 Acknowledgment


[[file:http://melpa.org/packages/ace-jump-helm-line-badge.svg]]
[[file:http://stable.melpa.org/packages/ace-jump-helm-line-badge.svg]]

*Ace-jump to a candidate in helm window.*

This package makes use of the `avy.el'.


[[file:http://melpa.org/packages/ace-jump-helm-line-badge.svg]]
http://melpa.org/#/ace-jump-helm-line

[[file:http://stable.melpa.org/packages/ace-jump-helm-line-badge.svg]]
http://stable.melpa.org/#/ace-jump-helm-line


1 Setup
=======

  ,----
  | (add-to-list 'load-path "/path/to/ace-jump-helm-line.el")
  | (require 'ace-jump-helm-line)
  `----

  You can use the following code to bind `ace-jump-helm-line' to a
  key(say, C-'):
  ,----
  | (eval-after-load "helm"
  | '(define-key helm-map (kbd "C-'") 'ace-jump-helm-line))
  `----


2 Usage
=======

  When in a helm session, for example, after you call `helm-M-x', you
  can use your key binding(for example, C-') to invoke
  `ace-jump-helm-line'. See the following demos.

  *Note*: Since *2016-02-19*, you can configure `ace-jump-helm-line' in
  a similar way as `avy'. The old-fashioned variable
  `ace-jump-helm-line-use-avy-style' is discarded now. There is no
  effect by setting this variable(I dropped this variable because `avy'
  has become much more configurable since I first developed this
  package).


2.1 Keys & UI
~~~~~~~~~~~~~

  You can customize following variables:
  1. `ace-jump-helm-line-keys': the keys to be used for
     `ace-jump-helm-line'. If you don't set this variable, `avy-keys'
     will be used.
  2. `ace-jump-helm-line-style': You can set the styles to be used for
     `ace-jump-helm-line'. The values can be `pre', `at', `at-full',
     `post', and `de-bruijn', the same as `avy-style'. If you don't set
     this variable, `avy-style' will be used.
  3. `ace-jump-helm-line-background': Whether you want to use a
     background or not. The default value is `nil'.

  For old version users: if you want to achieve the same effect of
    `(setq ace-jump-helm-line-use-avy-style nil)', use the following
    code:
  ,----
  | (setq ace-jump-helm-line-keys (number-sequence ?a ?z))
  | (setq ace-jump-helm-line-style 'at)
  | (setq ace-jump-helm-line-background t)
  `----


2.2 Different Actions: move-only, persistent or select
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  You can now specify the action that will be executed after the cursor
  has been moved to the candidate. This is controlled by the value of
  `ace-jump-helm-line-default-action'. Three different kinds of values
  are available:
  1. `nil' or `move-only': This is the default one. Just move the cursor
     to the candidate and do nothing.
  2. `persistent': After the cursor has been moved to the candidate,
     execute the persistent action on that candidate.
  3. `select': After the cursor has been moved to the candidate, select
     the candidate and exit the helm session.

  Thanks to `avy' 0.4.0, we can now switch the action after we see the
  avy prompt. Three different keys can be used to switch the action:
  1. `ace-jump-helm-line-move-only-key'
  2. `ace-jump-helm-line-persistent-key'
  3. `ace-jump-helm-line-select-key'

  For example, if we have following settings:
  ,----
  | (setq ace-jump-helm-line-default-action 'select)
  | (setq ace-jump-helm-line-select-key ?e) ;; this line is not neeeded
  | ;; Set the move-only and persistent keys
  | (setq ace-jump-helm-line-move-only-key ?o)
  | (setq ace-jump-helm-line-persistent-key ?p)
  `----

  Say after we invoke `ace-jump-helm-line', we can use f to jump to a
  candidate. Since the default action is `select', the candidate will be
  automatically selected and the helm session will be ended after the
  cursor has been moved to it. But suddenly I change my mind and only
  want to move to it. Instead of pressing f, I can press of where o is
  defined by the `ace-jump-helm-line-move-only-key' and is used to
  switch the action to `move-only'. Similarly, if I press pf, then the
  persistent action on the candidate will be executed.

  Note in this example, setting `ace-jump-helm-line-select-key' has no
  effect because the default action is `select'. It makes no senses that
  we need to have an extra key to switch to the `select' action. So if
  your default action is `nil' or `move-only',
  `ace-jump-helm-line-move-only-key' is not needed and
  `ace-jump-helm-line-persistent-key' is not needed if your default
  action is `persistent'. However, you're *safe* to set these variables
  regardless of your default action since the variable corresponding to
  your default action will just be ignored.

  If you wonder why this feature is useful, here is an example: if you use
  `helm-find-files' and set the default action to be `select', you can now
  use `ace-jump-helm-line-persistent-key' to complete the directory name
  instead of opening the directory in dired. This means you can use
  `ace-jump-helm-line' until you finally find the target file.

  For compatibility issues, there are also two identical pre-defined
  commands: `ace-jump-helm-line-and-select' and
  `ace-jump-helm-line-execute-action'. Their default action is to select
  the candidate and exit the helm session. Now you can achieve the same
  effect using `ace-jump-helm-line' by the following setting:
  ,----
  | (setq ace-jump-helm-line-default-action 'select)
  `----


2.3 Automatic Idle Execution
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  `ace-jump-helm-line' can be automatically executed if there is no
  input after the user launches a helm command. The delay can be
  specified by setting the variable `ace-jump-helm-line-idle-delay' in
  seconds. The default value is 1.

  Use the following code to enable this feature for a helm command, say,
  `helm-mini':
  ,----
  | (ace-jump-helm-line-idle-exec-add 'helm-mini)
  `----

  After adding this setting, `ace-jump-helm-line' will be automatically
  triggerred if there is no input for `ace-jump-helm-line-idle-delay'
  seconds after `helm-mini' is called.

  To remove it, use:
  ,----
  | (ace-jump-helm-line-idle-exec-remove 'helm-mini)
  `----

  Note this feature is *experimental*. Please file an issue if you find
  any problems. As I couldn't find good documentation about adding hooks
  to a helm command, the implementation is a simple yet dirty hack. And
  don't try to set the value of `ace-jump-helm-line-idle-delay' to be
  `nil'. It doesn't work.


2.4 Line Hints Preview
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  You can preview the line hints without invoking `ace-jump-helm-line' by
  enabling `ace-jump-helm-line-autoshow-mode'. This is similar to `linum-mode'.
  With `avy-style' set to `at-full', the result is shown below:
  https://github.com/cute-jumper/ace-jump-helm-line/screencasts/autoshow.png

  Or if you may prefer to show the hints using `linum-mode', you can set
  `ace-jump-helm-line-autoshow-use-linum' to `t':
  ,----
  | (setq ace-jump-helm-line-autoshow-use-linum t)
  `----

  The result:
  https://github.com/cute-jumper/ace-jump-helm-line/screencasts/autoshow-linum.png


3 Example settings
==================

  ,----
  | (eval-after-load "helm"
  | '(define-key helm-map (kbd "C-'") 'ace-jump-helm-line))
  | ;; or if using key-chord-mode
  | ;; (eval-after-load "helm"
  | ;;  '(key-chord-define helm-map "jj" 'ace-jump-helm-line))
  | (setq ace-jump-helm-line-style 'pre)
  | (setq ace-jump-helm-line-background t)
  | (setq ace-jump-helm-line-default-action 'select)
  | (setq ace-jump-helm-line-select-key ?e) ;; this line is not neeeded
  | ;; Set the move-only and persistent keys
  | (setq ace-jump-helm-line-move-only-key ?o)
  | (setq ace-jump-helm-line-persistent-key ?p)
  | ;; enable idle execution for `helm-mini'
  | (ace-jump-helm-line-idle-exec-add 'helm-mini)
  | ;; enable hints preview
  | (ace-jump-helm-line-autoshow-mode +1)
  | ;; use `linum-mode' to show
  | (setq ace-jump-helm-line-autoshow-mode-use-linum t)
  `----


4 Demos(only showing the basic feature)
=======================================

  The following demo are recorded in pre-0.4 version. It's a little
  out-dated.

  Use `avy' style to jump to a helm candidate:
  [./screencasts/avy-jump-style.gif]

  Or use a different style similar to `ace-jump-mode' (by setting the
  values of `ace-jump-helm-line-keys', `ace-jump-helm-line-style' and
  `ace-jump-helm-line-background'):
  [./screencasts/ace-jump-mode-style.gif]

  The new features after v0.4 are not recorded yet.:-(


5 Similar Package
=================

  [This issue of Helm] has been solved by adding a new minor mode
  `helm-linum-relative-mode' to `linum-relative'. You can take a look if
  you don't like `avy' and want to find an alternative. As a heavy user
  of `avy', I don't find the way that `helm-linum-relative-mode'
  provides very appealing. Thanks to `avy', this package provides more
  customizations and more consistent user experience for `avy' users.


  [This issue of Helm] https://github.com/emacs-helm/helm/issues/1257


6 Acknowledgment
================

  - Thank [Oleh Krehel] for the awesome [avy] package.
  - Thank @hick for the original idea.


  [Oleh Krehel] https://github.com/abo-abo/

  [avy] https://github.com/abo-abo/avy
