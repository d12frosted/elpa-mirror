Provides `helm-eca`:
- Source "ECA chats": all chat buffers across all sessions, displayed as:
WORKSPACE • CHAT-TITLE [USAGE]
- Source "ECA workspaces": all sessions (workspace roots)
This code uses some ECA internals (such as `eca--sessions` and `eca--session-chats`)
because eca-emacs doesn't currently expose a stable "list chats across sessions"
API.  If upstream changes those internals, small tweaks may be needed.
