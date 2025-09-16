
; Installation

This package has one main requirement: `magit', for
`magit-section'.  Assuming this package is satisfied, the
`universal-sidecar.el' file may be placed on the load path and
`require'd.

; Usage

The `universal-sidecar-toggle' command will bring up a per-frame
"sidecar" buffer.  These sidecar buffers are used to show
information about or related to the focused buffer.  Information is
shown in *sections*, which are configured using the
`universal-sidecar-sections' variable.  The behavior of this
variable, and expected interface is described below in
configuration.

Additionally, to make sure that the sidecar buffer is updated, it's
necessary to advise several functions.  This can be done
automatically using the `universal-sidecar-insinuate' function,
which will advise functions listed in
`universal-sidecar-advise-commands'.  This may be undone with
`universal-sidecar-uninsinuate'.  Additionally,
`universal-sidecar-insinuate' will add `universal-sidecar-refresh'
to the `focus-in-hook', and will set an idle timer to refresh all
sidecar buffers if `universal-sidecar-enable-timer' is non-nil
(idle time configured with `universal-sidecar-refresh-time').
Buffers can be ignored by modifying the
`universal-sidecar-ignore-buffer-regexp', or using the (irregular)
`universal-sidecar-ignore-buffer-functions' hook.  This hook will
be run with an argument (the buffer) and run until a non-nil
result.

;; Configuration

The name of the sidecar buffer is configured using
`universal-sidecar-buffer-name-format', which must contain `%F', a
representation of the description of the frame.

Which sections are shown is configured using
`universal-sidecar-sections', which is a list of functions or
functions-with-arguments.  For example, let's consider the section
`buffer-git-status', which shows git status.  This section allows a
keyword argument, `:show-renames', which defaults to t.  If we want
the default behavior, we would configure it using

    (add-to-list 'universal-sidecar-sections 'buffer-git-status)

However, if we want the opposite behavior (don't show renames),
we'd configure it as shown below.

(add-to-list 'universal-sidecar-sections '(buffer-git-status :show-renames t))

Note that using `add-to-list' is generally bad practice, as the
sections will be run in the order they're present in the list.

Next, the displayed buffer name is generated using
`universal-sidecar-buffer-id-format' and
`universal-sidecar-buffer-id-formatters'.  These may be customized
to your liking.  Note: `universal-sidecar-buffer-id-formatters' is
an alist of character/function pairs.  The functions should take as
their first (and only mandatory) argument the buffer for which the
sidecar is being displayed.

Additionally, fontification of sections may be performed by the
`universal-sidecar-fontify-as' macro.  This macro includes a
provision to allow you to set some buffer-local variables before
the fontification mode is enabled.  This is done using
`universal-sidecar-fontify-default-bindings', which takes a list of
lists, such that the first element of the list is the name of the
buffer, and the second element is the expression to evaluate the
binding for.

Finally, sidecar buffers are displayed using `display-window'.
This means that how the buffer is displayed is easily configurable
from `display-buffer-alist'.  The author's configuration is shown
below as an example.  In particular, using the
`display-buffer-in-side-window' display action is suggested, as
it's generally not helpful to select the sidecar window through
normal window motion commands

    (add-to-list 'display-buffer-alist
                 '("\\*sidecar\\*"
                   (display-buffer-in-side-window)
                   (slot . 0)
                   (window-width . 0.2)
                   (window-height . 0.2)
                   (preserve-size t . t)
                   (window-parameters . ((no-other-window . t)
                                         (no-delete-other-windows . t)))))


Additionally, buffers can be ignored by setting the buffer-local
value of `universal-sidecar-ignore-buffer' to non-nil.

Finally, errors in sections or section definitions are by default
logged to the *Warnings* buffer.  This is done in a way to allow
for debugging.  Moreover, the logging can be disabled by setting
`universal-sidecar-inhibit-section-error-log' to non-nil, in which
case (unless debugging is enabled) these errors will be ignored.

; Section Functions

The basic installation of `universal-sidecar' does not include any
section functions.  This is to reduce the number of dependencies of
the package itself so that it may be used as a library for others,
or to help integrate multiple packages.  A
`universal-sidecar-sections.el' package is available as well, which
will have simple section definitions that may be of use.

However, implementation of functions is generally straight-forward.
First, sections are simply functions which take a minimum of two
arguments, `buffer', or the buffer we're generating a sidecar for,
and `sidecar', the sidecar buffer.  When writing these section
functions, it is recommended to avoid writing content to `sidecar'
until it's verified that the information needed is available.  That
is **don't write sections without bodies**.

To aid in defining sections, the `universal-sidecar-define-section'
and `universal-sidecar-insert-section' macros are available.  The
first defines a section which can be added to
`universal-sidecar-sections'.  The second simplifies writing
sections by adding proper separators and headers to the sidecar
buffer.  We will demonstrate both below.

    (universal-sidecar-define-section fortune-section (file title)
                                      (:major-modes org-mode
                                                    :predicate (not (buffer-modified-p)))
      (let ((title (or title
                       (and file
                            (format "Fortune: %s" file))
                       "Fortune"))
            (fortune (shell-command-to-string (format "fortune%s"
                                                      (if file
                                                          (format " %s" file)
                                                        "")))))
        (universal-sidecar-insert-section fortune-section title
          (insert fortune))))

Note: the arguments (`file' and `title') are *keyword* arguments.
Additionally, you specify that this section only applies when
`buffer' is a descendent of `:major-modes' which can be either a
symbol or a list of symbols.  `:predicate' is used to specify a
somewhat more complex predicate to determine if the section should
be generated.

This section could be added in any of the following ways:

    (add-to-list 'universal-sidecar-sections 'fortune-section)
    (add-to-list 'universal-sidecar-sections '(fortune-section :file "definitions"))
    (add-to-list 'universal-sidecar-sections '(fortune-section :title "O Fortuna!"))
    (add-to-list 'universal-sidecar-sections '(fortune-section :file "definitions" :title "Random Definition"))

Finally, section text can be formatted and fontified as if it was
in some other mode, for instance, `org-mode' using
`universal-sidecar-fontify-as'.  An example is shown below.

    (universal-sidecar-fontify-as org-mode ((org-fold-core-style 'overlays))
      (some-function-that-generates-org-text)
      (some-post-processing-of-org-text))


;; Changelog

v1.2.3 (2023-06-24): Pass package-lint and byte-compile-file with
minimal errors.

v1.2.4 (2023-07-17): Allow the sidecar's displayed buffer
identifier to be autogenerated using
`universal-sidecar-buffer-id-format' and
`universal-sidecar-buffer-id-formatters'.

v1.2.6 (2023-09-04): Fix type error in
`universal-sidecar-format-buffer-id'.

v1.2.7 (2023-09-04): Fix a byte compilation issue.

v1.3.0 (2023-09-14): Log errors, don't ignore them.

v1.4.0 (2023-09-22): Add
`universal-sidecar-inhibit-section-error-log' to control when
sidecar section errors are logged.

v1.4.3 (2024-01-03): Buffers can now be ignored using the
`universal-sidecar-ignore-buffer-regexp' and
`universal-sidecar-ignore-buffer-functions' variables.

v1.5.0 (2024-01-06): The macro `universal-sidecar-fontify-as' is
now available to fontify code as if in some major mode.

v1.5.1 (2024-01-14): `universal-sidecar-advise-commands' and
`universal-sidecar-unadvise-commands' now take arguments to allow
programmatic advising.

v1.5.2 (2024-01-15): `universal-sidecar-buffer-mode-hook' is now
customizable.

v1.8.0 (2025-07-30): local variable
`universal-sidecar-ignore-buffer' added.
