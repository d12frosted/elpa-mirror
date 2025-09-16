Short: it unroll  "callback hell" to static  sequence, also provide
better handling for plist.

Why? Most commonly, you will encounter callbacks in the url.el library.
When you request a page with the (url-retrieve url callback) command,
 control returns immediately. Once the page is retrieved, it is passed
 as parameters to the callback function. This creates a chain of calls,
 which is known as the "callback hell" problem - nested indented bloks.

Async functions don't return "futures/promises".  Instead, together
 they build chain of calls that executed according to pipeline,
 asynchronous.

Other Emacs packages with solution for "callback hell":
- deferred https://github.com/kiwanami/emacs-deferred/tree/master
- promise https://github.com/chuntaro/emacs-promise
- aio https://github.com/skeeto/emacs-aio

What? Static chain of callbacks that unroll at call.

Configuration:
 (require 'async1)

Usage:
 Define and run pipeline of callbacks with `async1-start' function.

Examples 1. Sequential and parallel steps with default template
(async1-start nil
 '((:result "Step 1" :delay 1)
   (:parallel
    (:result "Parallel A" :delay 2)
    (
     (:result "Sub-seq a" :delay 1)
     (:result "Sub-seq b" :delay 1)
     )
    (:result "Parallel B" :delay 2))
   (:result "Step 3" :delay -1)))

"Final result: {Step 1 -> Sub-seq a -> Sub-seq b, Step 1 -> Parallel B, Step 1 -> Parallel A} -> Step 3"

Each async records-functions wrapped in lambda that call to next record with result.
All lambda functions created as a one lambda and we call it.

You may call own function defined with (data callback) parameters.
You   may   redefine    `async-default-aggregator'   for   parallel
 calls.  There may be only one aggregator for now.
:parallel should be at the beginin of list
:aggregator may be anywhere in parallel list

Deep trees should work also.

2. Mixing custom function and parallel steps
(defun custom-async-step (data callback)
  "Custom async function that modifies data differently.
  CALLBACK is optionall and may be ignored, see `async-create-function'
  for refence."
  (run-at-time 1.5 nil callback
               (concat data " -> Custom Step")))

(async1-start nil
 '((:result "Step 1" :delay 1)
   (:parallel
    custom-async-step
    (:result "Parallel B" :delay 1))
   (:result "Step 3" :delay 1)))

3. With custom aggregator
(defun custom-aggregator (results)
  "Custom aggregator that joins results with ' & '."
  (concat "{" (mapconcat 'identity results " & ") "}"))

(async1-start nil
 '((:result "Step 1" :delay 1)
   (:parallel
    (:result "Parallel A" :delay 1)
    (:result "Parallel B" :delay 2)
    :aggregator #'custom-aggregator)))

Output: "Final result: {Step 1 -> Parallel B & Step 1 -> Parallel A}"

4. Use external data in callback and callback with one argument
(let* ((var "myvar")
       (stepcallback)
       (callback1 (lambda (data)
                    (funcall stepcallback (concat data " -> " var))))
       (call (lambda (data callback)
               (setq stepcallback callback)
               (run-at-time 0 nil callback1
                                                  (concat data " -> " "Step1"))))
       )
  (async1-start nil
                     (list call
                           call
                           call
                           )))
Output:  "Final result:  -> Step1 -> myvar -> Step1 -> myvar -> Step1 -> myvar"

5. Use mutable lambdas
(let* ((call (lambda (step)
               (lambda (data callback)
                 (run-at-time 0 nil callback
                              (concat data " -> " "Step" (number-to-string step)))))
             ))
  (async1-start nil
                     (list (funcall call 0)
                           (funcall call 1)
                           (funcall call 2)
                           (funcall call 3))))
Output:  "Final result:  -> Step0 -> Step1 -> Step2 -> Step3"

Battlefield example: ehttps://github.com/Anoncheg1/oai/blob/main/oai-prompt.el

Note:  (`run-at-time'  after-time  repeat function  &rest  args)  -
frequently used to imulate function with callback.
