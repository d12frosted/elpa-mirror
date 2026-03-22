A lightweight, parallel HTTP fetching library for Emacs that uses
`url-retrieve' to download multiple URLs asynchronously with
configurable concurrency limits.

Features:
- Parallel downloads with configurable concurrency (default: 5)
- Automatic timeout handling (default: 10 seconds)
- Custom parser support (default: json-parse-buffer)
- Progress tracking for large batches
- Error handling and retry logic

Example usage:

  (async-http-queue
   '("https://api.example.com/posts/1"
     "https://api.example.com/posts/2"
     "https://api.example.com/posts/3")
   :max-concurrent 5
   :timeout 10
   :parser #'json-parse-buffer
   :callback (lambda (results)
               (message "Got %d results" (length results))))
