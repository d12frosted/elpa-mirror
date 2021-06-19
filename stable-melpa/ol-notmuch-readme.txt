This file implements links to notmuch messages and "searches".  A
search is a query to be performed by notmuch; it is the equivalent
to folders in other mail clients.  Similarly, mails are referred to
by a query, so both a link can refer to several mails.

Links have one the following form
notmuch:<search terms>
notmuch-search:<search terms>.

The first form open the queries in notmuch-show mode, whereas the
second link open it in notmuch-search mode.  Note that queries are
performed at the time the link is opened, and the result may be
different from when the link was stored.
