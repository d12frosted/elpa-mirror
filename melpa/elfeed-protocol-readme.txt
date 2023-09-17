elfeed-protocol provide extra protocols to make self-hosting RSS
readers like Fever, NewsBlur, ownCloud News and Tiny TIny RSS work
with elfeed.  See the README for full documentation.

Usage:

  ;; curl recommend
  (setq elfeed-use-curl t)
  (elfeed-set-timeout 36000)
  (setq elfeed-curl-extra-arguments '("--insecure")) ;necessary for https without a trust certificate

  ;; setup extra protocol feeds
  (setq elfeed-protocol-feeds '(("owncloud+https://user@myhost.com"
                                 :password "my-password")))

  ;; enable elfeed-protocol
  (elfeed-protocol-enable)
