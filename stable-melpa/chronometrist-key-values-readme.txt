
This package lets users attach tags and key-values to their tracked time, similar to tags and properties in Org mode.

To use, add one or more of these functions to any chronometrist hook except `chronometrist-before-in-functions`.
* `completing-read'-based - `chronometrist-tags-add` and/or `chronometrist-kv-add'
* `choice'-based (Hydra-like) - `chronometrist-unified-choice'
