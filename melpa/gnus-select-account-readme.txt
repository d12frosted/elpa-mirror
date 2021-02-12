* What is gnus-select-account                                      :README:
gnus-select-account let user select an account before write a email
in gnus.

** Installation

1. Config melpa source, please read: [[http://melpa.org/#/getting-started]]
2. M-x package-install RET gnus-select-account RET

** Configure
1. Gnus-select-account configure
   #+BEGIN_EXAMPLE
   (require 'gnus-select-account)
   (gnus-select-account-enable)
   #+END_EXAMPLE
2. Add account information to file: "~/.authinfo.gpg" or "~/.authinfo", for example:
   #+BEGIN_EXAMPLE
   machine smtp.163.com login xxxr@163.com port 465 password PASSWORD user-full-name "XXX" user-mail-address xxx@163.com
   machine smtp.qq.com  login xxx@qq.com   port 465 password PASSWORD user-full-name "XXX" user-mail-address xxx@qq.com
   #+END_EXAMPLE
