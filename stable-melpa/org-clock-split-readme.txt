
 This package provides ability to split an org CLOCK entry into two records.

 Usage example:

 If cursor is on

 CLOCK: [2018-08-30 Thu 12:19]--[2018-08-30 Thu 16:05] =>  3:46

 Running

 (org-clock-split \"1h2m\")

 Will produce

 CLOCK: [2018-08-30 Thu 12:19]--[2018-08-30 Thu 13:21] =>  1:02
 CLOCK: [2018-08-30 Thu 13:21]--[2018-08-30 Thu 16:05] =>  2:44"
