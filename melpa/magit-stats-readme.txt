magit-stats generates reports containing statistics of your GIT Repositories.

It uses the ~magit-stats~ npm package CLI Tool for NodeJS.

It requires your system to run ~npx~ and have NodeJS
(node@latest) installed.  Please first install it if not yet present
in your system (see: https://nodejs.org/en/ and
https://www.npmjs.com/package/npx)

To enable magit-stats, install the package and add it to your load path:
    (require 'magit-stats)

Call it when inside a file inside a git repository with ~M-x magit-stats RET~
