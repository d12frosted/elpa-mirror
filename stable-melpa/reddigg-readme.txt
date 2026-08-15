This package allows you to browse reddit in org-mode.

Reddit now requires a logged-in, browser-driven session for its
JSON endpoints, so reddigg no longer talks to old.reddit.com
directly with `url-retrieve'.  Instead it uses the `browsel'
package (https://github.com/dmgerman/browsel) to run the fetch
*inside* an already-open, already-authenticated reddit tab in
your real browser, and reads the resulting JSON text back into
Emacs.  You must:
  1. Have `browsel' set up and running (see its README) with both
     the Emacs side (`browsel-start') and the browser extension
     loaded and connected.
  2. Be logged into old.reddit.com in that browser.
reddigg will look for an already-open reddit tab; if it can't
find one it will offer to open old.reddit.com for you and wait
for it to finish loading before continuing.

Buffers:
There are three buffers which are on org-mode. They show links and elisp
commands which will run when you enter/click (org-open-at-point) on them.
*reddigg-main*: show your subreddit list, enter on them will fetch the
subreddit posts and show them on *reddigg*. On *reddigg* when you enter on a
post will fetch the comments and show them on *reddigg-comments* buffer.

Variables:
reddigg-subs: list of subreddits you want to show on *reddigg-main*

* Commands
reddigg-view-main: show your subreddit list in *reddigg-main*, r/all and
r/popular are included.

reddigg-view-sub: prompt for a subreddits and show it,

reddigg-view-frontpage: view frontpage

reddigg-view-comments: prompt for a post (eg:
r/emacs/comments/lfww57/weekly_tipstricketc_thread/ or
https://old.reddit.com/r/emacs/comments/lfww57/weekly_tipstricketc_thread/)
and show it.

* Remarks
This mode only lets you view reddit. For a complete interaction with reddit check
out md4rd at https://github.com/ahungry/md4rd.
