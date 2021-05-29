
;;; ox-clip.el --- Cross-platform formatted copying for org-mode

;; Copyright(C) 2016 John Kitchin

;; Author: John Kitchin <jkitchin@andrew.cmu.edu>
;; URL: https://github.com/jkitchin/ox-clip
;; Package-Version: 20210528.2059
;; Package-Commit: 05a14d56bbffe569d86f20b49ae31ed2ac7d1101
;; Version: 0.3
;; Keywords: org-mode
;; Package-Requires: ((org "8.2") (htmlize "0"))

;; This file is not currently part of GNU Emacs.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program ; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:
;;
;; This module copies selected regions in org-mode as formatted text on the
;; clipboard that can be pasted into other applications. When not in org-mode,
;; the htmlize library is used instead.

;; For Windows the html-clip-w32.py script will be installed. It works pretty
;; well, but I noticed that the hyperlinks in the TOC to headings don't work,
;; and strike-through doesn't seem to work. I have no idea how to fix either
;; issue.

;; Mac OSX needs textutils and pbcopy, which should be part of the base install.

;; Linux needs a relatively modern xclip, preferrably a version of at least
;; 0.12. https://github.com/astrand/xclip

;; The main command is `ox-clip-formatted-copy' that should work across
;; Windows, Mac and Linux. By default, it copies as html.
;;
;; Note: Images/equations may not copy well in html. Use `ox-clip-image-to-clipboard' to
;; copy the image or latex equation at point to the clipboard as an image. The
;; default latex scale is too small for me, so the default size for this is set
;; to 3 in `ox-clip-default-latex-scale'. This overrides the settings in
;; `org-format-latex-options'.

(require 'htmlize)

;;; Code:
(defgroup ox-clip nil
  "Customization group for ox-clip."
  :tag "ox-clip"
  :group 'org)


(defcustom ox-clip-w32-cmd
  (format "python %s"
	  (expand-file-name
	   "html-clip-w32.py"
	   (file-name-directory (or load-file-name (locate-library "ox-clip")))))
  "Absolute path to html-clip-w32.py."
  :group 'ox-clip
  :type 'string)


(defcustom ox-clip-osx-cmd
  "textutil -inputencoding UTF-8 -stdin -format html -convert rtf -stdout | pbcopy"
  "Command to copy formatted text on osX."
  ;; This may work better on Chrome and Slack
  ;; "hexdump -ve '1/1 \"%.2x\"' | xargs printf \"set the clipboard to {text:\\\" \\\", «class HTML»:«data HTML%s»}\" | osascript -"
  :group 'ox-clip
  :type 'string)


(defcustom ox-clip-linux-cmd
  "xclip -verbose -i \"%f\" -t text/html -selection clipboard"
  "Command to copy formatted text on linux.
You must include %f. It will be converted to a generated
temporary filename later."
  :group 'ox-clip
  :type 'string)

(defvar ox-clip-w32-py "#!/usr/bin/env python
# Adapted from http://code.activestate.com/recipes/474121-getting-html-from-the-windows-clipboard/
# HtmlClipboard
# An interface to the \"HTML Format\" clipboard data format

__author__ = \"Phillip Piper (jppx1[at]bigfoot.com)\"
__date__ = \"2006-02-21\"
__version__ = \"0.1\"

import re
import win32clipboard

#---------------------------------------------------------------------------
#  Convenience functions to do the most common operation

def HasHtml():
    \"\"\"
    Return True if there is a Html fragment in the clipboard..
    \"\"\"
    cb = HtmlClipboard()
    return cb.HasHtmlFormat()


def GetHtml():
    \"\"\"
    Return the Html fragment from the clipboard or None if there is no Html in the clipboard.
    \"\"\"
    cb = HtmlClipboard()
    if cb.HasHtmlFormat():
        return cb.GetFragment()
    else:
        return None


def PutHtml(fragment):
    \"\"\"
    Put the given fragment into the clipboard.
    Convenience function to do the most common operation
    \"\"\"
    cb = HtmlClipboard()
    cb.PutFragment(fragment)


#---------------------------------------------------------------------------

class HtmlClipboard:

    CF_HTML = None

    MARKER_BLOCK_OUTPUT = \\
        \"Version:1.0\\r\\n\" \\
        \"StartHTML:%09d\\r\\n\" \\
        \"EndHTML:%09d\\r\\n\" \\
        \"StartFragment:%09d\\r\\n\" \\
        \"EndFragment:%09d\\r\\n\" \\
        \"StartSelection:%09d\\r\\n\" \\
        \"EndSelection:%09d\\r\\n\" \\
        \"SourceURL:%s\\r\\n\"

    MARKER_BLOCK_EX = \\
        \"Version:(\\S+)\\s+\" \\
        \"StartHTML:(\\d+)\\s+\" \\
        \"EndHTML:(\\d+)\\s+\" \\
        \"StartFragment:(\\d+)\\s+\" \\
        \"EndFragment:(\\d+)\\s+\" \\
        \"StartSelection:(\\d+)\\s+\" \\
        \"EndSelection:(\\d+)\\s+\" \\
        \"SourceURL:(\\S+)\"
    MARKER_BLOCK_EX_RE = re.compile(MARKER_BLOCK_EX)

    MARKER_BLOCK = \
        \"Version:(\\S+)\\s+\" \\
        \"StartHTML:(\\d+)\\s+\" \\
        \"EndHTML:(\\d+)\\s+\" \\
        \"StartFragment:(\\d+)\\s+\" \\
        \"EndFragment:(\\d+)\\s+\" \\
           \"SourceURL:(\\S+)\"
    MARKER_BLOCK_RE = re.compile(MARKER_BLOCK)

    DEFAULT_HTML_BODY = \
        \"<!DOCTYPE HTML PUBLIC \\\"-//W3C//DTD HTML 4.0 Transitional//EN\\\">\" \\
        \"<HTML><HEAD></HEAD><BODY><!--StartFragment-->%s<!--EndFragment--></BODY></HTML>\"

    def __init__(self):
        self.html = None
        self.fragment = None
        self.selection = None
        self.source = None
        self.htmlClipboardVersion = None


    def GetCfHtml(self):
        \"\"\"
        Return the FORMATID of the HTML format
        \"\"\"
        if self.CF_HTML is None:
            self.CF_HTML = win32clipboard.RegisterClipboardFormat(\"HTML Format\")

        return self.CF_HTML


    def GetAvailableFormats(self):
        \"\"\"
        Return a possibly empty list of formats available on the clipboard
        \"\"\"
        formats = []
        try:
            win32clipboard.OpenClipboard(0)
            cf = win32clipboard.EnumClipboardFormats(0)
            while (cf != 0):
                formats.append(cf)
                cf = win32clipboard.EnumClipboardFormats(cf)
        finally:
            win32clipboard.CloseClipboard()

        return formats


    def HasHtmlFormat(self):
        \"\"\"
        Return a boolean indicating if the clipboard has data in HTML format
        \"\"\"
        return (self.GetCfHtml() in self.GetAvailableFormats())


    def GetFromClipboard(self):
        \"\"\"
        Read and decode the HTML from the clipboard
        \"\"\"

        try:
            win32clipboard.OpenClipboard(0)
            src = win32clipboard.GetClipboardData(self.GetCfHtml())
            self.DecodeClipboardSource(src.decode('utf-8'))
        finally:
            win32clipboard.CloseClipboard()


    def DecodeClipboardSource(self, src):
        \"\"\"
        Decode the given string to figure out the details of the HTML that's on the string
        \"\"\"
                    # Try the extended format first (which has an explicit selection)
        matches = self.MARKER_BLOCK_EX_RE.match(src)
        if matches:
            self.prefix = matches.group(0)
            self.htmlClipboardVersion = matches.group(1)
            self.html = src[int(matches.group(2)):int(matches.group(3))]
            self.fragment = src[int(matches.group(4)):int(matches.group(5))]
            self.selection = src[int(matches.group(6)):int(matches.group(7))]
            self.source = matches.group(8)
        else:
                    # Failing that, try the version without a selection
            matches = self.MARKER_BLOCK_RE.match(src)
            if matches:
                self.prefix = matches.group(0)
                self.htmlClipboardVersion = matches.group(1)
                self.html = src[int(matches.group(2)):int(matches.group(3))]
                self.fragment = src[int(matches.group(4)):int(matches.group(5))]
                self.source = matches.group(6)
                self.selection = self.fragment


    def GetHtml(self, refresh=False):
        \"\"\"
        Return the entire Html document
        \"\"\"
        if not self.html or refresh:
            self.GetFromClipboard()
        return self.html


    def GetFragment(self, refresh=False):
        \"\"\"
        Return the Html fragment. A fragment is well-formated HTML enclosing the selected text
        \"\"\"
        if not self.fragment or refresh:
            self.GetFromClipboard()
        return self.fragment


    def GetSelection(self, refresh=False):
        \"\"\"
        Return the part of the HTML that was selected. It might not be well-formed.
        \"\"\"
        if not self.selection or refresh:
            self.GetFromClipboard()
        return self.selection


    def GetSource(self, refresh=False):
        \"\"\"
        Return the URL of the source of this HTML
        \"\"\"
        if not self.selection or refresh:
            self.GetFromClipboard()
        return self.source


    def PutFragment(self, fragment, selection=None, html=None, source=None):
        \"\"\"
        Put the given well-formed fragment of Html into the clipboard.

        selection, if given, must be a literal string within fragment.
        html, if given, must be a well-formed Html document that textually
        contains fragment and its required markers.
        \"\"\"
        if selection is None:
            selection = fragment
        if html is None:
            html = self.DEFAULT_HTML_BODY % fragment
        if source is None:
            source = \"\"

        fragmentStart = html.index(fragment)
        fragmentEnd = fragmentStart + len(fragment)
        selectionStart = html.index(selection)
        selectionEnd = selectionStart + len(selection)
        self.PutToClipboard(html, fragmentStart, fragmentEnd, selectionStart, selectionEnd, source)


    def PutToClipboard(self, html, fragmentStart, fragmentEnd, selectionStart, selectionEnd, source=\"None\"):
        \"\"\"
        Replace the Clipboard contents with the given html information.
        \"\"\"

        try:
            win32clipboard.OpenClipboard(0)
            win32clipboard.EmptyClipboard()
            src = self.EncodeClipboardSource(html, fragmentStart, fragmentEnd, selectionStart, selectionEnd, source)
            win32clipboard.SetClipboardData(self.GetCfHtml(), src.encode('utf-8'))
        finally:
            win32clipboard.CloseClipboard()


    def EncodeClipboardSource(self, html, fragmentStart, fragmentEnd, selectionStart, selectionEnd, source):
        \"\"\"
        Join all our bits of information into a string formatted as per the HTML format specs.
        \"\"\"
                    # How long is the prefix going to be?
        dummyPrefix = self.MARKER_BLOCK_OUTPUT % (0, 0, 0, 0, 0, 0, source)
        lenPrefix = len(dummyPrefix)

        prefix = self.MARKER_BLOCK_OUTPUT % (lenPrefix, len(html)+lenPrefix,
                        fragmentStart+lenPrefix, fragmentEnd+lenPrefix,
                        selectionStart+lenPrefix, selectionEnd+lenPrefix,
                        source)
        return (prefix + html)


def DumpHtml():

    cb = HtmlClipboard()
    print(\"GetAvailableFormats()=%s\" % str(cb.GetAvailableFormats()))
    print(\"HasHtmlFormat()=%s\" % str(cb.HasHtmlFormat()))
    if cb.HasHtmlFormat():
        cb.GetFromClipboard()
        print(\"prefix=>>>%s<<<END\" % cb.prefix)
        print(\"htmlClipboardVersion=>>>%s<<<END\" % cb.htmlClipboardVersion)
        print(\"GetSelection()=>>>%s<<<END\" % cb.GetSelection())
        print(\"GetFragment()=>>>%s<<<END\" % cb.GetFragment())
        print(\"GetHtml()=>>>%s<<<END\" % cb.GetHtml())
        print(\"GetSource()=>>>%s<<<END\" % cb.GetSource())


if __name__ == '__main__':
    import sys
    data = sys.stdin.read()
    PutHtml(data)
"
  "Windows Python Script for copying formatted text.")

(defcustom ox-clip-default-latex-scale 3
  "Default scale to use in `org-format-latex-options'.
Used when creating preview images for copying."
  :group 'ox-clip
  :type 'number)

;; Create the windows python script if needed.
(when (and (eq system-type 'windows-nt)
	   (not (file-exists-p (expand-file-name
				"html-clip-w32.py"
				(file-name-directory (or load-file-name (locate-library "ox-clip")))))))
  (with-temp-file (expand-file-name
		   "html-clip-w32.py"
		   (file-name-directory (or load-file-name (locate-library "ox-clip"))))
    (insert ox-clip-w32-py)))


;;;###autoload
(defun ox-clip-formatted-copy (r1 r2)
  "Export the selected region to HTML and copy it to the clipboard.
R1 and R2 define the selected region."
  (interactive "r")
  (copy-region-as-kill r1 r2)
  (if (equal major-mode 'org-mode)
      (save-window-excursion
        (let* ((org-html-with-latex 'dvipng)
	       (buf (org-export-to-buffer 'html "*Formatted Copy*" nil nil t t))
               (html (with-current-buffer buf (buffer-string))))
          (cond
           ((eq system-type 'windows-nt)
            (with-current-buffer buf
              (shell-command-on-region
               (point-min)
               (point-max)
               ox-clip-w32-cmd)))
           ((eq system-type 'darwin)
            (with-current-buffer buf
              (shell-command-on-region
               (point-min)
               (point-max)
               ox-clip-osx-cmd)))
           ((eq system-type 'gnu/linux)
            ;; For some reason shell-command on region does not work with xclip.
	    (let* ((tmpfile (make-temp-file "ox-clip-" nil ".html"
					    (with-current-buffer buf (buffer-string))))
		   (proc (apply
			  'start-process "ox-clip" "*ox-clip*"
			  (split-string-and-unquote
			   (format-spec ox-clip-linux-cmd
					`((?f . ,tmpfile))) " "))))
	      (set-process-query-on-exit-flag proc nil))))
          (kill-buffer buf)))
    ;; Use htmlize when not in org-mode.
    (let ((html (htmlize-region-for-paste r1 r2)))
      (cond
       ((eq system-type 'windows-nt)
        (with-temp-buffer
          (insert html)
          (shell-command-on-region
           (point-min)
           (point-max)
           ox-clip-w32-cmd)))
       ((eq system-type 'darwin)
        (with-temp-buffer
          (insert html)
          (shell-command-on-region
           (point-min)
           (point-max)
           ox-clip-osx-cmd)))
       ((eq system-type 'gnu/linux)
	(let* ((tmpfile (make-temp-file "ox-clip-" nil ".html" html))
	       (proc (apply
		      'start-process "ox-clip" "*ox-clip*"
		      (split-string-and-unquote
		       (format-spec ox-clip-linux-cmd
				    `((?f . ,tmpfile))) " "))))
	  (set-process-query-on-exit-flag proc nil)))))))


;; * copy images / latex fragments to the clipboard
(defun ox-clip-ov-at ()
  "Get overlay at point.  A helper to avoid dependency on ov.el."
  (car (overlays-at (point))))

;;;###autoload
(defun ox-clip-image-to-clipboard (&optional scale)
  "Copy the image file or latex fragment at point to the clipboard as an image.
SCALE is a numerical
prefix (default=`ox-clip-default-latex-scale') that determines
the size of the latex image. It has no effect on other kinds of
images. Currently only works on Linux."
  (interactive "P")
  (let* ((el (org-element-context))
	 (image-file (cond
		      ;; on a latex fragment
		      ((eq 'latex-fragment (org-element-type el))
		       (when (ox-clip-ov-at) (org-latex-preview))

		       ;; should be no image, so we rebuild one
		       (let ((current-scale (plist-get org-format-latex-options :scale))
			     ov display file relfile)
			 (plist-put org-format-latex-options :scale
				    (or scale ox-clip-default-latex-scale))
			 (org-latex-preview)
			 (plist-put org-format-latex-options :scale current-scale)

			 (setq ov (ox-clip-ov-at)
			       display (overlay-get ov 'display)
			       file (plist-get (cdr display) :file))
			 (file-relative-name file)))
		      ;; At a link of an image
		      ((and (eq 'link (org-element-type el))
			    (string= "file" (org-element-property :type el))
			    (string-match (cdr (assoc "file" org-html-inline-image-rules))
					  (org-element-property :path el)))
		       (file-relative-name (org-element-property :path el)))
		      ;; At a link of an image (which is an attachment)
		      ((and (eq 'link (org-element-type el))
			    (string= "attachment" (org-element-property :type el))
			    (string-match (cdr (assoc "file" org-html-inline-image-rules))
					  (org-element-property :path el)))
		       (file-relative-name (org-attach-expand (org-element-property :path el))))
		      ;; at an overlay with a display that is an image
		      ((and (ox-clip-ov-at)
			    (overlay-get (ox-clip-ov-at) 'display)
			    (plist-get (cdr (overlay-get (ox-clip-ov-at) 'display)) :file)
			    (string-match (cdr (assoc "file" org-html-inline-image-rules))
					  (plist-get (cdr (overlay-get (ox-clip-ov-at) 'display))
						     :file)))
		       (file-relative-name (plist-get (cdr (overlay-get (ox-clip-ov-at) 'display))
						      :file)))
		      ;; not sure what else we can do here.
		      (t
		       nil))))
    (when image-file
      (cond
       ((eq system-type 'windows-nt)
	(message "Not supported yet."))
       ((eq system-type 'darwin)
	(do-applescript
	 (format "set the clipboard to POSIX file \"%s\"" (expand-file-name image-file))))
       ((eq system-type 'gnu/linux)
	(call-process-shell-command
	 (format "xclip -selection clipboard -t image/%s -i %s"
		 (file-name-extension image-file)
		 image-file)))))
    (message "Copied %s" image-file)))

(provide 'ox-clip)

;;; ox-clip.el ends here
