hush.el helps abstract getting data out of external password managers
By default, supports manual input and the 1password-cli tool.
You can add support for your own preferred tool by writing your own
handler function and appending it together with its name to the hush-engine-alist

This package is an alternative to the native `auth-source' package

The core differences:

More secret-shape agnostic way we integrate engines
It allows us to retrieve any kinds of data structures (not just strings)
from the backends leading to a better developer experience.

No magic integrations
Hush is intended to be used as a utility library more than a ready solution
That means protocols like TRAMP won't load credentials automatically via hush

Configurable cache
Not dependent on `password-cache.el', and you can write your own caching mechanism
