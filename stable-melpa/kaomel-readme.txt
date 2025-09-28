
Kaomel is an interactive kaomoji picker for Emacs that provides a
convenient way to insert kaomojis into your
buffers or copy them to the clipboard.

The package includes a curated dataset of approximately 1000 kaomojis
with multilingual tags in various languages including Japanese
(hiragana/katakana), English, and Italian, with multiple romanization
formats for enhanced searchability.

Main commands:
  M-x kaomel-insert      - Insert selected kaomoji at point
  M-x kaomel-to-clipboard - Copy selected kaomoji to clipboard

The package automatically detects and integrates with popular
completion frameworks:
  - Uses Helm interface when helm-core is available
  - Falls back to completing-read (works with Vertico, Ivy, etc.)
  - Configurable via kaomel-force-completing-read to force completing-read

Customization options include tag language preferences, filtering
settings, visual separators, and display formatting to tailor the
picker experience to your workflow.

Ensure your Emacs font supports Unicode characters for proper
kaomoji rendering.
