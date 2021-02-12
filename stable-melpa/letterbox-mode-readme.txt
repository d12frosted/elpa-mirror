Letterbox-mode is a simple minor mode to add letterboxing to sensitive text.

Select a region of text you want to censor and call M-x
letterbox-add, the selected region will be letterboxed/censored.
Call M-x letterbox-remove to remove all letterboxes, or M-x to
toggle the letterboxes (without removing them).  Some use cases:

 This is a buffer with some sensitive information. 123456 is
 the password for my bank account, and qwerty is my account
 name. please don't read it.

Select "123456" and call letterbox-add, you will see that part
letterboxed:

 This is a buffer with some sensitive information. ██████ is
 the password for my bank account, and qwerty is my account
 name. please don't read it.

Select "qwerty" and call letterbox-add again, you will see that
part letterboxed as well:

 This is a buffer with some sensitive information. ██████ is
 the password for my bank account, and ██████ is my account
 name. please don't read it.

Call letterbox-toggle to hide/show the sensitive text, or
letterbox-remove to remove them.
