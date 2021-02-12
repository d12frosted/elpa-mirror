This package defines some hydras (pop-up menus of commands with common
prefixes) for CIDER.

For more information about CIDER, see
https://github.com/clojure-emacs/cider

For more information about hydras, see https://github.com/abo-abo/hydra

Hydras serve several important purposes: discovery, memorization, and
organization.

- Discovery

  - Grouping related commands together under a common prefix and
    displaying them in a single menu facilitates discovery.

  - For example, if a user wants to know about CIDER's documentation
    commands, they could bring up a hydra that includes commands like
    `cider-doc', `cider-javadoc', etc, some of which may be new to them.

- Memorization

  - Hydras serve as a memory aid for the user.  By grouping related
    commands together, the user has less need to memorize every command;
    knowing one, she can find the others.

- Organization

  - The process of creating hydras can aid in organizing code.  This
    gives both developers and users a better overview of what the
    project can or cannot do.

  - Thus, each hydra is like a section of a quick-reference card.  In
    fact, many of the hydras here are inspired by the CIDER refcard:
    https://github.com/clojure-emacs/cider/blob/master/doc/cider-refcard.pdf
