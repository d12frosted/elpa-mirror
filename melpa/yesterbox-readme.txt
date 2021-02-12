The `yesterbox' approach to handling email is to focus on
reading/replying to messages sent yesterday (a finite number),
rather than trying to keep up with today's email (a moving target).

This mode assumes that you use the excellent `mu4e' mail program,
but could be adapted to work with other Emacs mailers.

When you call `M-x yesterbox', you will see a new *yesterbox*
buffer containing something like:

Days  Count
   1     19
   2      5
   3      7
 4-6     13
7-10     21

This shows that there are 19 messages in the inbox from yesterday
(1 day ago), 5 messages from 2 days ago and so on.  The last entry
shows that there are 21 messages aged between 7 and 10 days
inclusive.  If you then wish to see those 19 messages from
yesterday, just press RETURN on the corresponding line.

The days for which yesterbox will search can be changed by updating
the variable `yesterbox-days'.  If you wish to see the number of
messages from today you can include 0 in that list, but then you
might be tempted to work on today's messages...

The program also assumes your primary inbox is called "inbox";
change the variable `yesterbox-inbox' if you use a different
name.  Setting the variable to "inbox/" (note the final forward
slash) will search for the pattern "inbox" and look for emails in
multiple accounts.  See https://github.com/sje30/yesterbox/issues/1
for details.

Acknowledgements: Thanks to Laurent Gatto for testing and feedback.

TODO:
When quitting the search buffer, maybe return to *yesterbox* rather
than the mu main header.  Remember window configuration?
