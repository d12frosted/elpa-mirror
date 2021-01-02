This program currently uses frames only.

After you type M-x regex-tool, you will see three buffers: *Regex*, *Text*
and *Groups*.  The *Regex* buffer contains your regular expression.  By
default, this tool uses Emacs regular expressions.  If you customize the
variable `regex-tool-backend', you can switch to using full Perl regular
expressions.

The *Text* buffer contains the sample text you want to match against.
Change this however you like.

The *Groups* buffer will list out any regular expression groups that match.
Your regular expression is searched for as many times as it appears in the
buffer, and any groups that match will be repeated.

The results are updated as you type in either the *Regex* or *Text* buffer.
Use C-c C-c to force an update.  Use C-c C-k to quit all the regex-tool
buffers and remove the frame.

; Version History:

1.1 - Don't die horribly if the user simply types '^' or '$'
1.2 - Include cl.el at compile time
