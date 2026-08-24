Rule-based email automation for mu4e.  Configure `mu4e-autotask-rules' with a
list of rules that match an incoming message by sender and/or subject and run
an action function on it, then call `mu4e-autotask-initialize' to expose the
dispatcher as a mu4e view action.

The package also provides building blocks for action functions: helpers to
read a message's raw text, MIME-part bodies, and attachments, plus an
`mu4e-autotask-email-template' struct and `mu4e-autotask-send-email' for
composing and sending templated outgoing mail.

Calendar invitations (messages mu flags `calendar') that no rule matches
are handled by a built-in RSVP flow when `mu4e-autotask-handle-icalendar'
is non-nil: prompt for accept / tentative / decline, send the iTIP reply
to the organizer, and optionally record the event in a Google Calendar via
org-gcal (see `mu4e-autotask-icalendar-event-target-function').

mu4e 1.12 or later is a runtime requirement; it ships with mu and is not an
ELPA package, so it is not listed in Package-Requires.
