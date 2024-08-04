This package provides a major mode for running terminal sessions.
One can think of it similarly to Jupyter notebooks, but general to a terminal
session and with less special features in order to only work with plain text.

One can also think of it as similar to `M-x shell', but more focussed around
replay of existing commands and pruning of your session into something close
to automation.

When running experimental terminal sessions (where one does not know exactly
how to do what they are attempting) one can find themselves repeating parts
of that session multiple times with slight variation.

Similarly such repetition with slight variation could happen when performing
actions that could be scripted, but where the percieved benefit of scripting
is not quite enough for the current task (e.g. because it's too small a
task).

Both of the above situations can benefit from some kind of automation "in
between" scripting and typing into the terminal.  That is where this package
comes in.

While running a terminal session in a `vsh' buffer one is automatically
recording a list of commands that got run (as in history).  One can edit the
output as per a `shell' buffer etc.  The difference with `vsh' is that you
can also remove commands that were mistakes, and you can run previous
commands in place (and as a block).  N.b.  running a command is done with the
default `eval-last-sexp' binding (usually `C-x C-e').
As an example, when running in a GDB session one might have a session with
various mistakes and temporary commands in the history (simplistic example
below):

vshcmd: > gdb ./test
...
vshcmd: > break printf
...
vshcmd: > y
...
vshcmd: > run
...
vshcmd: > # To represent bunch of different commands that are not "important".
vshcmd: > apropos shared
...
vshcmd: > # Notice that we should have put a breakpoint on `puts' rather than `printf'.
vshcmd: > disassemble main
Dump of assembler code for function main:
   0x0000555555555149 <+0>:	endbr64
   0x000055555555514d <+4>:	push   %rbp
   0x000055555555514e <+5>:	mov    %rsp,%rbp
   0x0000555555555151 <+8>:	lea    0xeac(%rip),%rax        # 0x555555556004
   0x0000555555555158 <+15>:	mov    %rax,%rdi
   0x000055555555515b <+18>:	call   0x555555555050 <puts@plt>
   0x0000555555555160 <+23>:	mov    $0x0,%eax
   0x0000555555555165 <+28>:	pop    %rbp
   0x0000555555555166 <+29>:	ret
End of assembler dump.
(gdb)
vshcmd: > break puts
...
vshcmd: > delete 1
...
vshcmd: > run
Starting program: /home/matmal01/test
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/lib/x86_64-linux-gnu/libthread_db.so.1".

Breakpoint 2, 0x00007ffff7dfbe50 in puts () from /lib/x86_64-linux-gnu/libc.so.6
(gdb)

Imagine that the day after you come back to the same debugging session.
First off running inside `vsh-mode' has recorded the session so you don't
have to remember what you did.  Secondly you can simply clean up the session
in the buffer before running it so you don't make the same mistakes as last
time.

vshcmd: > gdb ./test
...
vshcmd: > break puts
...
vshcmd: > run
...

Furthermore, you can put all these commands in one block and run the entire
block every time you start GDB (imagine there are three or four setup
commands that via trial and error you have found you need to run in these
debugging sessions).  The below block would be run with `C-M-x'.

vshcmd: > gdb ./test
vshcmd: > break puts
vshcmd: > run
... ... ...

Some time later on, if you perform this same kind of debugging session
multiple times, you might save this into a GDB command or setup file.
The main concept here is that `vsh-mode' provides a very low-barrier
progression from doing something complicated to having it partially
automated.  This partially automated state is often good enough for many
tasks, but for a task that needs to be properly automated this partially
automated state is also having done part of the work towards automation.

Anecdotally I can also mention that knowing complex commands will stay around
ready for me to use again (and easily editable with standard text editor
commands to adjust for future use) has meant that I much more often write
complex commands to do what I want in one step rather than simpler commands
that take a few manual steps.


All this is done by breaking the fundamental assumption of terminals that the
command and output are all appended to previous text.  This comes with a few
quirks (like when looking at the `vsh-mode' buffer you don't immediately know
where the last command has come from, nor whether you're currently running a
python REPL, gdb session, or shell session).  Most of these quirks have not
turned out to be problematic enough to compare to the benefits listed above.

N.b.  another use for this mode is to prepare live demonstrations.  You can
test the exact terminal session you intend to run and avoid typos during the
demonstration while still allowing the ability to do something slightly
different on the day.

Basic keybindings:
  - `C-M-x' for `vsh-execute-block'
  - `C-x C-e' for `vsh-execute-command'
  - `M-e' for `vsh-next-command'  (actually `forward-sentence')
  - `M-a' for `vsh-prev-command'  (actually `backward-sentence')
  - `C-c C-o' for `vsh-mark-segment' (to mark output from a command).
  - `C-c C-u' for `vsh-line-discard' (kill back to end of prompt).
  - `C-c M-/' for `vsh-complete-file-at-point'
  - `C-c C-x C-f' for `vsh-find-file' (find file in directory of shell).
