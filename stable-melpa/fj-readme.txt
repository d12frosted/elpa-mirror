A client for Forgejo instances. Forgejo is a self-hostable software
forge. See <https://foregejo.org>.

The client is based on tabulated listings for issues, PRs, repos,
users, etc., and attempts to implement a fairly rich interface for item
(issue, PR) timelines, as well as for composing items and comments. It
is built with fedi.el, which in turn is based on mastodon.el.

To get started, first set `fj-token' and `fj-user'. Then either set
your Forgejo access token in your auth-source file or set `fj-host' to
it.

For further details, see the readme at
<https://codeberg.org/martianh/fj.el>.
