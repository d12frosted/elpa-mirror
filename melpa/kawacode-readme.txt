Emacs integration for Kawa Code (https://codeawareness.com/product),
a real-time collaboration platform for software teams.

Kawa Code is a standalone desktop application that monitors your
working copy and communicates with team members via a cloud service.
This package connects Emacs to the Kawa Code app over a local socket,
enabling the following features directly in your editor:

- Live diff highlights showing where your code intersects with
  teammates' uncommitted changes (early merge-conflict warning)
- One-click navigation between your version and a peer's version
  of the same file, without committing or pushing
- Per-file peer selection to compare against specific team members
- Intent-driven development (more details on Code Awareness website)
- Other possible features via Kawa Code extensions

Requirements:
  - The Kawa Code desktop app must be installed and running.
    Download it from https://codeawareness.com/product
  - Emacs 27.1 or later
