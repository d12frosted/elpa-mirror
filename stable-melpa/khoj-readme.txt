This package provides a natural, incremental search interface to your
`org-mode' notes, `markdown' files, `beancount' transactions and images.
It is a wrapper that interfaces with the Khoj server.
The server exposes an API for advanced search using transformer ML models.
The Khoj server needs to be running to use this package.
See the repository docs for detailed setup of the Khoj server.

Quickstart
-------------
1. Install Khoj Server
   pip install khoj-assistant
2. Start, Configure Khoj Server
   khoj
3. Install khoj.el
   (use-package khoj :bind ("C-c s" . 'khoj))
