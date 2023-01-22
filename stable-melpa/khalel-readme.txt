
 Khalel provides helper routines to import current events from a local
 calendar through the command-line tool khal into an org-mode file. Commands
 to edit and to capture new events allow modifications to the calendar.
 Changes to the local calendar can be transfered to remote CalDAV servers
 using the command-line tool vdirsyncer which can be called from within
 khalel.

 First steps/quick start:
 - install, configure and run vdirsyncer
 - install and configure khal
 - customize the values for capture file and import file for khalel
 - call `khalel-add-capture-template' to set up a capture template
 - import events through `khalel-import-events',
   edit them through `khalel-edit-calendar-event' or create new ones through `org-capture'
 - consider adding the import org file to your org agenda to show current events there
