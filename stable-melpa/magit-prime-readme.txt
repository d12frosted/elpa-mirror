A Magit extension that primes caches in parallel before refresh operations,
reducing Magit buffer refresh times.

Usage:
(add-hook 'magit-pre-refresh-hook 'magit-prime-refresh-cache)
