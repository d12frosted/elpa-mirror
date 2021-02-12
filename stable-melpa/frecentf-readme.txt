Slightly similar to `recentf', uses frecency for scoring entries.
Big differences with `recentf' are:
· simplified persistent list
· No entry is deleted when a buffer is killed (only when
  `frecentf-max-saved-items' is reached)
