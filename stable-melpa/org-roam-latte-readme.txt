Org-roam Latte is a minor mode that highlights unlinked references to
existing org-roam nodes. It scans your text for words matching existing
org-roam node titles or aliases and highlights them, allowing you to quickly
navigate to those nodes or convert the text into a formal link.

Features:
- Fast: Uses an optimized inverted search strategy. It scans only the VISIBLE
section of a buffer, and checks against a hash table. It stays snappy even
with thousands of nodes.
- Smart Linking: Highlighted words are navigatable and con be converted
to links easily.
- Pluralization: Automatically handles pluralization (e.g., a node titled
"Algorithm" will highlight "algorithms" in your text).
Org-roam Alias Support: Recognizes and highlights your node aliases as well.
- Context Aware: Ignores existing Org links. Intelligent handling of code
blocks (only highlights inside comments).
- Theme Aware: Adapts colors automatically for Light and Dark themes.
