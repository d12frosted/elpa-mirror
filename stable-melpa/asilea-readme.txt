Asilea is a library using simulated annealing to try to find best compiler
options, where "best" is typically either the fastest executable or the
smallest one, but may be any arbitrary metric.

Typical usage (assuming lexical binding):

(let* ((asilea-max-steps 1000)
       (solution nil)
       (asilea-solution-accepted-function
        (lambda (state energy)
          (setq solution (cons state energy))))
       (asilea-finished-function
        (lambda ()
          (message "Solution found: %s (score: %s)"
                   (car solution)
                   (cdr solution)))))
  (asilea-run
   ;; timing-script is a script that compiles the program, measures
   ;; the time and/or size, and prints the score ("energy") on the
   ;; stdout. By default, lower energy is better.
   "timing-script"
   [["-O2" "-O3" "-Ofast" "-Os"]
    [nil "-ffast-math"]
    [nil "-ffoo" ("-ffoo" "-fbar")]
    [nil "-fexample-optimization"]
    ;; and so on
    ]))

For more details, see the function `asilea-run' and variables whose names
start with `asilea-'.
