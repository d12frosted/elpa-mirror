This package allows you to browse reddit in org-mode.

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

reddigg-view-comments: prompt for a post (eg:
r/emacs/comments/lfww57/weekly_tipstricketc_thread/ or
https://www.reddit.com/r/emacs/comments/lfww57/weekly_tipstricketc_thread/)
and show it.

* Remarks
This mode only lets you view reddit. For a complete interaction with reddit check
out md4rd at https://github.com/ahungry/md4rd.
