http-server speaks HTTP for you.  It is a building block for other packages that want
to offer an HTTP server inside of Emacs to communicate with the user or external
programs.  http-server's minimal design makes no assumptions on what that package will
do with the server.  It gets out of your way and grants you full control and
responsibility over any aspect of the server that is not directly tied to the HTTP
protocol itself.
