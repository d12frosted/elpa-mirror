Installation:
  - Put `protobuf-mode.el' in your Emacs load-path.
  - Add this line to your .emacs file:
      (require 'protobuf-mode)

You can customize this mode just like any mode derived from CC Mode.  If
you want to add customizations specific to protobuf-mode, you can use the
`protobuf-mode-hook'. For example, the following would make protocol-mode
use 2-space indentation:

  (defconst my-protobuf-style
    '((c-basic-offset . 2)
      (indent-tabs-mode . nil)))

  (add-hook 'protobuf-mode-hook
    (lambda () (c-add-style "my-style" my-protobuf-style t)))

Refer to the documentation of CC Mode for more information about
customization details and how to use this mode.

TODO:
  - Make highlighting for enum values work properly.
  - Fix the parser to recognize extensions as identifiers and not
    as casts.
  - Improve the parsing of option assignment lists. For example:
      optional int32 foo = 1 [(my_field_option) = 4.5];
  - Add support for fully-qualified identifiers (e.g., with a leading ".").
