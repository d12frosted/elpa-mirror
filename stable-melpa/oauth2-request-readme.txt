OAuth2 request package interface.

Sample usage:

  (setq token
        (let ((auth-url "https://accounts.google.com/o/oauth2/auth")
              (token-url "https://www.googleapis.com/oauth2/v3/token")
              (client-id "000000000000-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com")
              (client-secret "xxxxxxxxxxxxxxxxxxxxxxxx")
              (scope "https://www.googleapis.com/auth/calendar"))
          (oauth2-auth-and-store auth-url token-url scope client-id client-secret)))

  (oauth2-request token "https://www.googleapis.com/calendar/v3/users/me/calendarList"
    :complete (cl-function
               (lambda (&key response &allow-other-keys)
                 (with-current-buffer (generate-new-buffer "*oauth2-request*")
                   (insert (pp-to-string response))
                   (newline)
                   (insert (request-response-data response))
                   (display-buffer (current-buffer))))))
