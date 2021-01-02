This library provides a way to sort items by "frecency" (frequency
and recency).

;; Installation

;;; MELPA

If you installed from MELPA, you're done.

;;; Manual

Install these required packages:

+ a
+ dash

Then put this file in your load-path.

;; Usage

Load the library with:

(require 'frecency)

The library operates on individual items.  That is, you have a list
of items that are frequently (or not-so-frequently) accessed, and
you pass each item to these functions:

+ `frecency-score' returns the score for an item, which you may use
to sort a list of items (e.g. you may pass `frecency-score' to
`cl-sort' as the `:key' function).

+ `frecency-sort' returns a list sorted by frecency.  Each item in
the list must itself be a collection with valid frecency keys and
values.

+ `frecency-update' returns an item with its frecency values
updated.  If the item doesn't have any frecency keys (e.g. if it's
the first time it's been accessed or recorded), they will be added.

An item should be an alist or a plist.  These keys are used by the
library:

+ :frecency-num-timestamps
+ :frecency-timestamps
+ :frecency-total-count

All other keys are ignored and returned with the item.

The library uses alists by default, but it can operate on plists,
hash-tables, or other collections by setting `:get-fn' and
`:set-fn' when calling a function (e.g. when using plists, set them
to `plist-get' and `plist-put' respectively).  `:get-fn' should
have the signature (ITEM KEY), and `:set-fn' (ITEM KEY VALUE).

;; Tips

+ You can customize settings in the `frecency' group.

;; Credits

This package is based on the "frecency" algorithm which was
(perhaps originally) implemented in Mozilla Firefox, and has since
been implemented in other software.  Specifically, this is based on
the implementation described here:

<https://slack.engineering/a-faster-smarter-quick-switcher-77cbc193cb60>
