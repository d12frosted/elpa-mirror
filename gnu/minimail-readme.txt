                               ━━━━━━━━━━
                                MINIMAIL
                               ━━━━━━━━━━


Minimail is a simple, non-blocking IMAP email client for Emacs.

Minimail currently covers the basics needed for reading and replying to
messages.  Below is a listing of implemented and planned features.

• ☑ Read messages, including MIME content (rendering via Gnus)
• ☑ Compose, reply to and forward messages
• ☑ Multi-account support
• Search
  • ☑ Full text
  • ☐ Structured (by sender, subject, etc.)
• Sorting by thread
  • ☑ Simple algorithm based on subject lines
  • ☐ Fancy algorithm based on reference message IDs.
• ☑ Move messages (also archive, move to trash, flag as junk)
• ☐ Mark and operate on sets of messages (move, etc.)
• ☑ "Load more messages" button
• ☐ Notifications (polling or IDLE)
• ☐ OAuth

Being non-blocking doesn't mean Minimail has excellent performance
(spoiler: it doesn't, yet); it simply means that it has one of the
necessary condition for such.  In fact, Minimail currently doesn't
include any of these possible optimizations:

• ☑ Caching
  • in memory, no persistence
• ☐ Support for CONDSTORE capability
• ☐ Connection pool (for concurrent requests)
• ☐ Prefetching of messages in the background


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
  │ 	(work ;; Assuming Evil Corp uses "Google Workspace" as email provider
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
