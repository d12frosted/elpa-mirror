
 Khalel provides helper routines to import upcoming events from a local
 calendar through the command-line tool khal into an org-mode file. Commands
 to edit and to capture new events allow modifications to the calendar.
 Changes to the local calendar can be transfered to remote CalDAV servers
 using the command-line tool vdirsyncer which can be called from within
 khalel.

 First steps/quick start:
 - install, configure and run vdirsyncer
 - install and configure khal
 - customize the values for default calendar, capture file and import file for khalel
 - call `khalel-add-capture-template' to set up a capture template
 - import upcoming events through `khalel-import-upcoming-events',
   edit them through `khalel-edit-calendar-event' or create new ones through `org-capture'
 - consider adding the import org file to your org agenda to show upcoming events there
