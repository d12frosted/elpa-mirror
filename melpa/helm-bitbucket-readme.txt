
A helm interface for searching Bitbucket.

** Installation

Download and install the `helm-bitbucket.el' file in your preferred way.

`helm-bitbucket' uses the credentials stored in `.authinfo.gpg' for
authenticating against the bitbucket API.  So you need to add:

`machine api.bitbucket.org login <my-username> password <my-password> port https'

to your `.authinfo.gpg' file.

If you are not familiar with `.authinfo', check out
https://www.emacswiki.org/emacs/GnusAuthinfo for further information.

It is not currently possible to search across all Bitbucket repositories, so
`helm-bitbucket' searches all repositories for which your registered
Bitbucket user is a member.  Thus, `helm-bitbucket' searches both your
personal repositories and the repositories of any Bitbucket team you are a
member of.

API Reference: https://developer.atlassian.com/bitbucket/api/2/reference/

** Usage

Run `M-x helm-bitbucket' and type a search string.  (The search begins after
you've typed at least 2 characters).

Hitting =RET= with an item selected opens the corresponding repository in your
browser.

*** Keys

| =C-n=   | Next item.                       |
| =C-p=   | Previous item.                   |
| =RET=   | Open repository page in browser  |
| =C-h m= | Full list of keyboard shortcuts  |
