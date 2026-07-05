Provides a local WebSocket server that exchanges JSON frames with a
Chrome (MV3) extension.  Frames carry one of two shapes:

  Request : { "id": "<uuid>", "name": "NAME",   "payload": {...} }
  Response: { "requestId": "<uuid>",            "payload": {...} }

Request names are SCREAMING_SNAKE_CASE.  Incoming requests are
dispatched to handlers registered with
`browsel-register-handler'.  Outgoing requests are made with
`browsel-request-async' (callback-based) or
`browsel-request' (sync wrapper using `accept-process-output').

Built-in handlers:

  ORG_CAPTURE       -- org-capture (template key configurable)
  ORG_ROAM_CAPTURE  -- standard org-roam-capture
  EWW               -- open URL in eww

Per-feature backends register additional handlers:

  browsel-chatgpt.el  -- CHATGPT
  browsel-www.el      -- SAVE_PAGE
  browsel-youtube.el  -- YOUTUBE, YOUTUBE_TRANSCRIPT

Usage:
  (require 'browsel)
  (browsel-start)   ; start the server
  (browsel-stop)    ; stop the server
