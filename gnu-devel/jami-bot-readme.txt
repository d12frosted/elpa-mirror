           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            `JAMI-BOT': AN EXTENDABLE ELISP CHAT BOT FOR THE
                  DISTRIBUTED, PRIVATE MESSENGER JAMI
           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


An extendable chat bot for the distributed, private messenger GNU Jami
written in Emacs Lisp. It interacts with the locally-installed Jami
daemon via D-Bus and reacts to both plain text messages and file
transfers sent to local accounts.  Further processing of either or both
can be configured by adding functions to the abnormal hooks,
`jami-bot-text-message-functions' and
`jami-bot-data-transfer-functions', respectively.

Additionally, the bot allows special actions to be triggered by sending
a text message starting with an exclamation mark and a command keyword.
Further commands than the ones included can be configured by mapping
them to functions through `jami-bot-command-function-alist'.

Set up `jami-bot' by executing `jami-bot-register'. This will set up the
message handler, `jami-bot--messageReceived-handler', to be called on
the `messageReceived' D-Bus signal.


1 Demo
══════

  The extension `org-jami-bot' showcases how `jami-bot' can be used as a
  note-taking interface on the go: [Note-taking on the go: Capturing
  messages and images sent via Jami in Org mode]


[Note-taking on the go: Capturing messages and images sent via Jami in
Org mode] <https://hoowl.se/org-jami-bot.html>


2 Extending functionality of `jami-bot'
═══════════════════════════════════════

  I have written two blog posts explaining the principles behind
  `jami-bot' and the Org mode extension `org-jami-bot',
  respectively. These should provide you a good starting point to extend
  either package:

  • [An extendable GNU Jami chat bot written in Elisp]
  • [Note-taking on the go: Capturing messages and images sent via Jami
    in Org mode]


[An extendable GNU Jami chat bot written in Elisp]
<https://hoowl.se/jami-bot.html>

[Note-taking on the go: Capturing messages and images sent via Jami in
Org mode] <https://hoowl.se/org-jami-bot.html>


3 Troubleshooting
═════════════════

3.1 Stuck messages / no reply from `jami-bot'
─────────────────────────────────────────────

  Especially should your network connectivity drop out, Jami might not
  be able to sync messages and you will see no reply. Try to stop the
  Jami daemon:
  ┌────
  │ killall jamid
  └────
  and then run `M-x jami-bot-register' to restart it and register
  `jami-bot' to listen on the /messageReceived/ signal.
