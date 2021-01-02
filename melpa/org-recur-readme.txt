
This package extends org-mode and org-agenda with support for defining
recurring tasks and easily scheduling them.

By adding some simple syntax to a task heading you can control how often the
task should recur. Examples:

+ |+2|: Recur every other day.
+ |+w|: Recur every week.
+ |1|: Recur on the first of every month.
+ |Thu|: Recur every Thursday.
+ *|Sun,Sat|: Recur every Sunday and Saturday.
+ *|Wkdy|: Recur every weekday.

The syntax is almost identical to the one used by `org-schedule', with
examples of additional syntax, provided by org-recur, marked by *.

You can use the provided command `org-recur-finish' to reschedule tasks based
on their recurrence syntax. With the point over a task, in either org-mode or
org-agenda, call `org-recur-finish' and it will handle the task
intelligently. If the task does not contain a recurrence syntax, the command
will ignore it by default, though this is customizable.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 3, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to
the Free Software Foundation, Inc., 51 Franklin Street, Fifth
Floor, Boston, MA 02110-1301, USA.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
