This is gh-notify: A thin ui veneer on top of Magit/Forge porcelain for juggling
large amounts of GitHub notifications.

It provides a more efficient interface to the Magit/Forge notification database
suited for rapid searching/narrow/filter based workflows.  It also improves on
Magit/Forge's default notification fetching behavior by introducing support for
incremental notification fetching, which is a must for interactive notification
queue workflow iterations.

This code should be plug and play if you already have Magit/Forge set up and have
fetched notifications for your GitHub account at least once.  If not, please see:
https://magit.vc/manual/forge.html to get started.

Note: this requires the latest versions of magit/forge to be installed from melpa
as per Feb 18, 2021.
