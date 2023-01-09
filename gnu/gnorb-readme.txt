1 Gnorb
═══════

  Glue code between the Gnus, Org, and BBDB packages for Emacs.

  This package connects Emacs-based email, project management, and
  contact management a little more closely together. The goal is to
  reduce friction when manipulating TODOs, contacts, messages, and
  files.

  Probably the most interesting thing Gnorb does is tracking
  correspondences between Gnus email messages and Org headings. Rather
  than "turning your inbox into a TODO list", as some software puts it,
  Gnorb (kind of) does the opposite: turning your TODO headings into
  mini mailboxes. See the Info manual for details.

  *Note for previous users*: If you were using Gnorb from Github before
  it shifted to the Elpa repository, the email tracking mechanism has
  changed, please see the manual for details.


1.1 Known bugs/issues
─────────────────────

1.1.1 Gnus Registry
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Prior to late December, 2014, the Gnus registry had some issues with
  preserving "precious" entries while pruning.

  When the registry approaches its maximum size it will delete excess
  entries, a process referred to as "pruning". "Precious" entries are
  those that contain important information: they should not be pruned.

  Gnorb uses the registry to track associations between messages and Org
  headings, and marks those entries as precious. The entire process of
  tracking, in fact, relies on these entries being preserved, and Gnorb
  goes to some lengths to protect this information. Older versions of
  the registry could nevertheless delete those entries.

  These issues are fixed circa the end of December, 2014, around "Ma
  Gnus v0.12", whatever that means. If you think there's a possibility
  your registry is full, and associations are being deleted, you might
  consider upgrading to a recent Gnus.


1.1.2 Multiple Associations
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Gnorb theoretically supports email messages being associated with
  multiple Org headings. In practice, however, this situation hasn't
  been thought through completely, and you may experience weirdness. If
  you do, and you have some ideas about how it should be handled, please
  contact the author and suggest them.


1.2 Installation
────────────────

  Gnorb is developed inside the Elpa repository – install with M-x
  package-install RET gnorb RET. There is a [Github repository], but the
  code there is stale as of March 2017. Any issues opened there will be
  addressed, though obviously pull requests won't work. Prefer
  submitting bugs via `emacs-report-bug'.


[Github repository] <https://github.com/girzel/gnorb/>


1.3 Roadmap
───────────

1.3.1 More fully utilize nngnorb
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Instead of just being place to put nnir searches, the nngnorb server
  should have groups in its own right. Users will still be able to make
  ephemeral search groups if they like, but they'll also have the option
  of creating regular Gnus groups that track certain Org subtrees. These
  groups will be persistent, and they will auto-update, so it's possible
  to handle more TODO stuff from the Gnus group buffer. Copying a
  message into the group will set up tracking for the message; deleting
  it from the group will remove tracking.


1.3.2 Comprehensive views of related information
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  For instance, A `gnorb-view' command that takes a tags-todo search
  phrase (or a single Org heading ID), finds all relevant messages, Org
  headings, and BBDB records, and sets up a four-pane view: Org Agenda,
  BBDB buffer, Gnus Summary buffer, and Gnus Article buffer.

  Or something like that – more pondering is necessary.


1.3.3 Consider consolidating posting styles, personas, etc
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  There are many solutions out there for setting up "personas" in Gnus
  or elsewhere: wrappers for mail composition and reply that create
  certain identities by setting variables and mail headers.

  Do we need another one? Gnorb seems so well placed for this sort of
  thing: we've already got bbdb-posting-styles, and allowing further
  configuration based on, say, the Org tags of the subtree we're
  composing messages from… Or maybe it's just a case of NIH.


1.4 To do list
──────────────

1.4.1 TODO Agenda date-span message search
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Provide an Org Agenda command that does an email search for messages
  received in the visible date span, or day under point, etc. Make it
  work in the calendar, as well?


1.4.2 TODO Collect BBDB messages by thread
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  At present, when you collect message links on a BBDB contact, each
  message is a separate link. If you have lengthy conversations with
  this contact, you'll get a whole bunch of links with the same summary:
  not very useful. Provide an option to collect one /thread/ per link:
  each link represents the top-level message in the thread, and
  following the link opens a Summary buffer where the whole thread is
  visible.


1.4.3 TODO Automatic org-tagging for BBDB contacts
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  When messages from a contact are associated with an Org heading, make
  it possible for the contact to inherit that heading's tags
  automatically.


1.4.4 TODO gnorb-bbdb-view
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Provide a `gnorb-bbdb-view' command that opens a Summary buffer
  containing all the tracked messages from the contact(s) under point.


1.4.5 DONE Gnus message tagging
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Allow tagging of Gnus messages, by giving the message's registry entry
  an 'org-tags key.


1.4.6 DONE Email subtree export to doc and rtf
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  When using `gnorb-email-subtree', provide built-in options for
  exporting to doc and rtf attachments; these are such commonly-needed
  formats. Do the odt conversion automatically.


1.4.7 DONE Capture to child/subtree trigger actions
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Add trigger actions that create new sibling or child headings on the
  original Org heading.
