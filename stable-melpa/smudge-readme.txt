This mode requires at least GNU Emacs 27.1

Before using this mode, first go the Spotify Web API console
<https://developer.spotify.com/my-applications> and create a new application,
adding <http://localhost:8080/smudge-callback> as the redirect URI (or
whichever port you have specified via customize).

After requiring `smudge', make sure to define the client id and client
secrets, along with some other important settings.
