
This extension features are
- Easily and quickly edit ticket of various bug tracking systems using a unified widget interface
- List up ticket summaries with the combination of multiple conditions at one time
- Edit the listed multiple tickets at one time

You are able to create/update the tickets of a bug tracking system by the following steps.
1. create projects for the system
2. create queries belongs to the project
3. List up the summaries of the fetched tickets from the queries
4. Open details of the tickets, change the properties, and submit them.

* Project means a access configuration for the system stores target tickets data
* Query means a configuration detects the fetched tickets in the tickets belongs to the project
* For handling project, there are `bts:project-new'/`bts:project-update'
* For handling query, there are `bts:query-new'/`bts:query-update'
* For handling ticket, there are `bts:ticket-new'/`bts:summary-open'
* For key binding in widget buffer, see `bts:widget-common-keymap'
* For checking other functions, see API section below
* For use of this extension, it needs to install the system package (eg. bts-github is for GitHub).

For more infomation, see <https://github.com/aki2o/emacs-bts/blob/master/README.md>
