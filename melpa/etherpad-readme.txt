Etherpad is a highly customizable Open Source online editor providing
collaborative editing in really real-time.

This package enables read-write access to pads on an Etherpad server
as if they were filelike but is not (yet) suitable for use as a
collaborative Etherpad client.

 details -> https://etherpad.org/doc/v1.8.5/#index_http_api


 known bugs, limitations, shortcomings, etc
 - various problems with realtime editing using easysync
 - the server and api key could be buffer local to enable editing on more than one server
 - doesn't automate API interface generation from openapi.json
 - not much in the way of error checking or recovery
 - etc
