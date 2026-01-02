Replace long prefixes with short ones visually using overlays.
Example: "application-config-manager--" -> "acm:"

Basic usage:

    (visual-shorthands-add-mapping "application-config-manager--" "acm:")
    (visual-shorthands-mode 1)

Abbreviates PREFIXES only, not whole symbols.
