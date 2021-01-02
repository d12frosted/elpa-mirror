This is oauth client library implementation in elisp. It is
capable of authenticating (receiving an access token) and signing
requests. Currently it only supports HMAC-SHA1, although adding
additional signature methods should be relatively straight forward.

Visit http://oauth.net/core/1.0a for the complete oauth spec.

Oauth requires the client application to receive user authorization in order
to access restricted content on behalf of the user. This allows for
authenticated communication without jeopardizing the user's password.
In order for an application to use oauth it needs a key and secret
issued by the service provider.

Usage:

Obtain access token:

The easiest way to obtain an access token is to call (oauth-authorize-app)
This will authorize the application and return an oauth-access-token.
You will use this token for all subsequent requests. In many cases
it will make sense to serialize this token and reuse it for future sessions.
At this time, that functionality is left to the application developers to
implement (see yammer.el for an example of token serialization).

Two helper functions are provided to handle authenticated requests:
(oauth-fetch-url) and (oauth-post-url)
Both take the access-token and a url.
Post takes an additional parameter post-vars-alist which is a
list of key val pairs to be used in a x-www-form-urlencoded message.

yammer.el:
http://github.com/psanford/emacs-yammer/tree/master is an example
mode that uses oauth.el

Dependencies:

The default behavior of oauth.el is to dispatch to curl for http
communication. It is strongly recommended that you use curl.
If curl is unavailable you can set oauth-use-curl to nil and oauth.el
will try to use the emacs internal http functions (url-request).
Note: if you plan on doing https and have oauth-use-curl set to nil,
make sure you have gnutls-bin installed.

oauth.el uses hmac-sha1 library for generating signatures. An implementation
by Derek Upham is included for convenience.

This library assumes that you are using the oauth_verifier method
described in the 1.0a spec.
