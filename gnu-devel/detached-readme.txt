# detached.el

[![GNU ELPA](https://elpa.gnu.org/packages/detached.svg)](https://elpa.gnu.org/packages/detached.html)
[![GNU-devel ELPA](https://elpa.gnu.org/devel/detached.svg)](http://elpa.gnu.org/devel/detached.html)
[![MELPA](https://melpa.org/packages/detached-badge.svg)](https://melpa.org/#/detached)
[![MELPA Stable](https://stable.melpa.org/packages/detached-badge.svg)](https://stable.melpa.org/#/detached)
[![builds.sr.ht status](https://builds.sr.ht/~niklaseklund/detached.el/commits/main/.build.yml.svg)](https://builds.sr.ht/~niklaseklund/detached.el/commits/main/.build.yml?)

# Introduction

`detached.el` is a package to launch, and manage, detached processes. The idea is that these processes are detached from the Emacs process and the package can make Emacs seamlessly attach to these processes. This enables users to launch processes that can survive when Emacs itself is being shutdown. The package relies on the program [dtach](https://github.com/crigler/dtach), in order to make this functionality possible.

Internally the package transforms the detached process into a `detached-session` object, which essentially is a text-based representation of the process. All `detached-session` objects are stored in a lisp file, and the output of all sessions are captured into individual logs.

The package supports integration with multiple packages, here is a list of the built-in packages that are supported:

- `shell`
- `eshell`
- `compile`
- `org`
- `dired`

# Features

Since a `detached-session` contain all the output of the process as well as data such as, `what command` was run, `which directory` the process was launched etc, it opens up the possibility for the following features:

- `Unlimited scrollback:` All the output from a `detached-session` is always accessible
- `Remote support:` Full support for running on remote hosts. See `Remote support` section of the README
- `Notifications:` The package will monitor all detached sessions and notify when a session has finished
- `Post compilation`: The package will know the exit status of a session, which enables the package to post compile the output of a session to enable Emacs's built-in functionality of navigating between errors in the output.
- `Annotations:` When selecting a session all are presented with a rich set of annotations
- `Actions:` The package provides actions to act on a session:
  + `kill` a an active session
  + `rerun` a session
  + `copy` the output of a session
  + `diff` the output of two different sessions

# Installation

The package is available on [GNU ELPA](https://elpa.gnu.org) and [MELPA](https://melpa.org/), and for users of the [GNU Guix package manager](https://guix.gnu.org/) there is a guix package.

# Configuration

The prerequisite for `detached.el` is that the user has the programs `dtach` and `tail` installed.

## Use-package example

A minimal `use-package` configuration.

``` emacs-lisp
(use-package detached
  :init
  (detached-init)
  :bind (;; Replace `async-shell-command' with `detached-shell-command'
         ([remap async-shell-command] . detached-shell-command)
         ;; Replace `compile' with `detached-compile'
         ([remap compile] . detached-compile)
         ([remap recompile] . detached-compile-recompile)
         ;; Replace built in completion of sessions with `consult'
         ([remap detached-open-session] . detached-consult-session))
  :custom ((detached-show-output-on-attach t)
           (detached-terminal-data-command system-type)))
```

The users are required to call `detached-init`. This function orchestrates the integration with all other internal and external packages that `detached.el` supports. These are:

- `compile`
- `dired`
- `dired-rsync`
- `embark`
- `eshell`
- `org`
- `projectile`
- `shell`
- `vterm`

All of the integration are configured to enable lazy-loading. Meaning that if you are not a user of `projectile` that code that handles the integration will never load.

However if you do want to disable the integration with a specific package, or enable for a subset of the packages use the variables `detached-init-allow-list` or `detached-init-block-list`.

# Usage 

The idea is that users can choose to either:
- `create`: a detached session and attach to it
- `detach`: from a detached session
- `attach`: to a detached session

In the integration of `detached.el` with other packages these commands are always existent, with the exception for `org-mode`.

To detach from a `detached-session` in any of the modes, use the universal `detached-detach-session` command. The keybinding for this command is defined by the `detached-detach-key` variable, which by default has the value `C-c C-d`.

## General

To interact with a session the package provides the command `detached-open-session`. This provides a convenient completion interface, enriched with annotations to provide useful information about the sessions. The `detached-open-session` command is implemented as a do what I mean command. This results in `detached.el` performing different actions depending on the state of a session. The actions can be configured based on the `origin` of the session. The user can have one set of configurations for sessions started in `shell` which is different from those started in `compile`.

The actions are controlled by the customizable variables named `detached-.*-session-action`. They come preconfigured but if you don't like the behavior of `detached-open-session` these variables allows for tweaking the experience.

- If the session is `active`, call the sessions `attach` function
- If the session is `inactive` call the sessions `view` function, which by default performs a post-compile on the session if its status is `failure` otherwise the sessions raw output is opened.
    
The package also provides additional commands to interact with a session.

| Command (Keybinding)                | Description                                 |
|-------------------------------------|---------------------------------------------|
| detached-view-session (v)           | View a session's output                     |
| detached-attach-session (a)         | Attach to a session                         |
| detached-diff-session (=)           | Diff a session with another session         |
| detached-compile-session (c)        | Open the session output in compilation mode |
| detached-rerun-session (r)          | Rerun a session                             |
| detached-insert-session-command (i) | Insert the session's command at point       |
| detached-copy-session-command (w)   | Copy the session's shell command            |
| detached-copy-session-output (W)    | Copy the session's output                   |
| detached-kill-session (k)           | Kill an active session                      |
| detached-delete-session (d)         | Delete an inactive session                  |

These commands are available through the `detached-action-map`. The user can bind the action map to a keybinding of choice. For example

``` emacs-lisp
(global-set-key (kbd "C-c d") detached-action-map)
```

Then upon invocation the user can choose an action, keybindings listed in the table above, and then choose a session to perform the action upon. For those using `embark` this will not be necessary as `detached-init` sets up integration with embark actions.

## Shell command

The `detached-shell-command` is for the Emacs users that are accustomed to running shell commands from `M-x shell-command` or `M-x async-shell-command`.

## Shell

A minor mode named `detached-shell-mode` is provided, and will be enabled in `shell`. The commands that are implemented are:

| Command                       | Description                    | Keybinding          |
|-------------------------------|--------------------------------|---------------------|
| detached-shell-send-input     | Run command with detached      | <S-return>          |
| detached-shell-attach-session | Attach to a detached session   | <C-return>          |
| detached-detach-session       | Detach from a detached session | detached-detach-key |

## Eshell

A minor mode named `detached-eshell-mode` is provided, and will be enabled in `eshell`. The commands that are implemented are:

| Command                        | Description                    | Keybinding          |
|--------------------------------|--------------------------------|---------------------|
| detached-eshell-send-input     | Run command with detached      | <S-return>          |
| detached-eshell-attach-session | Attach to a detached session   | <C-return>          |
| detached-detach-session        | Detach from a detached session | detached-detach-key |

## Org babel

The package implements an additional header argument for `ob-shell`. The header argument is `:detached t`. When provided it will enable the code inside a src block to be run with `detached.el`. Since org is not providing any live updates on the output the session is created with `detached-sesion-mode` set to `create`. This means that if you want to access the output of the session you do that the same way you would for any other type of session. The `detached-org` works both with and without the `:session` header argument.

```
#+begin_src sh :detached t
    cd ~/code
    ls -la
#+end_src

#+RESULTS:
: [detached]
```

## Compile

The package implements the commands `detached-compile` and `detached-compile-recompile`, which are thin wrappers around the original `compile` and `recompile` commands. The users should be able to use the former as replacements for the latter without noticing any difference except from the possibility to `detach`.

## Consult

The command `detached-consult-session` is a replacement for `detached-open-session` using the [consult](https://github.com/minad/consult) package. The difference is that the consult command provides multiple session sources, which is defined in the `detached-consult-sources` variable. Users can customize which sources to use, as well as use individual sources in other `consult` commands, such as `consult-buffer`. The users can also narrow the list of sessions by entering a key. The list of supported keys are:

| Type                  | Key |
|-----------------------|-----|
| Active sessions       | a   |
| Inactive sessions     | i   |
| Successful sessions   | s   |
| Failed sessions       | f   |
| Hidden sessions       | SPC |
| Local host sessions   | l   |
| Remote host sessions  | r   |
| Current host sessions | c   |

# Customization

## Customizable variables

The package provides the following customizable variables.

| Name                                 | Description                                                                      |
|--------------------------------------|----------------------------------------------------------------------------------|
| detached-session-directory           | A host specific directory to store sessions in                                   |
| detached-db-directory                | A localhost specific directory to store the database                             |
| detached-dtach-program               | Name or path to the `dtach` program                                              |
| detached-shell-program               | Name or path to the `shell` that `detached.el` should use                        |
| detached-timer-configuration         | Configuration of the timer that runs on remote hosts                             |
| detached-annotation-format           | A list of annotations that should be present in completion                       |
| detached-command-format              | A configuration for displaying a session command                                 |
| detached-degraded-commands           | A list of commands that should be run in degraded mode                           |
| detached-notification-function       | Specifies which function to issue notifications with                             |
| detached-detach-key                  | Specifies which keybinding to use to detach from a session                       |
| detached-shell-command-initial-input | Enables latest value in history to be used as initial input                      |
| detached-filter-ansi-sequences       | Specifies if `detached.el` will use ansi-color to filter out escape sequences    |
| detached-show-output-command         | Specifies if `detached.el` should show the session's output when attaching to it |

Apart from those variables there is also the different `action` variables, which can be configured differently depending on the origin of the session.

| Name                                  | Description                                                     |
|---------------------------------------|-----------------------------------------------------------------|
| detached-shell-command-session-action | Actions for sessions launched with `detached-shell-command`     |
| detached-eshell-session-action        | Actions for sessions launched with `detached-eshell-send-input` |
| detached-shell-session-action         | Actions for sessions launched with `detached-shell-send-input`  |
| detached-compile-session-action       | Actions for sessions launched with `detached-compile`           |
| detached-org-session-action           | Actions for sessions launched with `detached-org`               |

## Remote support

The `detached.el` supports [Connection Local Variables](https://www.gnu.org/software/emacs/manual/html_node/elisp/Connection-Local-Variables.html) which allows the user to customize the variables used by `detached.el` when running on a remote host. This example shows how the following variables are customized for all remote hosts.

``` emacs-lisp
(connection-local-set-profile-variables
 'remote-detached
 '((detached-shell-program . "/bin/bash")
   (detached-session-directory . "~/tmp")
   (detached-dtach-program . "/home/user/.local/bin/dtach")))

(connection-local-set-profiles
 '(:application tramp :protocol "ssh") 'remote-detached)
```

## Completion annotations

Users can customize the appearance of annotations in `detached-open-session` by modifying the `detached-annotation-format`. The default annotation format is the following.

``` emacs-lisp
(defvar detached-annotation-format
  `((:width 3 :function detached--state-str :face detached-state-face)
    (:width 3 :function detached--status-str :face detached-failure-face)
    (:width 10 :function detached--host-str :face detached-host-face)
    (:width 40 :function detached--working-dir-str :face detached-working-dir-face)
    (:width 30 :function detached--metadata-str :face detached-metadata-face)
    (:width 10 :function detached--duration-str :face detached-duration-face)
    (:width 8 :function detached--size-str :face detached-size-face)
    (:width 12 :function detached--creation-str :face detached-creation-face))
  "The format of the annotations.")
```

## Show session context when attaching

By default the `detached-show-session-context` is set to t. This means that part of the output from a session will be shown when attaching to a session. The number of lines of the context is determined by `detached-session-context-lines`. The package uses `tail` in order to display the context.

## Metadata annotators

The user can configure any number of annotators to run upon creation of a session. The package comes with a function which captures the git branch name, if the session is started in a git repository.

This function can be added as an annotation function to the `detached-metadata-annotators-alist` together with a symbol describing the property.

``` emacs-lisp
(setq detached-metadata-annotators-alist '((branch . detached--metadata-git-branch)))
```

## Degraded commands

To be able to both attach to a dtach session as well as logging its output `detached.el` relies on the usage of `tee`. However it is possible that the user tries to run a command which involves a program that doesn't integrate well with tee. In those situations the output could be delayed until the session ends, which is not preferable.

For these situations `detached.el` provides the `detached-degraded-commands` variable. This is a list of regular expressions. Any command that matches any of the strings will be getting the property `degraded` set to true.
``` emacs-lisp
(setq detached-degraded-commands '("^ls"))
```

Here a command beginning with `ls` would from now on be considered degraded, hence `detached` will use `tail`to tail the sessions log instead of attaching to the `dtach` process.

## Colors in sessions

The package needs to use a trick to get programs programs such as `git` or `grep` to show color in their outputs. This is because these commands only use colors and ansi sequences if they are being run in a terminal, as opposed to a pipe. The package therefore has two different modes, either `plain-text` or `terminal-data`. The latter is now the default for all sessions. When in `terminal-data` mode the `script` tool is used to make programs run by `detached.el` think they are inside of a full-featured terminal, and therefore can log their raw terminal data.

The drawback is that there can be commands which generates escape sequences that the package supports and will therefore mess up the output for some commands. If you detect such an incompatible command you can add a regexp that matches that command to the list `detached-plain-text-commands`. By doing so `detached.el` will be instructed to run those commands in plain-text mode.

The tool `script` can have different options depending on version and operating system. The package requires the user to set the `detached-terminal-data-command` in the package configuration and with `connection-local-set-profiles` for remote sessions. It can either be set to a symbol or to a string.

## Chained commands

With `detached` there exist the possibility to use callback. This functionality makes it possible to create chained sessions, essentially starting a new session once a previous one is finished. Here is an example:

``` emacs-lisp
;; The detached commands are run in serial.
;; This is equivalent to run sleep 1 && ls && ls -la
(let* ((default-directory "/tmp")
       (detached-session-action
        `(,@detached-shell-command-session-action
          :callback (lambda (session1)
                      (when (eq 'success (detached-session-status session1))
                        (let ((default-directory (detached-session-working-directory session1))
                              (detached-session-action
                               `(,@detached-shell-command-session-action
                                 :callback (lambda (session2)
                                             (when (eq 'success (detached-session-status session2))
                                               (let ((default-directory (detached-session-working-directory session2)))
                                                 (detached-start-session "ls -la" t)))))))
                          (detached-start-session "ls" t)))))))
  (detached-start-session "sleep 1" t))
```

# Tips & Tricks

The `detached.el` package integrates with core Emacs packages as well as 3rd party packages. Integration is orchestrated in the `detached-init.el`. In this section you can find tips for integrations that are not supported in the package itself.

## Alert

By default `detached.el` uses the built in `notifications` library to issue a notification. This solution uses `dbus` but if that doesn't work for the user there is the possibility to set the `detached-notification-function` to `detached-state-transition-echo-message` to use the echo area instead. If that doesn't suffice there is the possibility to use the [alert](https://github.com/jwiegley/alert) package to get a system notification instead.

``` emacs-lisp
(setq detached-notification-function #'detached-extra-alert-notification)
```

# Versions

Information about larger changes that has been made between versions can be found in the `CHANGELOG.org`

# Support

The `detached.el` package should work on `Linux` and `macOS`. It is regularly tested on `Ubuntu` and `GNU Guix System`.

# Contributions

The package is part of [ELPA](https://elpa.gnu.org/) which means that if you want to contribute you must have a [copyright assignment](https://www.gnu.org/software/emacs/manual/html_node/emacs/Copyright-Assignment.html).

# Acknowledgments

This package wouldn't have been were it is today without these contributors.

## Code contributors

- [rosetail](https://gitlab.com/rosetail)
- [protesilaos](https://lists.sr.ht/~protesilaos)
- [Stefan Monnier](https://www.iro.umontreal.ca/~monnier)
- dpettersson
- [Greg Pfeil](http://technomadic.org)

## Idea contributors

- [rosetail](https://gitlab.com/rosetail) for all the great ideas and improvements to the package. Without those contributions `detached.el` would be a less sophisticated package.
- [Troy de Freitas](https://gitlab.com/ntdef) for solving the problem of getting `detached.el` to work with `filenotify` on macOS.
- [Daniel Mendler](https://gitlab.com/minad) for helping out in improving `detached.el`, among other things integration with other packages such as `embark` and `consult`.
- [Ambrevar](https://gitlab.com/ambrevar) who indirectly contributed by inspiring me with his [yes eshell is my main shell](https://www.reddit.com/r/emacs/comments/6y3q4k/yes_eshell_is_my_main_shell/). It was through that I discovered his [package-eshell-detach](https://github.com/Ambrevar/dotfiles/blob/master/.emacs.d/lisp/package-eshell-detach.el) which got me into the idea of using `dtach` as a base for detached shell commands.

