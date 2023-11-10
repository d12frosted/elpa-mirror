* What is it?

  Emacs comes with a SQL interpreter which is able to open a connection
  to databases and present you with a prompt you are probably familiar
  with (e.g. `mysql>', `pgsql>', etc.). But it cannot connect to less
  known databases like Amazon Athena, Amazon Redshift, (Facebook)
  PrestoDB,...

  This mode gives you the ability to do that through SqlLine
  (<https://github.com/julianhyde/sqlline>) command


* How do I get it?

  The canonical repository for the source code is
  <https://gitlab.com/matteoredaelli/sql-sqlline>

  The recommended way to install the package is to utilize Emacs's
  `package.el' along with MELPA. To set this up, please follow MELPA's
  [getting started guide], and then run `M-x package-install
  sql-sqlline'.


  [getting started guide] <https://melpa.org/#/getting-started>


* How do I use it?

  Within Emacs, run `M-x sql-sqlline'. You will be prompted by in the
  minibuffer for a server. Enter the correct server and you should be
  greeted by a SQLi buffer with a `sqlline>' prompt.

  From there you can either type queries in this buffer, or open a
  `sql-mode' buffer and send chunks of SQL over to the SQLi buffer with
  the requisite key-chords.


* Contributing

  Please open GitLab issues and issue pull requests. Prior to submitting
  a pull-request, please run `make'. This will perform some linting and
  attempt to compile the package.


* License

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

  Please see the LICENSE file.
