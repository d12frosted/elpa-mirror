                               ━━━━━━━━━━
                                MINIMAIL
                               ━━━━━━━━━━


Minimail is a simple, non-blocking IMAP email client for Emacs.  It is a
rather new package but covers the basics needed for reading and replying
to messages:

• Displaying messages, including MIME content (rendering via Gnus)
• Composing, replying to and forwarding messages
• Multi-account support
• Search (currently only full text)
• Moving messages between mailboxes (also archive, move to trash, move
  to junk folder)
• Sorting by thread, in two modes:
  • “Shallow” threading (just one nesting level, sorted by date) using
    server-side thread information if available or subject lines as a
    fallback.
  • Optionally, hierarchical threads based on reference message IDs.

Here is a list of planned features:

• Structured search (by sender, subject, etc.)
• Marking and operating on sets of messages (move, etc.)
• Watching for new messages and notifications
• Login via OAuth
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

  Just set `mail-user-agent' to `minimail' and customize the variable
  `minimail-accounts'.  Here is an illustrative example:

  ┌────
  │ (setq mail-user-agent 'minimail
  │       minimail-accounts
  │       '((gmail ;; This can be any symbol you like to identify the account
  │ 	 :mail-address "somebody@gmail.com"
  │ 	 :incoming-url "imaps://imap.gmail.com"
  │ 	 :outgoing-url "smtps://smtp.gmail.com")
  │ 	(work ;; Assuming Evil Corp. uses "Google Workspace" as email provider
  │ 	 :mail-address "webmaster@evilcorp.com"
  │ 	 :incoming-url "imaps://imap.gmail.com"
  │ 	 :outgoing-url "smtps://smtp.gmail.com"
  │ 	 :signature (file "~/work/.signature"))
  │ 	(uni
  │ 	 :mail-address "somebody@math.niceuni.edu"
  │ 	 ;; Include a username in the server URLs if it doesn't match
  │ 	 ;; your email address.
  │ 	 ;; Use `imap' and `smtp' as URL scheme if your server only
  │ 	 ;; supports STARTTLS.
  │ 	 :incoming-url "imap://username@imap.niceuni.edu"
  │ 	 :outgoing-url "smtp://username@smtp.niceuni.edu")))
  └────

  In addition to the above, you need to configure [auth-source] to
  supply the passwords.  Some email provides require you to first create
  an "app password" (for Gmail, see [this]).  Then your `~/.authinfo'
  file should look something like this:

  ┌────
  │ machine imap.gmail.com login somebody@gmail.com password xxxxxxxxxxxxxxxx
  │ machine smtp.gmail.com login somebody@gmail.com password xxxxxxxxxxxxxxxx
  │ 
  │ machine imap.gmail.com login webmaster@evilcorp.com password yyyyyyyyyyyyyyyy
  │ machine smtp.gmail.com login webmaster@evilcorp.com password yyyyyyyyyyyyyyyy
  │ 
  │ machine imap.niceuni.edu login username password zzzzzzzzzzzzzzzz
  │ machine smtp.niceuni.edu login username password zzzzzzzzzzzzzzzz
  └────


[auth-source]
<https://www.gnu.org/software/emacs/manual/html_mono/auth.html>

[this] <https://support.google.com/accounts/answer/185833>


3 Usage
═══════

  This package has two main entry points.  The command
  `minimail-show-mailboxes' displays the mailbox hierarchy of your
  accounts, while `minimail-find-mailbox' directly opens a mailbox you
  choose from the minibuffer.  In a mailbox or message buffer, hit `h'
  to see a list of available commands.
