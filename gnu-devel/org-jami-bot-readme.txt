           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
             `ORG-JAMI-BOT': CAPTURING MESSAGES AND IMAGES
                       SENT VIA JAMI IN ORG MODE
           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


`org-jami-bot' builds upon `jami-bot' and extends it with Org mode
capture functionality for text messages and images. It allows to
schedule agenda items at specific dates and compose multi-measure
captures including pictures – all by sending a message via the GNU Jami
messenger.


1 Demo (with cats!)
═══════════════════

  <file:images/org-jami-bot_capture_animation.gif>

  The animation shows how one initiates a multi-message capture from
  within the Jami messenger app – that is, a capture process that
  consists of several messages and can include even images and other
  files. The process is started by sending the command `!start' followed
  by the title of the capture. Every command consists of an exclamation
  mark and a single word, for example: `!help' which shows the available
  commands or `!today' which captures the remainder of the message as a
  todo entry scheduled today. Everything else is treated as a normal
  message (and captured verbatim).

  On the other side of the chat is `jami-bot' running within Emacs on my
  local computer. It responds to each of my messages to indicate how it
  was processed.

  Once the multi-message capture session is started, every following
  message is simply added. This includes images which will be downloaded
  and stored locally on my computer. A reference in the form of a link
  will be included in the notes.

  Putting down the phone and opening the computer again, I will see
  something like this on the screen:
  <file:images/screenshot.png>

  On the left is the capture buffer which includes the individual
  messages and the image I sent shown inline. Additional meta
  information like the capture date is also included. Files sent
  separately as a single message, such as the screenshot in the next
  entry, are captured as links to the locally downloaded file and tagged
  as `FILE'. In principle, further automatic processing (e.g. OCR) could
  easily be integrated. In clear text, the first example capture looks
  like this:

  ┌────
  │ * Demonstration of a multi-message capture :)
  │ :PROPERTIES:
  │ :CREATED: [2023-04-10 Mon 18:26]
  │ :END:
  │ This is the first line to be added.
  │ But there can more!
  │ #+ATTR_ORG: :width 400
  │ [[../../jami/20230410-1826_image1_1.png]]
  │ Like cute cat pictures 😻
  │ That's it!
  └────

  Any received file will also be added to the variable
  `org-stored-links' and can then be easily inserted as link in any Org
  mode document using `C-c C-l'. For me, this has become the easiest and
  quickest way to transfer specific files from my mobile phone to my
  computer and into my notes.


2 Advantages and disadvantages of using Jami and `jami-bot'
═══════════════════════════════════════════════════════════

  [Jami is a distributed and private messenger] that is part of the GNU
  project and [mainly developed by Savoir-faire Linux]. /Private/ in
  this context does not only refer to the fact that messages, calls and
  video chats are encrypted, but that [you need to provide essentially
  no personal information to create a Jami account]. /Distributed/ means
  that you can have encrypted (group) chats without requiring any server
  to exchange them through – which even [works between devices on the
  same local network while the internet is down].

  Jami is easy to deploy on most OS and is available for different
  mobile devices as well. That coupled with that fact that it was rather
  straightforward to interface from Emacs made it a ideal candidate for
  this experiment.

  However, Jami has some rougher edges from a user's perspective (that
  is to say, my personal one). While the mobile Android client has
  improved significantly over the past years, it still might quietly
  fail to sync up with other clients.  In those cases, only a restart of
  the App seems to help reliably. Other quirks can be slightly annoying
  at times: pasting from the clipboard, for example, wipes the current
  message draft on my Android client – and I tend to insert links as the
  last step of composing a message.

  Similarly, also the desktop daemon, `jamid', which runs in the
  background while `jami-bot' interacts with it, sometimes needs a
  friendly `killall jamid' followed by `M-x jami-bot-register' to
  re-initiate the service. In particular, network state changes, i.e. a
  temporary loss of connectivity seems to cause a drop from the Jami
  network which Jami does not recover quickly from.

  One more thing to be aware of is that `jami-bot' only reacts to
  messages being /received/. So if the daemon (and/or the GUI app) is
  already running before `jami-bot' is registered and started, some
  messages might slip by unnoticed.  Should you not yet have received
  them yet though, for example because the daemon lost the connection,
  you can simply follow the killall-and-register procedure outlined
  above and you /will/ capture any missed messages.

  Personally, I can live with these compromises.

  One last thing to consider is security: I am not aware of any recent
  security audit of Jami. Either way, bugs affecting the security of the
  messenger likely exist. Personally, I assume that by disabling
  unneeded features such as phone and video calls on my account,
  disallowing connections with unknown accounts and limiting my accounts
  exposure will keep it sufficiently secure for me. Timely updates are a
  given of course. `(org-)jami-bot' should only marginally increase the
  attack surface as long as you use it with trusted devices and accounts
  and do not extend it with functions that directly execute parts of the
  message received as code. In case you discover any potential security
  risks with the code I provide or the way I interface with Jami, please
  [let me know]!

  In any case, [you should make your own threat model] for your use case
  and situation.

  That said, let's look into setting things up!


[Jami is a distributed and private messenger]
<https://docs.jami.net/user/faq.html#what-makes-jami-different-from-other-communication-platforms>

[mainly developed by Savoir-faire Linux] <https://savoirfairelinux.com>

[you need to provide essentially no personal information to create a
Jami account]
<https://docs.jami.net/user/faq.html#what-information-do-i-need-to-provide-to-create-a-jami-account>

[works between devices on the same local network while the internet is
down] <https://docs.jami.net/user/lan-only.html>

[let me know] <mailto:hanno@hoowl.se>

[you should make your own threat model]
<https://ssd.eff.org/module/your-security-plan>


3 Setup
═══════

  You need to have the Jami daemon, `jamid', installed on the local
  system. On Debian, this can be done by simply running `sudo apt
  install jami' which will also install the GUI application. The latter
  is not strictly necessary but can be more comfortable to use during
  the account setup. The version installed through `apt', however, is
  likely older than what is provided on [the official Jami download
  pages] – consider updating should you run into any connectivity issues
  later.

  Jami is controlled by `jami-bot' via [a protocol called /D-Bus/]. If
  you are using a Linux-based system such as Ubuntu, you are almost
  certainly already running D-Bus and an Emacs with built-in support.

  Then you will need to create a Jami account. The easiest is to make a
  completely new one only for `jami-bot', even if you already have a
  Jami account.  By default, `jami-bot' will react to any message sent
  to any local Jami account but will ignore message sent /from/ local
  accounts (to avoid feedback loops). In case you have several local
  accounts and would like to limit `jami-bot' to only one of them, you
  can configure the variable `jami-bot-account-user-names'.


[the official Jami download pages] <https://jami.net/>

[a protocol called /D-Bus/]
<https://www.freedesktop.org/wiki/Software/dbus/>

3.1 `jami-bot' and `org-jami-bot'
─────────────────────────────────

  You will also need to install both the `jami-bot' and `org-jami-bot'
  packages in Emacs. These will eventually be made available via
  e.g. MELPA but currently, you need to install from source. Once that
  is done, simply `require' the `org-jami-bot' package to load them:
  ┌────
  │ (require 'org-jami-bot)
  └────

  In order to capture messages automatically and without user
  interaction, we need to set up an appropriate capture template. Let us
  start by setting an associated key:
  ┌────
  │ (setq org-jami-bot-capture-key "J")
  └────

  Just make sure that this does not conflict with any other already
  defined template in `org-capture-templates'.

  If you just want to get started right way with the default setup for
  `org-jami-bot', simply run
  ┌────
  │ (org-jami-bot-default-setup)
  │ (jami-bot-register)
  └────
  and skip ahead to the next section! If you would like to understand
  the configuration a little bit better or make adjustments, read on!


3.2 Setup explained
───────────────────

  For the actual template, use /initial content/ (`%i'), define the key
  via the above variable, and set the property `:immediate-finish' to
  file the capture away directly. In the code below, you might want to
  replace `org-default-notes-file' with another location:
  ┌────
  │ (if (assoc org-jami-bot-capture-key org-capture-templates)
  │     (message "Capture template referred to by \"%s\" key already defined!"
  │ 	     org-jami-bot-capture-key)
  │   (add-to-list 'org-capture-templates
  │ 	     `(,org-jami-bot-capture-key "Jami message" entry (file org-default-notes-file)
  │ 	       "%i" :immediate-finish t)))
  └────


3.3 Extending  `jami-bot' commands for capture
──────────────────────────────────────────────

  Anytime you send a Jami message that starts with an exclamation mark,
  `jami-bot' will interpret this as a command that will trigger a
  special action. However, `jami-bot' comes only with a rudimentary set
  of commands. These are extended via `org-jami-bot' and need to be
  registered so that `jami-bot' knows about them:

  ┌────
  │ (setq jami-bot-command-function-alist (append jami-bot-command-function-alist
  │   '(("!today" . org-jami-bot--command-function-today)
  │     ("!schedule" . org-jami-bot--command-function-schedule)
  │     ("!start" . org-jami-bot--command-function-start)
  │     ("!done" . org-jami-bot--command-function-done))))
  └────
  This maps the command strings to the functions that handle them. The
  latter will be explained in more detail in the next section!

  As this list of commands is easily forgotten while on the road, you
  can always send the command `!help' via Jami to receive a summary of
  all known commands and their docstrings as reply. Of course, you can
  easily add additional mappings to the list above. Just be sure that
  you do not overwrite the default commands already listed in
  `jami-bot-command-function-alist', or you would lose e.g.  the /!help/
  command.

  Finally, we also want non-command messages captured, whether it is a
  plain text message or a file being sent. This is accomplished by
  adding corresponding /hooks/ that will be run when `jami-bot'
  processes such messages:

  ┌────
  │ (add-hook 'jami-bot-text-message-functions 'org-jami-bot--capture-plain-messsage)
  │ (add-hook 'jami-bot-data-transfer-functions 'org-jami-bot--capture-file)
  └────

  While we are at it, you might want to adjust the directory to which
  files are being downloaded to from its default value:
  ┌────
  │ (setq jami-bot-download-path "~/jami/")
  └────

  Finally, we need to register `jami-bot' so it listens to incoming
  messages:
  ┌────
  │ (jami-bot-register)
  └────

  This is all the setup we need! Now it is time to fire up Jami on your
  phone or any other device and capture messages!


4 First steps
═════════════

  Once you have `jami-bot' and `org-jami-bot' configured, check that the
  account you want to send captures to is shown as present in Jami
  (indicated by a green dot in the profile). Send a simple command such
  as `!help' or `!ping' first. On the computer running `jami-bot', you
  should see a message appear in the minibuffer indicating that the
  message was received. Shortly after, you should get a response via
  Jami.

  After that, try a capture: simply send a text message (without
  starting it with an exclamation mark). You should see the response
  "captured" after only a moment. The message should be filed at the
  location you specified in your capture template
  (`org-default-notes-file' by default).

  Try sending an image or starting a multi-message capture (by sending
  `!start') next. If all works as intended, you might want to adjust or
  extend the format of the capture – so let us look into the code
  handling the captures!


5 Extending functionality of `org-jami-bot'
═══════════════════════════════════════════

  I have written two blog posts explaining the principles behind
  `jami-bot' and `org-jami-bot', respectively. These should provide you
  a good starting point to extend either package:

  • [An extendable GNU Jami chat bot written in Elisp]
  • [Note-taking on the go: Capturing messages and images sent via Jami
    in Org mode]


[An extendable GNU Jami chat bot written in Elisp]
<https://hoowl.se/jami-bot.html>

[Note-taking on the go: Capturing messages and images sent via Jami in
Org mode] <https://hoowl.se/org-jami-bot.html>


6 Troubleshooting
═════════════════

6.1 Stuck messages / no reply from `jami-bot'
─────────────────────────────────────────────

  Especially should your network connectivity drop out, Jami might not
  be able to sync messages and you will see no reply. Try to stop the
  Jami daemon:
  ┌────
  │ killall jamid
  └────
  and then run `M-x jami-bot-register' to restart it and register
  `jami-bot' to listen on the /messageReceived/ signal.
