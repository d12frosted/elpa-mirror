[https://elpa.nongnu.org/nongnu/xml-rpc.svg]
[file:https://stable.melpa.org/packages/xml-rpc-badge.svg]
[file:https://melpa.org/packages/xml-rpc-badge.svg]
[https://github.com/xml-rpc-el/xml-rpc-el/workflows/CI/badge.svg]


[https://elpa.nongnu.org/nongnu/xml-rpc.svg]
<https://elpa.nongnu.org/nongnu/xml-rpc.html>

[file:https://stable.melpa.org/packages/xml-rpc-badge.svg]
<https://stable.melpa.org/#/xml-rpc>

[file:https://melpa.org/packages/xml-rpc-badge.svg]
<https://melpa.org/#/xml-rpc>

[https://github.com/xml-rpc-el/xml-rpc-el/workflows/CI/badge.svg]
<https://github.com/xml-rpc-el/xml-rpc-el/actions>


1 Commentary:
═════════════

  This is an [XML-RPC] client implementation in elisp, capable of both
  synchronous and asynchronous method calls (using the url package's
  async retrieval functionality).

  XML-RPC is remote procedure calls over HTTP using XML to describe the
  function call and return values.

  xml-rpc.el represents XML-RPC datatypes as lisp values, automatically
  converting to and from the XML datastructures as needed, both for
  method parameters and return values, making using XML-RPC methods
  fairly transparent to the lisp code.


[XML-RPC] <http://xmlrpc.com/>


2 Installation:
═══════════════

  If you use [ELPA], and have configured the [NonGNU ELPA] or [MELPA]
  repository, then `M-x package-install RET xml-rpc RET' interface. This
  is preferable as you will have access to updates automatically.

  If you would like to use ELPA, but this is your first time to use it,
  or NonGNU ELPA/MELPA, then try evaluating the following code in emacs:
  ┌────
  │ (progn
  │   (require 'package)
  │   (add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
  │   (unless (package-installed-p 'xml-rpc)
  │     (with-temp-buffer
  │       (url-insert-file-contents "https://raw.githubusercontent.com/xml-rpc-el/xml-rpc-el/master/xml-rpc.el")
  │       (package-install-from-buffer))))
  └────

  Otherwise, just make sure this file in your load-path (usually
  `~/.emacs.d' is included) and put
  ┌────
  │ (require 'xml-rpc) 
  └────
  in your `~/.emacs' or `~/.emacs.d/init.el' file.


[ELPA] <http://elpa.gnu.org/>

[NonGNU ELPA] <https://elpa.nongnu.org/>

[MELPA] <https://melpa.org/>


3 Requirements
══════════════

  xml-rpc.el uses the url package for http handling and `xml.el' for XML
  parsing or, if you have Emacs 27+ with `libxml' included,
  `libxml'. The url package that is part of Emacs works fine.


4 Bug reports
═════════════

  Please use `M-x xml-rpc-submit-bug-report' to report bugs directly to
  the maintainer, or use [github's issue system].


[github's issue system]
<https://github.com/xml-rpc-el/xml-rpc-el/issues>


5 Representing data types
═════════════════════════

  XML-RPC datatypes are represented as follows

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   type          data                                   
   int           42                                     
   float/double  42.0                                   
   string        "foo"                                  
   base64        (list :base64                          
                 (base64-encode-string "hello" t))      
                 '(:base64 "aGVsbG8=")                  
   array         '(1 2 3 4)   '(1 2 3 (4.1 4.2))  [ ]   
                 '(:array (("not" "a") ("struct" "!"))) 
   struct        '(("name" . "daniel")                  
                 ("height" . 6.1))                      
   dateTime      '(:datetime (1234 124))                
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


6 Examples
══════════

  Here follows some examples demonstrating the use of xml-rpc.el


6.1 Normal synchronous operation
────────────────────────────────

  ┌────
  │ (xml-rpc-method-call "http://localhost:80/RPC" 'foo-method foo bar zoo)
  └────


6.2 Asynchronous example (cb-foo will be called when the methods returns)
─────────────────────────────────────────────────────────────────────────

  ┌────
  │ (defun cb-foo (foo)
  │   (print (format "%s" foo)))
  │ 
  │ (xml-rpc-method-call-async 'cb-foo "http://localhost:80/RPC"
  │ 			   'foo-method foo bar zoo)
  └────


6.3 Some real world working examples for fun and play
─────────────────────────────────────────────────────

  These were last tested working on 2020-09-06.


6.3.1 Fetch the first state name from UserLand's server
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (xml-rpc-method-call "http://betty.userland.com/rpc2"
  │ 		     'examples.getStateName '(1))
  └────

  Results in:

  ┌────
  │ Alabama
  └────


6.3.2 Get a list of supported methods from a blog
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ┌────
  │ (mapconcat (lambda (s) (when s s))
  │   (xml-rpc-method-call "https://hexmode.wordpress.com/xmlrpc.php"
  │ 		       'mt.supportedMethods)
  │   ", ")
  └────

  Results in:
  ┌────
  │ wp.getUsersBlogs, wp.newPost, wp.editPost, wp.deletePost, wp.getPost, wp.getPosts, wp.newTerm, wp.editTerm, wp.deleteTerm, wp.getTerm, wp.getTerms, wp.getTaxonomy, wp.getTaxonomies, wp.getUser, wp.getUsers, wp.getProfile, wp.editProfile, wp.getPage, wp.getPages, wp.newPage, wp.deletePage, wp.editPage, wp.getPageList, wp.getAuthors, wp.getCategories, wp.getTags, wp.newCategory, wp.deleteCategory, wp.suggestCategories, wp.uploadFile, wp.deleteFile, wp.getCommentCount, wp.getPostStatusList, wp.getPageStatusList, wp.getPageTemplates, wp.getOptions, wp.setOptions, wp.getComment, wp.getComments, wp.deleteComment, wp.editComment, wp.newComment, wp.getCommentStatusList, wp.getMediaItem, wp.getMediaLibrary, wp.getPostFormats, wp.getPostType, wp.getPostTypes, wp.getRevisions, wp.restoreRevision, blogger.getUsersBlogs, blogger.getUserInfo, blogger.getPost, blogger.getRecentPosts, blogger.newPost, blogger.editPost, blogger.deletePost, metaWeblog.newPost, metaWeblog.editPost, metaWeblog.getPost, metaWeblog.getRecentPosts, metaWeblog.getCategories, metaWeblog.newMediaObject, metaWeblog.deletePost, metaWeblog.getUsersBlogs, mt.getCategoryList, mt.getRecentPostTitles, mt.getPostCategories, mt.setPostCategories, mt.supportedMethods, mt.supportedTextFilters, mt.getTrackbackPings, mt.publishPost, pingback.ping, pingback.extensions.getPingbacks, demo.sayHello, demo.addTwoNumbers, wpStats.get_key, wpStats.check_key, wpStats.get_blog_id, wpStats.get_site_id, wpStats.update_bloginfo, wpStats.update_postinfo, wpStats.ping_blog, wpStats.flush_posts, wpcom.get_user_blogids, wpcom.getFeatures, wpcom.addApplicationPassword, wpcom.blackberryUploadFile, wpcom.blackberryGetUploadingFileKeys, wpcom.getUsersSubs, wpcom.set_mobile_push_notification_settings, wpcom.get_mobile_push_notification_settings, wpcom.mobile_push_register_token, wpcom.mobile_push_unregister_token, wpcom.mobile_push_set_blogs_list, wpcom.mobile_push_win_phone_get_last_notification
  └────
