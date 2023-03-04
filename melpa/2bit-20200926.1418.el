;;; 2bit.el --- Library for reading data from 2bit files -*- lexical-binding: t -*-
;; Copyright 2020 by Dave Pearson <davep@davep.org>

;; Author: Dave Pearson <davep@davep.org>
;; Version: 1.0
;; Keywords: files, data
;; URL: https://github.com/davep/2bit.el
;; Package-Requires: ((emacs "24.3"))

;; This program is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation, either version 3 of the License, or (at your
;; option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
;; Public License for more details.
;;
;; You should have received a copy of the GNU General Public License along
;; with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; 2bit.el provides functions and commands that help extract data from 2bit
;; files. Please see https://github.com/davep/2bit.el/blob/main/README.md
;; for more details on what this package provides.

;;; Code:

(require 'rx)
(require 'cl-lib)

(defconst 2bit-signature #x1a412743
  "2bit file signature.")

(defconst 2bit-bases ["T" "C" "A" "G"]
  "Vector of the bases.

Note that the positions of each base in the vector map to the 2bit decoding
for them.")

(cl-defstruct 2bit-data
  "Structure that holds details about a 2bit data source."
  ;; The source of data.
  source
  ;; The signature of the data.
  signature
  ;; Is the data in an other endianness?
  other-endian-p
  ;; The version of the data.
  version
  ;; The number of sequences in the data.
  sequence-count
  ;; Should masking be taken into account when reading the data?
  masking
  ;; The index of the 2bit data.
  index
  ;; The position to next read from in the file.
  pos)

(cl-defstruct 2bit-block-collection
  "Structure that holds details the collection of blocks in a 2bit file."
  ;; The count of entries in the block collection.
  count
  ;; The start locations of each block in the collection.
  starts
  ;; The sizes of each block in the collection.
  sizes)

(defun 2bit--relevant-blocks (start end blocks)
  "Return a list of BLOCKS that intersect START and END."
  ;; Note that, to save some work elsewhere, for mask-blocks we don't bother
  ;; spinning up a `2bit-block-collection', so BLOCKS can be nil. Allow for
  ;; that and simply return an empty list.
  (when blocks
    (cl-loop for block-start in (2bit-block-collection-starts blocks)
             for block-size  in (2bit-block-collection-sizes blocks)
             for block-end = (+ block-start block-size)
             if (and (>= end block-start) (> block-end start))
             collect (cons block-start block-end))))

(cl-defstruct 2bit-sequence
  "Structure that holds details about a 2bit sequence."
  ;; The source of the sequence data.
  source
  ;; The name of the sequence.
  name
  ;; The size of the DNA sequence.
  dna-size
  ;; Details of the blocks of Ns in the sequence.
  n-blocks
  ;; Details of the masked blocks in the sequence.
  mask-blocks
  ;; he location in the data where the actual DNA data starts.
  dna-offset)

(defsubst 2bit--goto (source pos)
  "Goto position POS in SOURCE."
  (setf (2bit-data-pos source) pos))

(defsubst 2bit--skip (source bytes)
  "Skip BYTES bytes in SOURCE."
  (cl-incf (2bit-data-pos source) bytes))

(defun 2bit--read (source length)
  "Read binary data from SOURCE.

Data will be read from the `2bit-data-pos' of SOURCE and will be
read for LENGTH bytes. As a side effect `2bit-data-pos' of SOURCE
will be increased by LENGTH bytes."
  (with-temp-buffer
    (set-buffer-multibyte nil)
    (let ((coding-system-for-read 'binary))
      (insert-file-contents-literally
       (2bit-data-source source)
       nil
       (2bit-data-pos source)
       (+ (2bit-data-pos source) length))
      (2bit--skip source length)
      (buffer-string))))

(defsubst 2bit--word-swap (value)
  "Swap the endianness of 32-bit word VALUE."
  (logior
   (logand (ash value -24) #xff)
   (logand (ash value -8) #xff00)
   (logand (ash value 8) #xff0000)
   (logand (ash value 24) #xff000000)))

(defsubst 2bit--word-from-bytes (source bytes)
  "Convert a binary word in BYTES into an int.

While SOURCE isn't used to read anything, it is used to know if
any endian issues should be taken into account."
  (let ((word (logior
               (aref bytes 0)
               (ash (aref bytes 1) 8)
               (ash (aref bytes 2) 16)
               (ash (aref bytes 3) 24))))
    (if (2bit-data-other-endian-p source)
        (2bit--word-swap word)
      word)))

(defun 2bit--read-word (source)
  "Read a 32-bit word from SOURCE.

If `2bit-data-other-endian-p' is t the value will be
endian-swapped using `2bit--word-swap'.

As a side effect `2bit-data-pos' of SOURCE will move by 4 bytes."
  (2bit--word-from-bytes source (2bit--read source 4)))

(defun 2bit--read-index (source)
  "Read the sequence index from SOURCE.

As a side effect `2bit-data-pos' of SOURCE will move."
  (cl-loop
   ;; The index will be a hash of sequence names, with the values being the
   ;; offsets within the file.
   with index = (make-hash-table :test #'equal)
   ;; We could read each name/value pair one by one, but because we're doing
   ;; this within Emacs, which means making a temp buffer for every read,
   ;; that could get pretty expensive pretty fast. So instead we'll read the
   ;; index data in in one go. However, there is no easy-to-calculate size
   ;; for the index. The best we can do is calculate the worst case size. So
   ;; let's do that. The worst case size is the maximum size of the name of
   ;; a sequence (255), plus the size of the byte that tells us the name
   ;; (1), plus the size of the word that is the offset in the file (4).
   with buffer = (2bit--read source (* (2bit-data-sequence-count source) (+ 255 1 4)))
   ;; For every sequence in the file...
   for n from 1 to (2bit-data-sequence-count source)
   ;; Calculate the position within the buffer for this loop around. Note
   ;; that the skip is the last position plus 1 for the size byte plus the
   ;; size plus the length of the offset word.
   for pos = 0 then (+ pos 1 size 4)
   ;; Get the length of the name of the sequence.
   for size = (aref buffer pos)
   ;; Pull out the name itself.
   for name = (substring buffer (1+ pos) (+ pos 1 size))
   ;; Pull out the offset.
   for offset = (2bit--word-from-bytes source (substring buffer (+ pos 1 size) (+ pos 1 size 4)))
   ;; Collect the offset into the hash.
   do (setf (gethash name index) offset)
   ;; Once we're all done.... return the index.
   finally return index))

(defun 2bit--read-words (source count)
  "Read COUNT 32-bit words from SOURCE."
  (cl-loop
   ;; Rather than load in COUNT words, one at a time, which would be tidy but
   ;; slow because every read requires that a temp buffer is created and
   ;; destroyed, we load up the whole buffer at once and split it up from
   ;; there.
   with buffer = (2bit--read source (* count 4))
   ;; For every word we expect to find in the buffer...
   for n from 1 to count
   ;; Every 4 bytes within the buffer...
   for pos = 0 then (+ pos 4)
   ;; ...extract the value into the list.
   collect (2bit--word-from-bytes source (substring buffer pos (+ pos 4)))))

(defun 2bit--load-block-collection (source)
  "Load a sequence block collection from SOURCE."
  (let ((blocks (make-2bit-block-collection)))
    ;; Get the count of blocks.
    (setf (2bit-block-collection-count blocks) (2bit--read-word source))
    ;; Get the start locations as a list.
    (setf (2bit-block-collection-starts blocks) (2bit--read-words source (2bit-block-collection-count blocks)))
    ;; Get the sizes as a list.
    (setf (2bit-block-collection-sizes blocks) (2bit--read-words source (2bit-block-collection-count blocks)))
    blocks))

(defun 2bit--skip-block-collection (source)
  "Skip past a block collection in SOURCE.

It is assumed that a block collection is at the current position
in source; `2bit-data-pos' is moved past it as a side effect."
  ;; We skip 4 bytes times by the number of blocks, times 2 (once for the
  ;; start locations, once for the sizes).
  (2bit--skip source (* (2bit--read-word source) 4 2)))

(defun 2bit--load-sequence (source sequence offset)
  "Make a sequence reader for SEQUENCE at OFFSET in SOURCE."
  (let ((seq (make-2bit-sequence)))
    ;; Jump to the start of the sequence's data.
    (2bit--goto source offset)
    ;; Remember the source so it can be used later.
    (setf (2bit-sequence-source seq) source)
    ;; Remember the sequence name.
    (setf (2bit-sequence-name seq) sequence)
    ;; Get the size of the DNA in the sequence.
    (setf (2bit-sequence-dna-size seq) (2bit--read-word source))
    ;; Load up the n-block collection for this sequence.
    (setf (2bit-sequence-n-blocks seq) (2bit--load-block-collection source))
    ;; Load up the mask block collection for this sequence. But only bother
    ;; doing it if we're doing masking; otherwise just skip all the data to
    ;; save some time on loading. Note that other bits of code rely on the
    ;; fact that the mask block list will be empty if it's off -- this has
    ;; the effect of turning off mask block handling without having to check
    ;; in all the relevant places.
    (if (2bit-data-masking source)
        (setf (2bit-sequence-mask-blocks seq) (2bit--load-block-collection source))
      (2bit--skip-block-collection source))
    ;; Skip a word.
    (2bit--skip source 4)
    ;; Remember the location at which the actual DNA data starts.
    (setf (2bit-sequence-dna-offset seq) (2bit-data-pos source))
    seq))

;;;###autoload
(defun 2bit-open (file &optional masking)
  "Open FILE as a 2bit file.

This function pulls out the details of the header of the given
file and, if it is a valid 2bit file, returns a `2bit-data'
structure that can be used with other functions.

If MASKING is supplied and is non-NIL mask blocks will be read
and processed too. Note that if MASKING isn't supplied, or is
NIL, the mask block data won't even be loaded to help reduce load
times."
  (if (file-exists-p file)
      (let ((2bit (make-2bit-data)))
        ;; Remember where we're getting the data from.
        (setf (2bit-data-source 2bit) file)
        ;; Start from position 0.
        (2bit--goto 2bit 0)
        ;; Get the signature.
        (setf (2bit-data-signature 2bit) (2bit--read-word 2bit))
        ;; If we're not looking at a valid signature...
        (unless (= (2bit-data-signature 2bit) 2bit-signature)
          ;; ...are we perhaps looking at an other-endian 2bit file?
          (if (= (2bit--word-swap (2bit-data-signature 2bit)) 2bit-signature)
              ;; We are. Remember this.
              (setf (2bit-data-other-endian-p 2bit) t)
            ;; At this point, the signature isn't the valid signature, even
            ;; if we swap to the other endian approach; what we're being
            ;; asked to look at likely isn't really a 2bit file.
            (error "Invalid 2bit signature: %d" (2bit-data-signature 2bit))))
        ;; Load up the file version number. This should always be 0.
        (unless (zerop (setf (2bit-data-version 2bit) (2bit--read-word 2bit)))
          (error "%d is not a valid 2bit file version number" (2bit-data-version 2bit)))
        ;; Now load up the count of sequences in the file.
        (setf (2bit-data-sequence-count 2bit) (2bit--read-word 2bit))
        ;; Remember the masking status.
        (setf (2bit-data-masking 2bit) masking)
        ;; Skip a reserved value.
        (2bit--skip 2bit 4)
        ;; Load up the sequence index.
        (setf (2bit-data-index 2bit) (2bit--read-index 2bit))
        2bit)
    (error "%s does not exist" file)))

(defun 2bit--maybe-open (source)
  "Possibly open SOURCE as a 2bit file.

This is a helper function that, if given a `2bit-data' structure,
simply returns it, otherwise it is assumed it's the name of a
file and a fresh `2bit-data' structure is created for it."
  (if (2bit-data-p source)
      source
    (2bit-open source)))

;;;###autoload
(defun 2bit-sequence-count (file)
  "Get the count of sequences available inside FILE.

FILE can either be the name of a 2bit file, or can be a value
returned from a call to `2bit-open'."
  (2bit-data-sequence-count (2bit--maybe-open file)))

;;;###autoload
(defun 2bit-sequence-names (file)
  "Get a list of all the sequence names available in FILE.

FILE can either be the name of a 2bit file, or can be a value
returned from a call to `2bit-open'."
  (cl-loop for sequence being the hash-keys of (2bit-data-index (2bit--maybe-open file)) collect sequence))

;;;###autoload
(defun 2bit-sequence (file sequence)
  "Get SEQUENCE from the 2bit data held in FILE."
  (let* ((2bit (2bit--maybe-open file))
         (offset (gethash sequence (2bit-data-index 2bit))))
    (if offset
        (2bit--load-sequence 2bit sequence offset)
      (error "Unknown sequence \"%s\"" sequence))))

;;;###autoload
(defun 2bit-bases (sequence start end)
  "Get the bases of SEQUENCE from START to END.

Note that, as is the usual convention, what is returned is
inclusive of the START location, and exclusive of the END
location."
  ;; Start out with some sanity checks.
  (when (>= start end)
    (error "Start location is greater or equal to the end location"))
  (when (< start 0)
    (error "Start location is less than 0"))
  (when (>= start (2bit-sequence-dna-size sequence))
    (error "Start location is beyond the end of the sequence"))
  (when (> end (2bit-sequence-dna-size sequence))
    (error "End location is beyond the end of the sequence"))
  ;; Having got that out of the way, time to get into the meat of pulling
  ;; out the bases. We'll be printing what we find into a temp buffer and
  ;; then will return the content as a string at the end.
  (with-temp-buffer
    (cl-loop
     ;; Figure out the start and end bytes to pull from the 2bit data.
     with start-byte = (+ (2bit-sequence-dna-offset sequence) (floor (/ start 4)))
     with end-byte   = (+ (2bit-sequence-dna-offset sequence) (floor (/ (1- end) 4)))
     ;; Next, figure out the position where we should start.
     with position = (* (- start-byte (2bit-sequence-dna-offset sequence)) 4)
     ;; Pull in a buffer that's big enough to hold all the bytes that
     ;; contain the bases we're interested in.
     with buffer = (progn
                     (2bit--goto (2bit-sequence-source sequence) start-byte)
                     (2bit--read (2bit-sequence-source sequence) (1+ (- end-byte start-byte))))
     ;; Get the n-blocks that overlap the sub-sequence we're being asked to return.
     with n-blocks = (2bit--relevant-blocks start end (2bit-sequence-n-blocks sequence))
     ;; Get the mask-blocks that overlap the sub-sequence we're being asked
     ;; to return. Note that all of the mask-block work here observes the
     ;; masking flag the user will have passed in higher-up by doing nothing
     ;; with it, but instead relying on the fact that `2bit--load-sequence'
     ;; will have skipped loading anything if masking is off.
     with mask-blocks = (2bit--relevant-blocks start end (2bit-sequence-mask-blocks sequence))
     ;; With all that set up, we're finally ready to dive into the bytes and
     ;; pull out the bases for the requested sub-sequence. So, for every
     ;; byte in the buffer...
     for byte across buffer
     do (cl-loop
         ;; ...and for every 2 bits in that byte...
         for shift from 6 downto 0 by 2
         ;; ...while we've not got to the end...
         while (< position end)
         ;; ...if we're interested in this particular base...
         if (>= position start)
         ;; ...collect it
         do (insert
             ;; If the position we're looking at is within an N block...
             (if (cl-loop for block in n-blocks thereis (and (< (1- (car block)) position (cdr block))))
                 ;; ...it's an "N".
                 "N"
               ;; ...otherwise decode the base.
               (let ((base (aref 2bit-bases (logand (ash byte (- shift)) #b11))))
                 ;; If the position lies within a mask block (note that we
                 ;; don't bother checking if the masking flag is set or not,
                 ;; if it was nil there will be no mask blocks loaded so
                 ;; none will match, having the same effect and saving
                 ;; time)...
                 (if (cl-loop for block in mask-blocks thereis (and (< (1- (car block)) position (cdr block))))
                     ;; ...downcase it
                     (downcase base)
                   ;; ...otherwise just use it as-is.
                   base))))
         ;; Move along.
         do (cl-incf position))
     ;; Having got to the end, return the content of the temporary buffer,
     ;; which contains the sequence the caller is after.
     finally return (buffer-string))))

;;;###autoload
(cl-defmacro 2bit-with-file ((handle file &optional masking) &body body)
  "Perform BODY against 2bit file name FILE, using HANDLE as he reader name.

MASKING optionally controls if masking should be handled. The
default is nil."
  (declare (indent 1))
  `(let ((,handle (2bit-open ,file ,masking)))
     ,@body))

;;;###autoload
(cl-defmacro 2bit-with-sequence ((name sequence file) &body body)
  "Perform BODY against SEQUENCE taken from FILE.

NAME will be bound to the sequence data from FILE for the
duration of BODY."
  (declare (indent 1))
  `(let ((,name (2bit-sequence (2bit-open ,file) ,sequence)))
     ,@body))

(defun 2bit--location-prompt ()
  "Helper function for `interactive' functions that prompt for a location."
  (let* ((file (read-file-name "2bit file: "))
         (sequence (completing-read "Sequence: " (2bit-sequence-names file))))
    ;; Here, while we've really simply been asking for the name of a
    ;; sequence, we're going to allow the user to enter a full location in
    ;; the common form of seq:start..end. If it looks like they've done that
    ;; we'll fill out the remaining information from that.
    (save-match-data
      (if (string-match (rx bol (group (+ any)) ":" (group (+ numeric)) (or "-" "..") (group (+ numeric)) eol) sequence)
          (list file (match-string 1 sequence) (string-to-number (match-string 2 sequence)) (string-to-number (match-string 3 sequence)))
        (let ((start (read-number (format "%s; Start: " sequence) 0)))
          (list file sequence start
                (read-number (format "%s; Start: %d; End: " sequence start) (2bit-sequence-dna-size (2bit-sequence file sequence)))))))))

;;;###autoload
(defun 2bit-insert-bases (file sequence start end)
  "Insert bases bounded START and END, from SEQUENCE in FILE.

If the command is invoked with \\[universal-argument] mask blocks
will be taken into account.

When used as an interactive command, if SEQUENCE is either of the
forms:

  seq:start..end
  seq:start-end

SEQUENCE, START and END will be fully-auto-populated from that
format."
  (interactive (2bit--location-prompt))
  (2bit-with-file (data file current-prefix-arg)
    (insert (2bit-bases (2bit-sequence data sequence) start end))))

;;;###autoload
(defun 2bit-insert-fasta (file sequence start end)
  "Insert FASTA format for bases bounded START and END, from SEQUENCE in FILE.

If the command is invoked with \\[universal-argument] mask blocks
will be taken into account.

When used as an interactive command, if SEQUENCE is either of the
forms:

  seq:start..end
  seq:start-end

SEQUENCE, START and END will be fully-auto-populated from that
format."
  (interactive (2bit--location-prompt))
  (2bit-with-file (data file current-prefix-arg)
    (insert (format "> %s; %s:%d-%d\n%s\n" (file-name-base file) sequence start end
                    (replace-regexp-in-string ".\\{80\\}" "\\&\n"  (2bit-bases (2bit-sequence data sequence) start end))))))

(provide '2bit)

;;; 2bit.el ends here
