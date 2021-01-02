
This extension provides a way to connect updating a buffer with running
a shell command.  So you can have a shell script which makes and runs a
c program, and then you would M-x watch-buffer, enter the shell script
to run, and every time you save the file it will run the shell script
asynchronously in a seperate buffer
