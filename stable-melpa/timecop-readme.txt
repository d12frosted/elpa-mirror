Inspired by Timecop gem https://github.com/travisjeffery/timecop

(datetime-format 'atom nil :timezone "America/New_York") ;=> now "2016-05-20 06:05:50-04:00"

(timecop 1234567890
    (datetime-format 'atom nil :timezone "America/New_York")) ;=> "2009-02-13 18:02:30-05:00"
