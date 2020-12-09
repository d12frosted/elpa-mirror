With this package you can easily enable/disable proxies per protocol in you Emacs.
You could also use this package to provide proxy settings for a group of s-expressions.
All the package does to your environment is operating the global variable `url-proxy-services',
Every time you enable/disable proxies, `url-proxy-services' will be saved into your `custom.el'.

Similar packages:
https://github.com/stardiviner/proxy-mode, https://github.com/twlz0ne/with-proxy.el

Usage:

  Require package:

    (require 'use-proxy) ;; if not using the ELPA package
    (use-proxy-mode) ;; globally enable `use-proxy-mode' to handle proxy settings

  Customization:

    This package provides these following variables you could customize:

    `use-proxy-http-proxy'
    HTTP proxy you could use.
    If not set, the value of $HTTP_PROXY in your environment will be used

    `use-proxy-https-proxy'
    HTTPS proxy you could use.
    If not set, the value of $HTTPS_PROXY in your environment will be used.

    `use-proxy-no-proxy'
    A regular expression matches hosts you don't want to connect through proxy
    If not set, the value of $NO_PROXY in your environment will be used.

    `use-proxy-display-in-global-mode-string'
    Boolean indicates whether display proxy states in `global-mode-string' when %M is enabled in your `mode-line-format'.

    NOTICE: Do not forget to load your `custom-file' if you customized these variables.

  Macros and functions:

    `use-proxy-toggle-proto-proxy'

    Toggle specified proxy by protocol

    (use-proxy-toggle-proto-proxy)
    ;; Running this command will prompt you available protocols
    ;; to choose to enable the corresponding proxy.
    ;; Enabled proxies will be shown in the minor mode lighter.

    `use-proxy-toggle-proxies-global'

    Toggle proxies global or not (respecting "no_proxy" settings or not)

    (use-proxy-toggle-proxies-global)
    ;; if using proxies globally, a "g" will be appended to lighter.

    `use-proxy-toggle-all-proxies'

    Toggle all proxies on/off.

    (use-proxy-toggle-all-proxies)
    ;; toggle all proxies on/off.

    `use-proxy-with-custom-proxies'

    Temporarily enable proxies for a batch of s-expressions.
    You are only required to provide a protocol list which you want to enable proxies for.
    This macro will read corresponding proxy settings from your customization variables.

    (use-proxy-with-custom-proxies '("http" "https")
      (browse-url-emacs "https://www.google.com"))

    `use-proxy-with-specified-proxies'

    Temporarily enable proxies for a batch of s-expression.
    You are required to provide a proxy setting association list.

    (use-proxy-with-specified-proxies '(("http" . "localhost:8080")
                                        ("https" . "localhost:8081"))
      (browse-url-emacs "https://www.google.com"))
