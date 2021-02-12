elfeed-protocol provide extra protocols to make self-hosting RSS
readers like Fever, NewsBlur, ownCloud News and Tiny TIny RSS work
with elfeed.  See the README for full documentation.

Usage:

  ;; curl recommend
  (setq elfeed-use-curl t)
  (elfeed-set-timeout 36000)
  (setq elfeed-curl-extra-arguments '("--insecure")) ;necessary for https without a trust certificate

  ;; setup extra protocol feeds
  (setq elfeed-feeds '(
                       ;; format 1
                       "owncloud+https://user:pass@myhost.com"

                       ;; format 2, for password with special characters
                       ("owncloud+https://user@myhost.com"
                        :password "password/with|special@characters:")

                       ;; format 3, for password in file
                       ("owncloud+https://user@myhost.com"
                        :password-file "~/.password")

                       ;; format 4, for password in .authinfo, ensure (auth-source-search :host "myhost.com" :port "443" :user "user4") exists
                       ("owncloud+https://user@myhost.com"
                        :use-authinfo t)

                       ;; format 5, for password in gnome-keyring
                       ("owncloud+https://user@myhost.com"
                        :password (shell-command-to-string "secret-tool lookup attribute value"))

                       ;; format 6, for password in pass(1), using password-store.el
                       ("owncloud+https://user@myhost.com"
                        :password (password-store-get "owncloud/app-pass"))

                       ;; use autotags
                       ("owncloud+https://user@myhost.com"
                        :password "password"
                        :autotags (("example.com" comic)))))

  ;; enable elfeed-protocol
  (elfeed-protocol-enable)
