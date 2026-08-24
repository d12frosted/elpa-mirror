Provides a local WebSocket server that exchanges JSON frames with a
Chrome (MV3) extension.  Frames carry one of two shapes:

  Request : { "id": "<uuid>", "name": "NAME",   "payload": {...} }
  Response: { "requestId": "<uuid>",            "payload": {...} }

Request names are SCREAMING_SNAKE_CASE.  Incoming requests are
dispatched to handlers registered with
`browser-gt-register-handler'.  Outgoing requests are made with
`browser-gt-request-async' (callback-based) or
`browser-gt-request' (sync wrapper using `accept-process-output').

Built-in handlers:

  ORG_CAPTURE       -- org-capture (template key configurable)
  ORG_ROAM_CAPTURE  -- standard org-roam-capture
  EWW               -- open URL in eww

Per-feature backends register additional handlers:

  browser-gt-chatgpt.el  -- CHATGPT
  browser-gt-www.el      -- SAVE_PAGE
  browser-gt-youtube.el  -- YOUTUBE, YOUTUBE_TRANSCRIPT

Usage:
  (require 'browser-gt)
  (browser-gt-start)   ; start the server
  (browser-gt-stop)    ; stop the server
