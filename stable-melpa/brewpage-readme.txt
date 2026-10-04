Publish Emacs buffers or regions to brewpage.app, a simple pastebin service.
After publishing, the generated URL is copied to the kill ring and displayed
in the minibuffer for easy sharing.

Usage:
  M-x brewpage-publish-region    - Publish selected region
  M-x brewpage-publish-buffer    - Publish entire buffer

Configuration:
  (setq brewpage-api-endpoint "https://brewpage.app/api/html")
  (setq brewpage-namespace "public")  ; can be customized per publish
