This file defines some functions for zetteldesk.el which help with
integrating it with org-remark.  Org-remark requires the buffer from
which its called to be associated with a file.  However the
zetteldesk-scratch buffer is not associated with a file.  Therefore,
some special things need to be done to allow for this integration
to work.  However, I consider that this is a good implementation of
such behaviour.
