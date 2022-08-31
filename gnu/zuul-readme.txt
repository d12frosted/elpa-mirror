# zuul.el

[![GNU-devel ELPA](https://elpa.gnu.org/devel/zuul.svg)](http://elpa.gnu.org/devel/zuul.html)
[![builds.sr.ht status](https://builds.sr.ht/~niklaseklund/zuul.el/commits/main/.build.yml.svg)](https://builds.sr.ht/~niklaseklund/zuul.el/commits/main/.build.yml?)

# Introduction

Browse [Zuul](https://zuul-ci.org/) build outputs from Emacs. The `zuul.el` package provides functionality to communicate with Zuul through its [Zuul REST API](https://zuul-ci.org/docs/zuul/latest/rest-api.html).

The `zuul-log-mode` major mode makes it as comfortable to browse a build log as it would be to navigate a local compilation. The package implements a custom filename parser for errors in the logs which allows Emacs to open the correct project file when an error is encountered in the log, even though the absolute path may not be found on the local machine.

# Configuration

A minimal `use-package` configuration.

``` emacs-lisp
(use-package zuul
  :custom ((zuul-base-url "https://base.url.to.zuul.net")
           (zuul-tenant "tenant1")
           (zuul-tenant-configs
            '((:name "tenant1"
                     :project-roots (("foo" . "~/git/foo-repo")
                                     ("baz" . "~/git/baz-repo")))
              (:name "tenant2"
                     :project-roots (("bar" . "~/git/bar-repo")))))))
```

# Usage

The package doesn't provide any commands, except those used by the `zuul-log-mode`. Other packages, or users themselves, needs to implement commands because retrieving builds or buildsets requires knowledge that might not be general. An example of a package that integrates with `zuul.el` is [egerrit-zuul](https://git.sr.ht/~niklaseklund/egerrit/tree/main/egerrit-zuul.el). It provides the command `egerrit-zuul-open-build-log` which can be used as inspiration.

The functions `zuul-get-builds` and `zuul-get-buildsets` needs to be called to retrieve builds and buildsets from Zuul. Both functions accepts multiple input parameters specified as keys in the call. The simplest example would be to use a `change` number. 

``` emacs-lisp
;; For buildsets
(zuul-get-buildsets :change "300203")

;; For builds
(zuul-get-builds :change "300203")
```

A query to retrieve builds or buildsets can be provided as input to the `zuul-open-build-log` in order to view a specific build log.

``` emacs-lisp
;; Query provided as a list
(zuul-open-build-log
 '(zuul-get-buildsets
   :change "300203"))

;; Query provided as a function
(zuul-open-build-log
 (lambda ()
   '(zuul-get-builds
     :change "300203")))
```

# Zuul log mode

The major mode `zuul-log-mode` provides the following commands.

| Name                       | Binding | Description                                |
|----------------------------|---------|--------------------------------------------|
| zuul-switch-build          | C-c C-b | Switch to another build                    |
| zuul-switch-buildset       | C-c C-s | Switch to a build from a specific buildset |
| zuul-run-build-command     | C-c C-r | Run build command from build log           |
| zuul-previous-command      | C-c C-p | Go to previous command in build log        |
| zuul-next-command          | C-c C-n | Go to next command in build log            |
| zuul-open-build-in-browser | C-c C-o | Open build in browser                      |
| zuul-previous-build        | C-c [   | Switch to previous build                   |
| zuul-next-build            | C-c ]   | Switch to next build                       |
| zuul-quit-build            | C-c C-q | Quit and delete build log buffers          |

It also integrates with the following built in features:
- `imenu`: navigate to beginning of tasks in the build log
- `eldoc`: echo descriptive information about where in the log point are

# Customization

The package provides the following customizable variables.

| Name                               | Description                                                |
|------------------------------------|------------------------------------------------------------|
| `zuul-base-url`                    | Base URL to Zuul                                           |
| `zuul-tenant`                      | Zuul tenant                                                |
| `zuul-tenant-configs`              | A list of tenant configurations                            |
| `zuul-build-annotation`            | A list of annotations to display for a build               |
| `zuul-buildset-annotation`         | A list of annotations to display for a buildset            |
| `zuul-build-command-annotation`    | A list of annotations to display for a build command       |
| `zuul-build-imenu-annotation`      | A list of annotations to display for a imenu               |
| `zuul-build-display-buffer-action` | The configuration for display-buffer when opening a build. |
| `zuul-add-builds-to-buildset`      | If set to t builds will be added to buildsets              |

# Remote support

The `zuul.el` package supports [Connection Local Variables](https://www.gnu.org/software/emacs/manual/html_node/elisp/Connection-Local-Variables.html) which allows the user to customize the `zuul-tenant-configs` variable when running on a remote host. In this example `zuul-tenant-configs` are configured the same for all remote hosts.

``` emacs-lisp
(connection-local-set-profile-variables
 'remote-zuul
 '((zuul-tenant-configs . ((:name "foo"
                            :project-roots (("bar" . "~/other_location/bar")))))))

(connection-local-set-profiles
 '(:application tramp :protocol "ssh") 'remote-zuul)
```

# Contributions

The package is part of [GNU ELPA](https://elpa.gnu.org/) which means that if you want to contribute you must have a [copyright assignment](https://www.gnu.org/software/emacs/manual/html_node/emacs/Copyright-Assignment.html).
