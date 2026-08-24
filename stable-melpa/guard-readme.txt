
`guard' is a lightweight, graph-based init framework for managing Emacs
configuration modules.  It allows you to structure your `init.el` into
named, hierarchical sections, selectively enable or disable subsystems
and override behavior per machine.

=============================================================================
1. BASIC USAGE
=============================================================================

Call `guard-initialize' early in your `init.el`.  Then call `guard-config' to
load the tweak-file.  Then wrap setup code in `guard-section' blocks:

  (require 'guard)
  (guard-initialize)
  (guard-config) ; Loads local tweaks from `guard-tweak-file`

  (guard-section ui ()
    "Various ui options"
    (tool-bar-mode -1)
    (scroll-bar-mode -1))

  (guard-section themes (:parents (ui))
    (load-theme 'modus-vivendi t))


=============================================================================
2. SECTION DEFINITION
=============================================================================

A section is defined with:

(guard-section [name] (<options>)
  <optional docstring>
  <optional body>)

If a section starts with a string, that acts as its doscstring.

=============================================================================
3. DEPENDENCIES & INHERITANCE
=============================================================================

A section can have any number of parent sections.

Sub-sections can be declared explicitly via `:parents':

  (guard-section Lisp (:parents (programming))
      (add-hook 'emacs-lisp-mode-hook #'enable-paredit-mode))

or implicitly by nesting `guard-section` blocks within each other:

  (guard-section programming ()
    (guard-section Lisp ()
      (add-hook 'emacs-lisp-mode-hook #'enable-paredit-mode)))

The parents don't have to be declared beforehand.  If a section is first
introduced as a parent of a section currently being defined, the parent is
also defined at that moment.

If a section has no parents, it's parent is either guard-parent-node or the
wrapping section (this has precedence).

A section wrapped in an other section will always have the wrapping section
as a (maybe transitive) parent.

=============================================================================
4. Allowing/disallowing sections
=============================================================================

Allowed sections will run during initialization and disallowed will not.

A section is allowed either if it is *explicitly allowed* or if *all* of its
parents are allowed.
A section can also be *explicitly disallowed* in which case it is disallowed.

All sections are transitive children of guard-parent-node which is by default
allowed.  This means that with no configuration, all sections are allowed.
Explicitly allowing/disallowing some section has the effect of allowing or
disallowing all transitive dependencies of the section.

For explicitly allowing a section use `guard-allow':

  (guard-allow (section1 ...)
    <optional body>)

The symmetric is `guard-disallow' for explicitly disallowing a section:

  (guard-disallow (section1 ...)
    <optional body>)

Both these operations have a body which will run *after* explicitly allowing
or disallowing the argument sections.
This allows for allowing part of a tree easily like:

  (guard-disallow (programming-languages)
    (guard-allow (python)))

The above can be read as `Disallow all programming languages except python`.
Note that the above is also equivalent with:

  (guard-disallow (programming-languages))
  (guard-allow (python))

The optional body is just a visual convenienve.

=============================================================================
5. Mutually exclusive sections
=============================================================================

A section can have the `:default-child' attribute:

  (guard-section completion (:default-child vertico))

`completion' is now a `xor` section and all of its children will be disabled
except `vertico'.
To override the chosen child (even though it is possible with `guard-allow'
and `guard-disallow' commands) you can use:

  (guard-choose completion helm)

This will make helm the default child.

=============================================================================
6. Overriding sections
=============================================================================

A section can be overriden with:

  (guard-override <place> <section>
    <body>)

Here <place> can be:
  - `before': <body> will be executed before the code in the section
  - `after': <body> will be executed after the code in the section
  - `over': <body> will be executed instead of the code in the section

=============================================================================
7. Introspection
=============================================================================

Run `M-x guard-dot` to open the `*guard-dot*` buffer containing a Graphviz DOT
representation of your configuration hierarchy.  This also contains runtime
information for each section during initialization.

Run `M-x guard-look` to inspect the status of a section along with its
parents and children.
