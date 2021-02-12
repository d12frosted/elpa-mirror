[![Travis build status](https://travis-ci.org/emacs-pe/redis.el.svg?branch=master)](https://travis-ci.org/emacs-pe/redis.el)

`redis.el' offer a comint mode for `redis-cli'.

Also offers a `redis-mode' for pseudo redis scripts which uses "#"
(number sign) as comment line. You can send the pseudo scripts to
redis removing the comments:

     $ grep -v '^#' myscript.redis | nc 127.0.0.1 6379
