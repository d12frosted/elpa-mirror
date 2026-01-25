Signel.el provides a lightweight, text-based interface for Signal. It
communicates with a running `signal-cli' daemon via JSON-RPC.

Features:
- Strict chat buffers (read-only history, guarded prompt).
- Inline image rendering.
- Sticker support (APNG->GIF conversion for animation).
- Auto-refreshing dashboard of active chats.
- Native Emacs desktop notifications.

Prerequisites:
1. signal-cli installed and in $PATH.
2. A registered/linked Signal account.
3. For animated stickers: `imagemagick' (specifically the `convert' command)
   must be available in your PATH.
