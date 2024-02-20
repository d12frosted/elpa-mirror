Excorporate provides Exchange integration for Emacs.

Most Recent Improvements
------------------------

New in Excorporate 1.1.2, released 2024-02-19:

** In Org entries use shorter time ranges where possible

New in Excorporate 1.1.1, released 2023-05-29:

** Update documentation

New in Excorporate 1.1.0, released 2023-05-10:

** Experimental OAuth 2.0 support

Warning: To deal with OAuth 2.0 refresh tokens, `url-http-oauth' needs
to rewrite entries in netrc files listed in the `auth-sources'
variable.  The netrc entry rewriting code is new and relatively
untested so please back up these files before trying OAuth 2.0
support.

Quick Start
-----------

Customize `excorporate-configuration'.  To use OAuth 2.0, at a minimum
you will need to set the "client-identifier" and the "login_hint"
fields.

Then:

M-x excorporate

You should see a message indicating that the connection is ready
either in the minibuffer or in the *Messages* buffer.

Run M-x calendar, and press 'e' to show today's meetings.

For configuration suggestions and connection troubleshooting tips, see
the Excorporate Info node at C-h i d m Excorporate.
