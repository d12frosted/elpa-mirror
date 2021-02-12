Inspired by Go tagged structs. 'alist, 'plist and 'json drivers are
provided, but implementing others just requires to inherit from
`marshal-driver'.

Sometimes the types are not enough (for example with lists, whose elements
are not explicitly typed. In those cases, a small extension on top of types
can be used. Like for example :marshal-type (list string)

Examples:

1. Regular use:

(marshal-defclass plop ()
  ((foo :initarg :foo :type string :marshal ((alist . field_foo)))
   (bar :initarg :bar :type integer :marshal ((alist . field_bar)))
   (baz :initarg :baz :type integer :marshal ((alist . field_baz)))))

(marshal-defclass plopi ()
  ((alpha :marshal ((alist . field_alpha)))
   (beta :type plop :marshal ((alist . field_beta)))))

(marshal (make-instance 'plop :foo "ok" :bar 42) 'alist)
=> '((field_bar . 42) (field_foo . "ok"))

(unmarshal 'plop '((field_foo . "plop") (field_bar . 0) (field_baz . 1)) 'alist)
=> '[object plop "plop" "plop" 0 1]

(marshal
 (unmarshal 'plopi '((field_alpha . 42)
                     (field_beta . ((field_foo . "plop")
                                    (field_bar . 0)
                                    (field_baz . 1)))) 'alist)
 'alist)
=> '((field_beta (field_baz . 1) (field_bar . 0) (field_foo . "plop")) (field_alpha . 42))

2. Objects involving lists:

(marshal-defclass foo/tree ()
  ((root :initarg :id :marshal ((plist . :root) json))
   (leaves :initarg :leaves :marshal ((plist . :leaves) json) :marshal-type (list foo/tree))))

(marshal (make-instance 'foo/tree :id 0
           :leaves (list (make-instance 'foo/tree :id 1)
                         (make-instance 'foo/tree :id 2
                           :leaves (list (make-instance 'foo/tree :id 3)))))
         'plist)
=> (:root 0 :leaves ((:root 1) (:root 2 :leaves ((:root 3)))))

(unmarshal 'foo/tree '(:root 0 :leaves ((:root 1) (:root 2 :leaves ((:root 3))))) 'plist)

=> [object foo/tree "foo/tree" 0
           ([object foo/tree "foo/tree" 1 nil]
            [object foo/tree "foo/tree" 2
                    ([object foo/tree "foo/tree" 3 nil])])]

3. Json

(marshal (make-instance 'foo/tree :id 0
           :leaves (list (make-instance 'foo/tree :id 1)
                         (make-instance 'foo/tree :id 2
                           :leaves (list (make-instance 'foo/tree :id 3)))))
         'json)
=> "{\"leaves\":[{\"root\":1},{\"leaves\":[{\"root\":3}],\"root\":2}],\"root\":0}"

(unmarshal 'foo/tree "{\"leaves\":[{\"root\":1},{\"leaves\":[{\"root\":3}],\"root\":2}],\"root\":0}" 'json)
=> [object foo/tree "foo/tree" 0
        ([object foo/tree "foo/tree" 1 nil]
         [object foo/tree "foo/tree" 2
                 ([object foo/tree "foo/tree" 3 nil])])]
