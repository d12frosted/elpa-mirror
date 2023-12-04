This library exposes `bookmark-frecency-mode', which is a global mode that
tracks every visit to a bookmark and sorts bookmarks by frecency, using the
algorithm described in
<https://slack.engineering/a-faster-smarter-quick-switcher/.

To retrieve a sorted list of bookmarks, you have to use `bookmark-all-names'.
`bookmark-alist' variable itself is not sorted by this library.

On every visit to a bookmark, the visited bookmark will be updated with the
information needed to calculate the frecency score later, which should be
persisted to `bookmark-file'. To control when to save the bookmarks,
customize `bookmark-save-flag'.
