Emacs input events are limited to keys, mouse actions, and a few
special types.  Simulacrum extends this by letting you define custom
event types that carry arbitrary data.  This is useful when an
external process (e.g., a voice control engine) needs to invoke
commands with structured arguments through the command loop.

Example usage:

  (simulacrum-define-event-type my-event)

  (keymap-global-set "<my-event>"
                     (simulacrum-command
                      (lambda (n) (message "Got %s" n))))

  (simulacrum-generate-event 'my-event 42)

When the command loop handles the generated event, it will execute
the command and print "Got 42".
