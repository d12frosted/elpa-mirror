                               ━━━━━━━━━━
                                MINIMAIL
                               ━━━━━━━━━━


Minimail is a simple, non-blocking IMAP email client for Emacs.  It is a
rather new package but covers the basics needed for reading and sending
messages:

• Rendering of MIME content (via Gnus)
• Composing, replying to and forwarding messages
• Multi-account support
• OAuth login (at least under GNOME, see below)
• Message search
• Copying and moving messages between mailboxes (also archive, move to
  trash, move to junk folder)
• Sorting by thread, in two modes: shallow (just one nesting level,
  sorted by date, using server-side thread information if available) and
  hierarchical (full-blown message trees).

Here is a list of planned features:

• Watching for new messages and notifications
• Virtual mailboxes a.k.a. bookmarked searches
• Various optimizations, perhaps a persistent cache

Minimail is an [online] IMAP client.  It is intended to coexist
peacefully with other clients accessing the same account.  Moreover, it
is intended to remain no more complicated than your regular webmail app.
In line with that, the following are some features which are not
planned:

• Filtering (use server-side filtering instead)
• Offline access
• POP, NNTP, RSS, Maildir, instant messaging, microblogging, social
  media, virtual reality, etc.


[online] <https://www.rfc-editor.org/rfc/rfc1733>


1 Try it out
════════════

  Minimail comes pre-configured to access the Emacs mailing lists served
  by [Yhetil] via anonymous IMAP.  Just type `M-x
  minimail-show-mailboxes RET' to try it out.


[Yhetil] <https://yhetil.org/>


2 Configuration
═══════════════

  All account configuration is centralized in one variable,
  `minimail-accounts'.  It accepts many different options, so it might
  be convenient to explore it using the Customize interface, even if you
  later decide to simply copy the Lisp expression into your init file.

  In order to send emails, you should also set `mail-user-agent' to
  `minimail' and customize the variable `message-server-alist' from the
  [Message] package.

  Here is an illustrative example:

  ┌────
  │ (setq minimail-accounts
  │       '((gmail ;; This can be any symbol you like to identify the account
  │          :mail-address "somebody@gmail.com"
  │          :incoming-url "imaps://imap.gmail.com")
  │         (work ;; Assuming Evil Corp. uses "Google Workspace" as email provider
  │          :mail-address "webmaster@evilcorp.com"
  │          :incoming-url "imaps://imap.gmail.com"
  │          :signature (file "~/work/.signature"))
  │         (uni
  │          :mail-address "somebody@math.niceuni.edu"
  │          ;; Include a username in the IMAP server URL if it doesn't
  │          ;; match your email address.  Use `imap' as URL scheme if the
  │          ;; server only supports STARTTLS.
  │          :incoming-url "imap://username@imap.niceuni.edu"))
  │       mail-user-agent 'minimail
  │       message-server-alist
  │       '(("somebody@gmail.com" . "smtp smtp.gmail.com 465 somebody@gmail.com")
  │         ("webmaster@evilcorp.com" . "smtp smtp.gmail.com 465 webmaster@evilcorp.com")
  │         ("somebody@math.niceuni.edu" . "smtp smtp.niceuni.edu 587 username")))
  └────

  Reassuringly, you also need a password to read your emails.
  Credentials are handled by the standard [auth-source] mechanism.  This
  means that:

  • In the absence of any configuration, you would be queried for
    passwords when you start Minimail, and they remain cached for a
    couple of hours.
  • If any of the files pointed by the variable `auth-sources' exits,
    you will have the option to save the passwords.
  • You can customize `auth-sources' to use an alternative credentials
    source, such as your system's password manager.

  Note that some email providers require you to first create an "app
  password".  This option is sometimes listed under the misleading
  rubric of "enable less secure apps" (for Gmail, see [this]).

  Once you get the basics up and running, try `M-x customize-group
  minimail RET' to explore all customization options.


[Message] <https://www.gnu.org/software/emacs/manual/html_node/message>

[auth-source]
<https://www.gnu.org/software/emacs/manual/html_mono/auth.html>

[this] <https://support.google.com/accounts/answer/185833>

2.1 OAuth access
────────────────

  If instead of passwords you want to (or must) use the OAuth login
  mechanism, and you happen to already have the account in question set
  up in GNOME Online Accounts, then you can try this out:

  ┌────
  │ (push 'online-accounts auth-sources)
  └────

  It is possible, though not very likely, that this feature can be
  extended to other platforms.  Let me know if you have and hints or
  suggestions.


3 Usage
═══════

  The main entry points of this package are:

  • `minimail-show-mailboxes': Display the mailbox hierarchy of your
    accounts.
  • `minimail-find-mailbox': Directly open a mailbox chosen from the
    minibuffer.
  • `minimail-search': Search messages in a mailbox.

  Hopefully, operation is intuitive enough that we don't need to linger
  on that topic.  In a mailbox or message buffer, hit `h' to see a list
  of available commands.


4 Comparison with other packages
════════════════════════════════

  Minimail is, quite plainly, a reaction to [Gnus], the self-described
  “coffee-brewing, all singing, all dancing, kitchen sink newsreader”.
  So let's break this down.

  • /coffee-brewing/: Gnus has filtering, scoring, expiration rules and
    a myriad of features that are probably useful if you need to handle
    a deluge of emails and news articles.  Modern email services also
    offer some version of those features, so Minimail relies on that
    instead of brewing its own.
  • /all-singing/: Minimail is just an IMAP client, while Gnus has
    several backends in addition to IMAP, such as Usenet news (NNTP),
    website feeds (Atom and RSS) and local mail downloaded with an
    external tool.
  • /all-dancing/: Gnus blocks while performing network operations, so
    Minimail is the better dancer.
  • /kitchen-sink/: Gnus can wash your articles, whatever that means.
    Minimail is minimalist and, hopefully, easier to operate.
  • /newsreader/: Gnus is fundamentally a Usenet news client with email
    capabilities bolted on top.  While it's very good at both, it can be
    confusing to refer to emails as articles, mailboxes as groups, and
    so on.  Minimail uses the more familiar email terminology.

  [Rmail], [Notmuch] and [mu4e] take the entirely different /offline/
  approach: you first download all you messages and then work with them
  locally.


[Gnus] <https://www.gnus.org>

[Rmail]
<https://www.gnu.org/software/emacs/manual/html_node/emacs/Rmail.html>

[Notmuch] <https://notmuchmail.org/>

[mu4e] <https://djcbsoftware.nl/code/mu/mu4e.html>
