
`org-jami-bot' builds upon `jami-bot' and extends it with Org mode capture
functionality for text messages and images.  It allows to schedule agenda
items at specific dates, compose multi-measure captures and capture images --
all by sending a message via the GNU Jami messenger.

`org-jami-bot' provides multi-message capture from within the Jami messenger
app -- that is, a capture process that consists of several messages and can
include even images and other files.  The process is started by sending the
command "!start" followed by the title of the capture and finished by sending
"!done".  Once the multi-message capture session is started, every following
message is simply added.  This includes images which will be downloaded and
stored locally.  A reference in the form of a link will be included in the
notes.

Every command consists of an exclamation mark and a single word, for example:
"!help" which shows the available commands or "!today" which captures the
remainder of the message as a todo entry scheduled today. Everything else is
treated as a normal message (and captured verbatim).

Files sent separately as a single message are captured as links to the
locally downloaded file and tagged as =FILE=.  In principle, further automatic
processing (e.g. OCR) could easily be integrated.  Any received file will also
be added to the variable =org-stored-links= and can then be easily inserted
as link in any Org mode document using =C-c C-l=.

To get started with `org-jami-bot':
 - install jamid, the GNU Jami daemon
 - set up a Jami account
 - configure a key to be used for org-capture templates:
   (setq org-jami-bot-capture-key "J")
 - set up `org-jami-bot' using default values:
   (org-jami-bot-default-setup)
 - register `jami-bot' to react to received messages:
   (jami-bot-register)
