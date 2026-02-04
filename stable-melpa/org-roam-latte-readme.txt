Org-roam Latte is a minor mode that highlights unlinked references to
existing org-roam nodes. It scans your text for words matching existing
org-roam node titles or aliases and highlights them, allowing you to quickly
navigate to those nodes or convert the text into a formal link.

Features:
- Fast: Scans only the visible section of a buffer, and checks against a hash
table. It stays snappy even with thousands of nodes.
- Instant: Automatically highlights keywords as you type, instantly surfacing
potential links.
- Non-org Modes: Allows you to have virtual, navigable links in any mode: text,
code, shells, man pages, etc.
- Smart Linking: Highlighted words are navigatable.
    Click / RET: Visit the node.
    M-RET: Convert the text into a formal org-roam ID link.
- Pluralization: Automatically handles pluralization (e.g., a node titled
"Algorithm" will highlight "algorithms" in your text).
- Context Aware: Ignores existing Org links and node self-referencing. It
intelligent handles code blocks (only highlights inside comments).
- Theme Aware: Adapts colors automatically for light and dark themes.
