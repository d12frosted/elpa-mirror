
This is a patch that attempts to fix image inlining (C-c C-x C-v) in
the org-mode for images that are encrypted AND end with ".gpg" extension.

To start, add this use-package to your config file to enable it globally:

(use-package org-epa-gpg
  :ensure t
  :after epa-file
  :config (org-epa-gpg-enable))

Or use `org-epa-gpg-mode' as buffer-local alternative.

The cleaning of the decrypted content (in /tmp via (make-temp-file) )
is currently done via patching (org-remove-inline-images) with a custom
hook (so that it's purged on (C-c C-x C-v) untoggling and via attaching
to multiple standard hooks.

What I attempted to make it less insane:
* purge the files right after decrypting and loading
  -> this causes an empty rectangle in the buffer with hot-reloading
* hook to standard hooks such as:
  * buffer-list-update-hook
    -> basically kills Emacs by making it frozen due to too many updates
    and the initial startup with few hundreds of buffers opened is
    a time to go for a coffee
  * change-major-mode / after-change-major-mode-hook / org-mode-hook
    -> is unreliable from security perspective due to being too slow

So I added the purging to these hooks so that an action of "going away"
from the org buffer or from Emacs alone, which would potentially endanger
the unencrypted data, would also purge them.  It's also trying to minimize
their overall presence too `org-epa-gpg-purging-hooks'

A timer could possibly be added with a very short interval, but it doesn't
seem feasible if the amount of images is more than a few (large Org
documents) due to 1:1 (image:purger) relationship in `list-timers' possibly
hogging Emacs down readability-/resource-wise.  Or at least, if turned on by
default.
