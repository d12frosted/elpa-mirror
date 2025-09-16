Implementation of the OAuth 2.0 draft.

The main entry point is `oauth2-auth-and-store' which will return a token
structure, which contains information needed for OAuth2 authentication,
e.g. access_token, refresh_token, etc.

If the token needs to be refreshed, call `oauth2-refresh-access' on the token
and it will be refreshed with a new access_token.  The code will also store
the new value of the access token for reuse.