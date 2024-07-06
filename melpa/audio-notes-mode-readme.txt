
`audio-notes-mode' is a way to manage small audio recordings that
you make in order to record thoughts.

After much struggle, I finally decided to stop trying to make
speech recognition work from my phone. Instead, I decided to just
record audio notes, and I wrote this package to automate the
process of playing them back at the computer.

I found this to be even faster, because I don't have to wait and
see if the speech recognition worked and I don't have to repeat the
message 1/3 of the time.

A tasker profile (which records and uploads these notes) is also
provided at the github page.

The idea is that you sync voice notes you record on your
smartphone into a directory on your PC. But you're free to use it
in other ways.

When you activate this mode, it will play the first audio note in a
specific directory and wait for you to write it down. Once you're
finished, just call the next note with \\[anm/play-next]. When you
do this, `audio-notes-mode' will DELETE the note which was already
played and start playing the next one. Once you've gone through all
of them, `audio-notes-mode' deactivates itself.
