`insta-pocket.el` is an Emacs client for interacting with the
Instapaper API, allowing users to manage their bookmarks, folders,
and reading content directly from Emacs.

This package provides functionalities such as:
- Authorizing a user with their Instapaper credentials to access their
  bookmarks securely via OAuth.
- Retrieving a list of bookmarks along with their metadata, including
  starred status and tags.
- Adding new URLs to the user's Instapaper account.
- Archiving or unarchiving bookmarks.
- Moving bookmarks between different folders.
- Starring or unstarring bookmarks to mark them for later reference.
- Selecting and managing different folders for better organization of
  bookmarks.

The user interface is built around `tabulated-list-mode`, making it easy
to view and interact with bookmarks in a structured format.
The package utilizes the `oauth` library for handling authentication and
secure API communication with the Instapaper service.

To start using `insta-pocket`, users need to set their consumer key and
secret and authorize access to their Instapaper account. Once authorized,
they can manage their bookmarks directly from Emacs.

Usage:
- Use `M-x insta-pocket` to launch the Insta Pocket interface.
- Use the key bindings within the mode to interact with bookmarks. For
  instance, "o" to read, "a" to archive, and more.

Ensure that required libraries like `oauth` are installed before using this
package. This package is licensed under the GNU General Public License v3.
