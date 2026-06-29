<a href="<https://elpa.gnu.org/packages/clipboard-collector.html>"><img
alt="GNU ELPA" src="<https://elpa.gnu.org/favicon.png"/>></a>


1 Introduction
══════════════

  When collecting information using copy/paste, it would be useful if
  one could stay at one place to copy things and later insert them all
  at once at another place. Emacs has `append-next-kill' but it only
  works inside Emacs and it only applies to the very next
  command. Further it would be great if Emacs could detect specific
  clipboard entries and transform them to a different format
  automatically. `clipboard-collector' provides you with those features
  (tested only for Linux).

  You can use it to simply collect multiple entries by binding
  `clipboard-collector-mode' to a key:

  ┌────
  │ (global-set-key (kbd "C-M-w") 'clipboard-collector-mode)
  └────

  Once called the clipboard is observed and any text that is
  copied/killed gets collected. To finish use `C-c C-c' in any buffer to
  insert the collected items separated by newlines.

  By default a timer is used to poll the clipboard for changes, you can
  use [gpastel] to avoid polling the clipboard (using
  `gpastel-update-hook'). This will be done automatically if
  `gpastel-mode' is found to be active.

  If you want to have specific rules for which items get collected and
  maybe transform them before collecting them you can create you own
  commands using `clipboard-collector-create' macro.

  Here is an example for collecting contact information from a website
  for org capture (contact info gets transformed to be used as org
  property drawer items).

  ┌────
  │ (clipboard-collector-create cc-capture-rss
  │  (("^http.*twitter.com"                           ":TWITTER: %s")
  │   ("^http.*reddit.com"                            ":REDDIT: %s")
  │   ("^http.*github.com"                            ":GITHUB: %s")
  │   ("^http.*youtube.com"                           ":YOUTUBE: %s")
  │   ("^http.*stack.*.com"                           ":STACK: %s")
  │   ("^https?://.*\\.[a-z]+/?\\'"                   ":DOMAIN: %s")
  │   ("^.*@.*"                                       ":MAIL: %s")
  │   ("^http.*\\(dotemacs\\|.?emacs\\|.?emacs.d\\)"  ":DOTEMACS: %s"))
  │  (lambda (items)
  │    (clipboard-collector-finish-default items)
  │    (org-capture-finalize)))
  └────

  This creates a command called `cc-capture-rss'. When called the
  clipboard is observed and any changes which match one of the regexes
  will be collected. The clipboard contents are transformed via the
  format string provided above.

  When done collecting, you can press `C-c C-c' to call the finalize
  function (in the above example it would inserts the collected items
  separated by newlines and finish org-capture).

  Rules can also contain a function which gets applied to the clipboard
  entry before the format string is applied. You can use match-data of
  your matching regex in that function, too:

  ┌────
  │ (clipboard-collector-create cc-url
  │  (("https?://\\([^/]*\\)"  "Url: %s" (lambda (item) (match-string 1 item)))))
  └────

  If you just want to apply a matched group to the format string you can
  provide the match group number instead of using a function, too:

  ┌────
  │ (clipboard-collector-create
  │  cc-youtube-rss
  │  (("https://www.youtube.com/user/\\(.*\\)"
  │    "https://www.youtube.com/feeds/videos.xml?user=%s"
  │    1)
  │   ("https://www.youtube.com/channel/\\(.*\\)"
  │    "https://www.youtube.com/feeds/videos.xml?channel_id=%s"
  │    1)))
  └────


[gpastel] <https://github.com/DamienCassou/gpastel>


2 Related projects
══════════════════

  There is [clipmon] but I wanted something more flexible and I wanted
  it to work for text copied in and outside of Emacs.


[clipmon] <https://github.com/bburns/clipmon>


3 Contribute
════════════

  See the [contribute] file.


[contribute]
<https://github.com/clemera/clipboard-collector/blob/master/CONTRIBUTE.asc>
