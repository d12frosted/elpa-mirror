This package demonstrates OAuth 2.0 authentication and
authorization to Sourcehut, using the built-in `url' and
`auth-source'libraries and the new `url-http-oauth' package.

Background:

Sourcehut has implemented OAuth 2.0 for its services.  Its
implementation is unique in that it is released as Free Software,
and does not require JavaScript for any of the OAuth 2.0 steps.

Here is a diagram summarizing the protocol, adapted from RFC 6749:

          `url' and `url-http-oauth' implement
                 these middle steps
+--------+                               +------------------------+
|        |--(A)- Authorization Request ->|    (Resource Owner)    |
|        |                               |                        |
|        |<-(B)-- Authorization Grant ---| You, the Human,        |
|        |                               | user of Emacs and      |
|        |                               | Sourcehut, performing  |
|        |                               | steps in a web browser |
|        |                               +------------------------+
|        |
|        |                               +----------------------+
|        |--(C)-- Authorization Grant -->|(Authorization Server)|
|(Client)|                               |                      |
|        |<-(D)----- Access Token -------| URLs starting with   |
| Emacs  |                               | meta.sr.ht/oauth2    |
|        |                               +----------------------+
|        |
|        |                               +--------------------+
|        |--(E)----- Access Token ------>| (Resource Server)  |
|        |                               |                    |
|        |<-(F)--- Protected Resource ---| URLs starting with |
|        |                               | meta.sr.ht/query   |
+--------+                               +--------------------+

For generality¹ there is no web browser automation.  Here is a
breakdown of Steps A and B:

Step A:
     A.1: A request URL is shown in the minibuffer; the minibuffer
          prompts for a response URL and waits.
     A.2: The user copies the request URL into their web browser of
          choice¹.
     A.3: The user authenticates to Sourcehut, using the web browser.
     A.4: The user authorizes Emacs to access their Sourcehut
          resource, using the web browser.
     A.5: The web browser redirects to a URL; this redirection may
          fail or it may not.  All that matters is the URL itself,
          which will contain a "code" query argument.
     A.6: The user copies the full "code" URL from the web browser.

Step B:   The user pastes the full "code" URL into the minibuffer
          and presses RET.

The remaining steps, C through F, are all handled within Emacs.

1. For example, when running Emacs in a VT100 terminal emulator
   through two SSH hops.

2. For Sourcehut in particular, steps A.2 through A.5 can be done
   using EWW because Sourcehut does not need JavaScript.  Today EWW
   needs to run in a separate process so it does not conflict with
   url-http-oauth, which blocks the minibuffer waiting for the
   response URL.

Installation:

M-x package-install RET url-http-oauth-demo RET

Usage:

M-x url-http-oauth-demo-get-profile-name RET
M-: (url-http-oauth-demo-get-profile-name) RET