
ticktick.el provides two-way synchronization between TickTick
(a popular task management service) and Emacs Org Mode.

FEATURES:

- Bidirectional sync: changes in either TickTick or Org Mode are reflected
  in both systems
- OAuth2 authentication with automatic token refresh
- Preserves task metadata: priorities, due dates, completion status
- Project-based organization matching TickTick's structure
- Optional automatic syncing on focus changes

SETUP:

1. Register a TickTick OAuth application at:
   https://developer.ticktick.com/

2. Configure your credentials:
   (setq ticktick-client-id "your-client-id")
   (setq ticktick-client-secret "your-client-secret")

3. Authorize the application:
   M-x ticktick-authorize

4. Perform initial sync:
   M-x ticktick-sync

USAGE:

Main commands:
- `ticktick-sync': Full bidirectional sync
- `ticktick-fetch-to-org': Pull tasks from TickTick to Org
- `ticktick-push-from-org': Push Org tasks to TickTick
- `ticktick-authorize': Set up OAuth authentication
- `ticktick-refresh-token': Manually refresh auth token
- `ticktick-toggle-sync-timer': Toggle automatic timer-based syncing

Tasks are stored in the file specified by `ticktick-sync-file'
(defaults to ~/.emacs.d/ticktick/ticktick.org) with this structure:

* Project Name
:PROPERTIES:
:TICKTICK_PROJECT_ID: abc123
:END:
** TODO Task Title [#A]
DEADLINE: <2024-01-15 Mon>
:PROPERTIES:
:TICKTICK_ID: def456
:TICKTICK_ETAG: xyz789
:SYNC_CACHE: hash
:LAST_SYNCED: 2025-01-15T10:30:00+0000
:END:
Task description content here.

CUSTOMIZATION:

Key variables you can customize:
- `ticktick-sync-file': Path to the org file for tasks
- `ticktick-dir': Directory for storing tokens and data
- `ticktick-autosync': Enable automatic syncing on focus changes
- `ticktick-sync-interval': Enable automatic syncing every N minutes
- `ticktick-httpd-port': Port for OAuth callback server

For debugging OAuth issues:
M-x ticktick-debug-oauth
