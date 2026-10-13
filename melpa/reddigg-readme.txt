This package allows you to browse reddit in org-mode.

Reddit now requires a logged-in, browser-driven session for its
JSON endpoints, so reddigg no longer talks to old.reddit.com
directly.  Instead it talks to a small local Python server (see
server/reddigg_server.py) over a simple HTTP/REST API.  That server
relays requests to a reddit tab running the reddigg userscript,
which is the only thing with the user's real, logged-in session.
You must:
  1. Run the server:  python3 server/reddigg_server.py
  2. Load userscript/reddigg-ws.user.js in your browser and be
     logged into old.reddit.com there.
The server listens on a single port (1979) for both the userscript's
websocket and Emacs's REST requests.  REST requests are authenticated
with a token the server stores in `reddigg-token-file'.
See `reddigg-server-url' to point Emacs at a non-default host/port,
and `reddigg-ping' to check that the whole chain
(Emacs -> server -> browser tab) is working.

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

reddigg-ping: check the server and the browser tab are reachable.

reddigg-refresh-session: re-read the logged-in username from the tab.

* Interaction (in the generated buffers, `reddigg-view-mode')
C-c C-v u / d / 0   upvote / downvote / clear vote
C-c C-v r           reply
C-c C-v e           edit your own post/comment
C-c C-v x           delete your own post/comment
`reddigg-submit-post' creates a new submission.
