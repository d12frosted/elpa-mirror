Mantras, not macros! A system for defining, parsing, and acting on
user activity.

This package provides two main facilities:

1. A DSL for composing "mantras" to represent complex user
   actions.  Mantras are a more expressive form of keyboard macro,
   able to include conditions, loops, and programmatic logic.  This
   can be used to script user behavior, similar to how Selenium is
   used to automate web browsers.

2. A real-time parser that can match live user activity against
   arbitrary patterns and conditions.  This allows you to define
   patterns of "interesting" activity and trigger custom actions
   (including, commonly, mantras) when those patterns are detected.

Together, these components enable the creation of powerful tools
like intelligent repeat mechanisms (e.g., repeating actions that
involve completion UIs), creating contextual location histories
like the jump and change lists in Evil mode, or advanced command
recorders.
