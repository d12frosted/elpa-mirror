
Description:

This provides flycheck integration for ycmd. It allows flycheck to
use ycmd's parse results for it display. It essentially works by
caching the ycmd parse results and then using them when the checker
is invoked.

Basic usage:

 (require 'flycheck-ycmd)
 (flycheck-ycmd-setup)
