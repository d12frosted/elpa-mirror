;;; scratch-message.el --- Changing message in your scratch buffer

;; Copyright (C) 2013-2017 Sylvain Rousseau

;; Author: Sylvain Rousseau <thisirs at gmail dot com>
;; Maintainer: Sylvain Rousseau <thisirs at gmail dot com>
;; URL: https://github.com/thisirs/scratch-message.git
;; Package-Version: 20220209.2207
;; Package-Commit: 0d4198f6effd8f118bf03ee4979f566041ef6a9b
;; Keywords: util scratch

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This utility allows you to automatically insert messages in your
;; scratch buffer coming from various sources.

;;; Installation:

;; Just put the following in your .emacs:

;; (require 'scratch-message)

;; and customize the variable `scratch-message-quotes' holding the
;; list of quotes or the variable `scratch-message-function'.

;;; Code:

;;; Customization
(defgroup scratch-message nil
  "Changing message in your scratch buffer."
  :group 'environment)

(defcustom scratch-message-function 'scratch-message-function-default
  "Function called by `scratch-message-trigger-message' that
should generate a message and insert it by calling
`scratch-message-insert'."
  :group 'scratch-message
  :type 'function)

(defcustom scratch-message-interval 10
  "Time in seconds to wait between two messages."
  :group 'scratch-message
  :type 'number)

(defcustom scratch-message-invisible t
  "If non-nil, do not change message if the scratch buffer is
visible."
  :group 'scratch-message
  :type 'boolean)

(defcustom scratch-message-retry 3
  "Time in seconds to wait before trying to redisplay."
  :group 'scratch-message
  :type 'number)

(defcustom scratch-message-quotes
  '("You can do anything, but not everything.
                                                                   - David Allen"
    "Perfection is achieved, not when there is nothing more to add, but when there is
nothing left to take away.
                                                      - Antoine de Saint-Exupéry"
    "The richest man is not he who has the most, but he who needs the least.
                                                                - Unknown Author"
    "You miss 100 percent of the shots you never take.
                                                                 - Wayne Gretzky"
    "Courage is not the absence of fear, but rather the judgement that something else
is more important than fear.
                                                               - Ambrose Redmoon"
    "You must be the change you wish to see in the world.
                                                                        - Gandhi"
    "When hungry, eat your rice; when tired, close your eyes. Fools may laugh at me,
but wise men will know what I mean.
                                                                       - Lin-Chi"
    "The third-rate mind is only happy when it is thinking with the majority. The
second-rate mind is only happy when it is thinking with the minority. The
first-rate mind is only happy when it is thinking.
                                                                   - A. A. Milne"
    "To the man who only has a hammer, everything he encounters begins to look like a
nail.
                                                                - Abraham Maslow"
    "We are what we repeatedly do; excellence, then, is not an act but a habit.
                                                                     - Aristotle"
    "A wise man gets more use from his enemies than a fool from his friends.
                                                              - Baltasar Gracian"
    "Do not seek to follow in the footsteps of the men of old; seek what they sought.
                                                                         - Basho"
    "Watch your thoughts; they become words.
Watch your words; they become actions.
Watch your actions; they become habits.
Watch your habits; they become character.
Watch your character; it becomes your destiny.
                                                                       - Lao-Tze"
    "Everyone is a genius at least once a year. The real geniuses simply have their
bright ideas closer together.
                                                   - Georg Christoph Lichtenberg"
    "What we think, or what we know, or what we believe is, in the end, of little
consequence. The only consequence is what we do.
                                                                   - John Ruskin"
    "The real voyage of discovery consists not in seeking new lands but seeing with
new eyes.
                                                                 - Marcel Proust"
    "Work like you don’t need money, love like you’ve never been hurt, and dance like
no one’s watching
                                                                - Unknown Author"
    "Try a thing you haven’t done three times. Once, to get over the fear of doing
it. Twice, to learn how to do it. And a third time, to figure out whether you
like it or not.
                                                        - Virgil Garnett Thomson"
    "Even if you’re on the right track, you’ll get run over if you just sit there.
                                                                   - Will Rogers"
    "People often say that motivation doesn’t last. Well, neither does bathing -
that’s why we recommend it daily.
                                                                        - Zig Ziglar"
    "Before I got married I had six theories about bringing up children; now I have
six children and no theories.
                                                                   - John Wilmot"
    "What the world needs is more geniuses with humility, there are so few of us
left.
                                                                  - Oscar Levant"
    "Always forgive your enemies; nothing annoys them so much.
                                                                   - Oscar Wilde"
    "I’ve gone into hundreds of [fortune-teller’s parlors], and have been told
thousands of things, but nobody ever told me I was a policewoman getting ready
to arrest her.
                                                       - New York City detective"
    "When you go into court you are putting your fate into the hands of twelve people
who weren’t smart enough to get out of jury duty.
                                                                   - Norm Crosby"
    "Those who believe in telekinetics, raise my hand.
                                                                 - Kurt Vonnegut"
    "Just the fact that some geniuses were laughed at does not imply that all who are
laughed at are geniuses. They laughed at Columbus, they laughed at Fulton, they
laughed at the Wright brothers. But they also laughed at Bozo the Clown.
                                                                    - Carl Sagan"
    "My pessimism extends to the point of even suspecting the sincerity of the
pessimists.
                                                                  - Jean Rostand"
    "Sometimes I worry about being a success in a mediocre world.
                                                                   - Lily Tomlin"
    "I quit therapy because my analyst was trying to help me behind my back.
                                                                 - Richard Lewis"
    "We’ve heard that a million monkeys at a million keyboards could produce the
complete works of Shakespeare; now, thanks to the Internet, we know that is not
true.
                                                               - Robert Wilensky"
    "If there are no stupid questions, then what kind of questions do stupid people
ask? Do they get smart just in time to ask questions?
                                                                   - Scott Adams"
    "If the lessons of history teach us anything it is that nobody learns the lessons
that history teaches us.
                                                                          - Anon"
    "When I was a boy I was told that anybody could become President. Now I’m
beginning to believe it.
                                                               - Clarence Darrow"
    "Laughing at our mistakes can lengthen our own life. Laughing at someone else’s
can shorten it.
                                                              - Cullen Hightower"
    "There are many who dare not kill themselves for fear of what the neighbors will
say.
                                                                - Cyril Connolly"
    "There’s so much comedy on television. Does that cause comedy in the streets?
                                                                   - Dick Cavett"
    "All men are frauds. The only difference between them is that some admit it. I
myself deny it.
                                                                 - H. L. Mencken"
    "I don’t mind what Congress does, as long as they don’t do it in the streets and
frighten the horses.
                                                                   - Victor Hugo"
    "I took a speed reading course and read ‘War and Peace’ in twenty minutes. It
involves Russia.
                                                                   - Woody Allen"
    "The person who reads too much and uses his brain too little will fall into lazy
habits of thinking.
                                                               - Albert Einstein"
    "Believe those who are seeking the truth. Doubt those who find it.
                                                                    - André Gide"
    "It is the mark of an educated mind to be able to entertain a thought without
accepting it.
                                                                     - Aristotle"
    "I’d rather live with a good question than a bad answer.
                                                                  - Aryeh Frimer"
    "We learn something every day, and lots of times it’s that what we learned the
day before was wrong.
                                                                  - Bill Vaughan"
    "I have made this letter longer than usual because I lack the time to make it
shorter.
                                                                 - Blaise Pascal"
    "Don’t ever wrestle with a pig. You’ll both get dirty, but the pig will enjoy it.
                                                               - Cale Yarborough"
    "An inventor is simply a fellow who doesn’t take his education too seriously.
                                                          - Charles F. Kettering"
    "Asking a working writer what he thinks about critics is like asking a lamppost
how it feels about dogs.
                                                           - Christopher Hampton"
    "Better to write for yourself and have no public, than to write for the public
and have no self.
                                                                - Cyril Connolly"
    "Never be afraid to laugh at yourself, after all, you could be missing out on the
joke of the century.
                                                             - Dame Edna Everage"
    "I am patient with stupidity but not with those who are proud of it.
                                                                 - Edith Sitwell"
    "Normal is getting dressed in clothes that you buy for work and driving through
traffic in a car that you are still paying for – in order to get to the job you
need to pay for the clothes and the car, and the house you leave vacant all day
so you can afford to live in it.
                                                                 - Ellen Goodman"
    "The cure for boredom is curiosity. There is no cure for curiosity.
                                                                    - Ellen Parr"
    "Advice is what we ask for when we already know the answer but wish we didn’t.
                                                                    - Erica Jong"
    "Some people like my advice so much that they frame it upon the wall instead of
using it.
                                                             - Gordon R. Dickson"
    "The trouble with the rat race is that even if you win, you’re still a rat.
                                                                   - Lily Tomlin"
    "Never ascribe to malice, that which can be explained by incompetence.
                                                     - Napoleon (Hanlon’s Razor)"
    "Imagination was given to man to compensate him for what he is not, and a sense
of humor was provided to console him for what he is.
                                                                   - Oscar Wilde"
    "When a person can no longer laugh at himself, it is time for others to laugh at
him.
                                                                  - Thomas Szasz")
  "Some quotes taken from https://litemind.com/best-famous-quotes/"
  :group 'scratch-message
  :type '(repeat string))

;; Internal variables
(defvar scratch-message-timer nil)
(defvar scratch-message-beg-marker (make-marker))
(defvar scratch-message-end-marker (make-marker))
(defvar scratch-message-timestamp nil)

(defun scratch-message-function-default ()
  "Default function called to display a new quote."
  (scratch-message-insert (nth (random (length scratch-message-quotes)) scratch-message-quotes)))

(defun scratch-message-fortune ()
  "Return a fortune as a string.

You need to properly set the value of `fortune-file' first. This
function can be used in place of
`scratch-message-function-default'."
  (require 'fortune)
  (fortune-in-buffer t)
  (scratch-message-insert
   (with-current-buffer fortune-buffer-name
     (buffer-string))))

(defun scratch-message-insert (message)
  "Replace or insert the message MESSAGE in the scratch buffer.

If there is no previous message, insert MESSAGE at the end of the
buffer, make sure we are on a beginning of a line and add three
newlines at the end of the message."
  (if (get-buffer "*scratch*")
      (with-current-buffer "*scratch*"
        (let ((bm (buffer-modified-p)))
          (if (and (marker-position scratch-message-beg-marker)
                   (marker-position scratch-message-end-marker))
              (delete-region scratch-message-beg-marker scratch-message-end-marker))
          (save-excursion
            (if (marker-position scratch-message-beg-marker)
                (goto-char (marker-position scratch-message-beg-marker))
              (goto-char (point-min))
              (search-forward (or initial-scratch-message "") nil t)
              (or (bolp) (insert "\n"))
              (save-excursion (insert "\n\n\n")))
            (set-marker scratch-message-beg-marker (point))
            (insert message)
            (set-marker scratch-message-end-marker (point))
            (let ((comment-start (or comment-start " ")))
              (comment-region scratch-message-beg-marker
                              scratch-message-end-marker)))
          (set-buffer-modified-p bm)))
    (error "No scratch buffer")))

(defun scratch-message-trigger-message ()
  "Display a new message and schedule for a new one.

The function `scratch-message-function' that is actually
displaying a new message is called when the two following
conditions hold:

- the previous message has already been seen (the *scratch*
  buffer has been displayed in a window). If is has not, a retry
  is scheduled in `scratch-message-retry' seconds.

- the *scratch* buffer is not currently displayed in a window (can
  be customized with `scratch-message-invisible'."
  (if (and scratch-message-invisible
           (get-buffer-window "*scratch*"))
      (setq scratch-message-timer
            (run-with-timer scratch-message-retry nil 'scratch-message-trigger-message))
    (when (and (get-buffer "*scratch*")
               (or (not scratch-message-timestamp)
                   (and (let ((ts (buffer-local-value 'buffer-display-time
                                                      (get-buffer "*scratch*"))))
                          (and ts (time-less-p scratch-message-timestamp ts))))))
      (with-demoted-errors "scratch-message error: %S"
          (funcall scratch-message-function))
      (setq scratch-message-timestamp (current-time)))
    (setq scratch-message-timer (run-with-timer
                                 scratch-message-interval
                                 nil
                                 'scratch-message-trigger-message))))

;;;###autoload
(define-minor-mode scratch-message-mode
  "Minor mode to insert message in your scratch buffer."
  :lighter ""
  :global t
  (if scratch-message-mode
      (unless (timerp scratch-message-timer)
        (setq scratch-message-timer (run-with-timer 30 nil 'scratch-message-trigger-message)))
    (if (timerp scratch-message-timer) (cancel-timer scratch-message-timer))
    (setq scratch-message-timer nil)))


(provide 'scratch-message)

;;; scratch-message.el ends here
