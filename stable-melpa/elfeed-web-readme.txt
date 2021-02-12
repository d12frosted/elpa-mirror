This is a very early work in progress. The long-term goal is to
provide a web interface view of the database with optional remote
tag updating. An AngularJS client accesses the database over a few
RESTful endpoints with JSON for serialization.

The IDs provided by RSS and Atom are completely arbitrary. To avoid
ugly encoding issues they're normalized into short, unique,
alphanumeric codes called webids. Both feeds and entries fall into
the same webid namespace so they share a single endpoint.

Endpoints:

/elfeed/<path>
    Serves the static HTML, JS, and CSS content.

/elfeed/content/<ref-id>
    Serves content from the content database (`elfeed-deref').

/elfeed/things/<webid>
    Serve up an elfeed-feed or elfeed-entry in JSON format.

/elfeed/search
    Accepts a q parameter which is an filter string to be parsed
    and handled by `elfeed-search-parse-filter'.

/elfeed/tags
    Accepts a PUT request to modify the tags of zero or more
    entries based on a JSON entry passed as the content.

/elfeed/update
    Accepts a time parameter. If time < `elfeed-db-last-update',
    respond with time. Otherwise don't respond until database
    updates (long poll).
