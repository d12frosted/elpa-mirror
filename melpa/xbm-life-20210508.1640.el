;;; xbm-life.el --- A XBM version of Conway's Game of Life

;; Copyright (C) 2015 Vasilij Schneidermann <mail@vasilij.de>

;; Author: Vasilij Schneidermann <mail@vasilij.de>
;; URL: https://depp.brause.cc/xbm-life
;; Package-Version: 20210508.1640
;; Package-Commit: ec6abb0182068294a379cb49ad5346b1d757457d
;; Version: 0.1.3
;; Package-Requires: ((emacs "24.1"))
;; Keywords: games

;; This file is NOT part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING. If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; A XBM version of Conway's Game of Life.

;;; Code:

(require 'format-spec)

(defgroup xbm-life nil
  "A XBM version of Conway's Game of Life."
  :group 'games
  :prefix "xbm-life-")

(defface xbm-life '((t :inherit default))
  "Used to determine the fore- and background color of the grid.")

(defvar xbm-life-foreground nil
  "Current foreground color of the grid.")
(make-variable-buffer-local 'xbm-life-foreground)

(defvar xbm-life-background nil
  "Current background color of the grid.")
(make-variable-buffer-local 'xbm-life-background)

(defcustom xbm-life-default-grid-size 16
  "Default width of the grid in tiles."
  :type 'integer
  :group 'xbm-life)

(defvar xbm-life-grid-size nil
  "Current width of the grid in tiles.")
(make-variable-buffer-local 'xbm-life-grid-size)

(defcustom xbm-life-default-tile-size 8
  "Default width of each tile in the grid."
  :type 'integer
  :group 'xbm-life)

(defvar xbm-life-tile-size nil
  "Current width of each tile in the grid.")
(make-variable-buffer-local 'xbm-life-tile-size)

(defvar xbm-life-patterns
  '((pulsar . [[0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
               [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
               [0 0 0 0 1 1 1 0 0 0 1 1 1 0 0 0 0]
               [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
               [0 0 1 0 0 0 0 1 0 1 0 0 0 0 1 0 0]
               [0 0 1 0 0 0 0 1 0 1 0 0 0 0 1 0 0]
               [0 0 1 0 0 0 0 1 0 1 0 0 0 0 1 0 0]
               [0 0 0 0 1 1 1 0 0 0 1 1 1 0 0 0 0]
               [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
               [0 0 0 0 1 1 1 0 0 0 1 1 1 0 0 0 0]
               [0 0 1 0 0 0 0 1 0 1 0 0 0 0 1 0 0]
               [0 0 1 0 0 0 0 1 0 1 0 0 0 0 1 0 0]
               [0 0 1 0 0 0 0 1 0 1 0 0 0 0 1 0 0]
               [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
               [0 0 0 0 1 1 1 0 0 0 1 1 1 0 0 0 0]
               [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
               [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]])

    (figure-eight . [[0 0 0 0 0 0 0 0 0 0 0 0]
                     [0 0 0 0 0 0 0 0 0 0 0 0]
                     [0 0 0 0 0 0 0 0 0 0 0 0]
                     [0 0 0 1 1 1 0 0 0 0 0 0]
                     [0 0 0 1 1 1 0 0 0 0 0 0]
                     [0 0 0 1 1 1 0 0 0 0 0 0]
                     [0 0 0 0 0 0 1 1 1 0 0 0]
                     [0 0 0 0 0 0 1 1 1 0 0 0]
                     [0 0 0 0 0 0 1 1 1 0 0 0]
                     [0 0 0 0 0 0 0 0 0 0 0 0]
                     [0 0 0 0 0 0 0 0 0 0 0 0]
                     [0 0 0 0 0 0 0 0 0 0 0 0]])

    (lightweight-spaceship . [[0 0 0 0 0 0 0 0 0 0]
                              [0 0 0 0 0 0 0 0 0 0]
                              [0 0 0 0 0 0 0 0 0 0]
                              [1 0 0 1 0 0 0 0 0 0]
                              [0 0 0 0 1 0 0 0 0 0]
                              [1 0 0 0 1 0 0 0 0 0]
                              [0 1 1 1 1 0 0 0 0 0]
                              [0 0 0 0 0 0 0 0 0 0]
                              [0 0 0 0 0 0 0 0 0 0]
                              [0 0 0 0 0 0 0 0 0 0]])

    (die-hard . [[0 0 0 0 0 0 0 0 0 0]
                 [0 0 0 0 0 0 0 0 0 0]
                 [0 0 0 0 0 0 0 0 0 0]
                 [0 0 0 0 0 0 0 0 0 0]
                 [0 0 0 0 0 0 0 1 0 0]
                 [0 1 1 0 0 0 0 0 0 0]
                 [0 0 1 0 0 0 1 1 1 0]
                 [0 0 0 0 0 0 0 0 0 0]
                 [0 0 0 0 0 0 0 0 0 0]
                 [0 0 0 0 0 0 0 0 0 0]])

    (glider . [[0 1 0 0 0 0 0 0]
               [0 0 1 0 0 0 0 0]
               [1 1 1 0 0 0 0 0]
               [0 0 0 0 0 0 0 0]
               [0 0 0 0 0 0 0 0]
               [0 0 0 0 0 0 0 0]
               [0 0 0 0 0 0 0 0]
               [0 0 0 0 0 0 0 0]])

    (clock . [[0 0 0 0 0 0]
              [0 0 0 1 0 0]
              [0 1 0 1 0 0]
              [0 0 1 0 1 0]
              [0 0 1 0 0 0]
              [0 0 0 0 0 0]])

    (blinker . [[0 0 0 0 0]
                [0 0 0 0 0]
                [0 1 1 1 0]
                [0 0 0 0 0]
                [0 0 0 0 0]])

    (r-pentomino . [[0 0 0 0 0 0]
                    [0 0 0 1 1 0]
                    [0 0 1 1 0 0]
                    [0 0 0 1 0 0]
                    [0 0 0 0 0 0]
                    [0 0 0 0 0 0]])

    (acorn . [[0 0 0 0 0 0 0 0 0]
              [0 0 1 0 0 0 0 0 0]
              [0 0 0 0 1 0 0 0 0]
              [0 1 1 0 0 1 1 1 0]
              [0 0 0 0 0 0 0 0 0]
              [0 0 0 0 0 0 0 0 0]
              [0 0 0 0 0 0 0 0 0]
              [0 0 0 0 0 0 0 0 0]
              [0 0 0 0 0 0 0 0 0]])

    (block-laying-switch-engine-2 . [[0 0 0 0 0 0 0]
                                     [0 1 1 1 0 1 0]
                                     [0 1 0 0 0 0 0]
                                     [0 0 0 0 1 1 0]
                                     [0 0 1 1 0 1 0]
                                     [0 1 0 1 0 1 0]
                                     [0 0 0 0 0 0 0]])
    (toad . [[0 0 0 0 0 0]
             [0 0 0 0 0 0]
             [0 0 1 1 1 0]
             [0 1 1 1 0 0]
             [0 0 0 0 0 0]
             [0 0 0 0 0 0]])

    (beacon . [[0 0 0 0 0 0]
               [0 1 1 0 0 0]
               [0 1 1 0 0 0]
               [0 0 0 1 1 0]
               [0 0 0 1 1 0]
               [0 0 0 0 0 0]])

    (pentadecathlon . [[0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                       [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                       [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                       [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                       [0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0]
                       [0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0]
                       [0 0 0 0 1 0 1 0 0 0 0 0 0 0 0 0 0 0]
                       [0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0]
                       [0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0]
                       [0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0]
                       [0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0]
                       [0 0 0 0 1 0 1 0 0 0 0 0 0 0 0 0 0 0]
                       [0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0]
                       [0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0]
                       [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                       [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                       [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                       [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]])

    (block-laying-switch-engine-1 . [[0 0 0 0 0 0 0 0 0 0]
                                     [0 0 0 0 0 0 0 1 1 0]
                                     [0 0 0 0 0 1 0 1 0 0]
                                     [0 0 0 0 0 1 0 1 0 0]
                                     [0 0 0 0 0 1 0 0 0 0]
                                     [0 0 0 1 0 0 0 0 0 0]
                                     [0 1 0 1 0 0 0 0 0 0]
                                     [0 0 0 0 0 0 0 0 0 0]
                                     [0 0 0 0 0 0 0 0 0 0]
                                     [0 0 0 0 0 0 0 0 0 0]])

    (gosper-glider-gun . [[0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 1 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 1 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0]
                          [0 1 1 0 0 0 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 1 1 0 0 0 0 0 0 0 0 1 0 0 0 1 0 1 1 0 0 0 0 1 0 1 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
                          [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]]))
  "Alist of pattern names and patterns.
The pattern name is a symbol, the pattern is a vector of vectors
containing ones and zeroes as values.")

(defcustom xbm-life-default-grid 'pulsar
  "Default grid layout.
Can be a symbol with the name of an existing pattern, when nil a
randomized grid is used, when t a random pattern is used."
  :type `(choice (const :tag "Random pattern" t)
                 (const :tag "Random grid" nil)
                 (choice ,@(mapcar (lambda (item) (list 'const (car item)))
                                   xbm-life-patterns)))
  :group 'xbm-life)

(defvar xbm-life-grid nil
  "Current grid.")
(make-variable-buffer-local 'xbm-life-grid)

(defcustom xbm-life-default-toroidal-grid nil
  "When non-nil, the grid is toroidal.
In other words, operations wrap around both sides."
  :type 'boolean
  :group 'xbm-life)

(defvar xbm-life-toroidal-grid nil
  "Current toroidal grid state.")
(make-variable-buffer-local 'xbm-life-toroidal-grid)

(defun xbm-life-render-image (grid)
  "Turn GRID into a XBM image."
  (let* ((size (* xbm-life-grid-size xbm-life-tile-size))
         (xbm (make-vector size nil)))
    (dotimes (row size)
      (let ((line (make-bool-vector size nil)))
        (dotimes (col size)
          ;; iterate over the upscaled xbm, do integer division to
          ;; obtain the coordinates to look up the original values in
          (aset line col (= 1 (xbm-life-peek grid (/ row xbm-life-tile-size)
                                             (/ col xbm-life-tile-size)))))
        (aset xbm row line)))
    xbm))

(defun xbm-life-peek (grid row col)
  "Return value for GRID at ROW and COL."
  (aref (aref grid row) col))

(defun xbm-life-poke (grid row col value)
  "Set value for GRID at ROW and COL to VALUE."
  (aset (aref grid row) col value))

(defun xbm-life-out-of-bounds (row col)
  "Check whether ROW and COL are out of bounds."
  (or (< row 0) (>= row xbm-life-grid-size)
      (< col 0) (>= col xbm-life-grid-size)))

(defun xbm-life-neighbors (grid row col)
  "Return number of neighbors on GRID at ROW and COL."
  (let ((neighbors 0)
        (offsets '((-1 . -1) (-1 . 0) (-1 . 1)
                   ( 0 . -1)          ( 0 . 1)
                   ( 1 . -1) ( 1 . 0) ( 1 . 1))))
    (dolist (xy offsets)
      (let* ((x (car xy))
             (y (cdr xy))
             (row+x (if xbm-life-toroidal-grid
                        (mod (+ row x) xbm-life-grid-size)
                      (+ row x)))
             (col+y (if xbm-life-toroidal-grid
                        (mod (+ col y) xbm-life-grid-size)
                      (+ col y))))
        (when (and (or xbm-life-toroidal-grid
                       (not (xbm-life-out-of-bounds row+x col+y)))
                   (= (xbm-life-peek grid row+x col+y) 1))
          (setq neighbors (1+ neighbors)))))
    neighbors))

(defun xbm-life-create-empty-grid (&optional size)
  "Return empty grid.
When supplying SIZE, make it of that size instead
`xbm-life-size'."
  (let ((size (or size xbm-life-grid-size))
        grid)
    (dotimes (_ size)
      (setq grid (cons (make-vector size 0) grid)))
    (vconcat grid)))

(defun xbm-life-create-random-grid (&optional size)
  "Return random grid.
When supplying SIZE, make it of that size instead
`xbm-life-size'."
  (let ((size (or size xbm-life-grid-size))
        (grid (xbm-life-create-empty-grid size)))
    (dotimes (row size)
      (dotimes (col size)
        (xbm-life-poke grid row col (random 2))))
    grid))

(defun xbm-life-randomize-grid ()
  "Randomize current grid."
  (interactive)
  (setq xbm-life-grid (xbm-life-create-random-grid))
  (xbm-life-redraw-grid))

(defun xbm-life-random-pattern ()
  "Return a random item from `xbm-life-patterns'."
  (nth (random (length xbm-life-patterns)) xbm-life-patterns))

(defun xbm-life-init-grid ()
  "Return a grid according to `xbm-life-default-grid'."
  (cond
   ((assoc xbm-life-default-grid xbm-life-patterns)
    (cdr (assoc xbm-life-default-grid xbm-life-patterns)))
   ((not xbm-life-default-grid)
    (xbm-life-create-random-grid))
   (t (cdr (xbm-life-random-pattern)))))

(defun xbm-life-load-pattern (pattern)
  "Load PATTERN into the current grid."
  (interactive (list (intern (completing-read "Pattern: " xbm-life-patterns
                                              nil t))))
  (let* ((grid (cdr (assoc pattern xbm-life-patterns)))
         (size (length grid)))
    (setq xbm-life-grid (cdr (assoc pattern xbm-life-patterns))
          xbm-life-grid-size size))
  (xbm-life-redraw-grid))

(defun xbm-life-load-random-pattern ()
  "Load random pattern into the current grid."
  (interactive)
  (xbm-life-load-pattern (car (xbm-life-random-pattern))))

(defun xbm-life-next-cell-state (grid row col)
  "Calculate the next cell state on GRID using ROW and COL."
  (let ((state (xbm-life-peek grid row col))
        (neighbors (xbm-life-neighbors grid row col)))
    (if (= state 1)
        (if (or (= neighbors 2) (= neighbors 3))
            1 0)
      (if (= neighbors 3)
          1 0))))

(defun xbm-life-next-generation (grid)
  "Create the next generation based on GRID."
  (let ((new (xbm-life-create-empty-grid)))
    (dotimes (row xbm-life-grid-size)
      (dotimes (col xbm-life-grid-size)
        (xbm-life-poke new row col
                       (xbm-life-next-cell-state grid row col))))
    new))

(defvar xbm-life-image-map (make-sparse-keymap))

(defun xbm-life-redraw-grid ()
  "Redraw grid on game buffer."
  (interactive)
  (setq buffer-read-only nil)
  (erase-buffer)
  (insert
   (propertize " "
               'display
               (create-image (xbm-life-render-image xbm-life-grid) 'xbm t
                             :width (* xbm-life-grid-size xbm-life-tile-size)
                             :height (* xbm-life-grid-size xbm-life-tile-size)
                             :foreground xbm-life-foreground
                             :background xbm-life-background)
               'keymap xbm-life-image-map
               'point-entered (lambda (_old _new) (goto-char (point-max)))))
  (insert "\n")
  (deactivate-mark)
  (setq buffer-read-only t))

(defun xbm-life-windows ()
  "Return a list of windows displaying and playing the demo."
  (let ((all-windows (window-list-1))
        windows)
    (dolist (window all-windows)
      (let ((buffer (window-buffer window)))
        (when (and (eq (buffer-local-value 'major-mode buffer) 'xbm-life-mode)
                   (buffer-local-value 'xbm-life-playing buffer))
          (setq windows (cons window windows)))))
    (nreverse windows)))

(defun xbm-life-call-on-windows (thunk)
  "Call THUNK on every window with a `xbm-life' buffer."
  (dolist (window (xbm-life-windows))
    (with-selected-window window
      (funcall thunk))))

(defun xbm-life-advance-generation ()
  "Advance the current generation and redraw the grid."
  (interactive)
  (xbm-life-call-on-windows
   (lambda ()
      (setq xbm-life-grid (xbm-life-next-generation xbm-life-grid))
      (xbm-life-redraw-grid)
      (xbm-life-stats-update))))

(defvar xbm-life-bitmap
  "#define glider_width 8
#define glider_height 16
static unsigned char glider_bits[] = {
0x18, 0x18, 0x00, 0xc0, 0xc0, 0x00, 0xdb, 0xdb,
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };"
  "XBM data for the mode icon.")

(defvar xbm-life-icon
  (propertize " " 'display `(image :type xbm :data ,xbm-life-bitmap
                                   :foreground ,(face-foreground 'mode-line)
                                   :background ,(face-background 'mode-line)))
  "XBM mode icon.")

(define-derived-mode xbm-life-mode special-mode xbm-life-icon
  "A XBM demonstration."
  (xbm-life-reset))

(defvar xbm-life-timer nil
  "Global timer controlling every running demo.")

(defun xbm-life-timer-adjust (delay)
  "Set the timer to DELAY."
  (setf (timer--repeat-delay xbm-life-timer) delay))

(defcustom xbm-life-default-delay 1.0
  "Amount of time passing between updates.
It's better to not go too low with it, especially if you plan
using Emacs along to it.  0.1s seem to work well enough for that
purpose.  If you use the demo only, you can go even lower down to
values like 0.01s."
  :type 'float
  :group 'xbm-life)

(defvar xbm-life-delay xbm-life-default-delay
  "Delay of `xbm-life-timer' in seconds.")

(defun xbm-life-reset ()
  "Initialize demo."
  (interactive)
  (buffer-disable-undo)
  (setq xbm-life-foreground (face-foreground 'xbm-life nil t)
        xbm-life-background (face-background 'xbm-life nil t)
        xbm-life-grid (xbm-life-create-empty-grid xbm-life-default-grid-size)
        xbm-life-grid-size (length xbm-life-grid)
        xbm-life-tile-size xbm-life-default-tile-size
        xbm-life-toroidal-grid xbm-life-default-toroidal-grid
        xbm-life-delay xbm-life-default-delay)
  (when xbm-life-timer
    (xbm-life-timer-adjust xbm-life-delay)
    (xbm-life-pause))
  (xbm-life-redraw-grid))

(defvar xbm-life-playing nil
  "Non-nil when the demo is running.")
(make-variable-buffer-local 'xbm-life-playing)

(defun xbm-life-play ()
  "Run demo."
  (unless xbm-life-timer
    (setq xbm-life-timer
          (run-with-timer xbm-life-delay xbm-life-delay
                          'xbm-life-advance-generation)))
  (unless xbm-life-playing
    (setq xbm-life-playing t)))

(defun xbm-life-pause ()
  "Pause demo."
  (when xbm-life-playing
    (setq xbm-life-playing nil)))

(defun xbm-life-play-or-pause ()
  "Run or pause demo."
  (interactive)
  (if xbm-life-playing
      (xbm-life-pause)
    (xbm-life-play))
  (xbm-life-call-on-windows 'xbm-life-stats-update))

(defun xbm-life-single-step ()
  "Advance a single generation when not playing."
  (interactive)
  (unless xbm-life-playing
    (xbm-life-advance-generation)))

(defcustom xbm-life-delay-minimum 0.1
  "Minimum delay that can be set interactively."
  :type 'float
  :group 'xbm-life)

(defcustom xbm-life-delay-step 0.1
  "Delay step size for interactive speed commands."
  :type 'float
  :group 'xbm-life)

(defun xbm-life-slow-down (arg)
  "Slow down demo by ARG."
  (interactive "p")
  (let ((delay (max xbm-life-delay-minimum
                    (+ xbm-life-delay (* arg xbm-life-delay-step)))))
    (xbm-life-timer-adjust delay)
    (setq xbm-life-delay delay))
  (xbm-life-call-on-windows 'xbm-life-stats-update))

(defun xbm-life-speed-up (arg)
  "Speed up demo by ARG."
  (interactive "p")
  (xbm-life-slow-down (- arg)))

(defcustom xbm-life-tile-minimum 1
  "Minimum tile size that can be set interactively."
  :type 'integer
  :group 'xbm-life)

(defcustom xbm-life-tile-step 1
  "Tile step size for interactive tile size commands."
  :type 'integer
  :group 'xbm-life)

(defun xbm-life-smaller-tiles (arg)
  "Make tile size smaller by ARG."
  (interactive "p")
  (let ((size (max xbm-life-tile-minimum
                   (+ xbm-life-tile-size (* arg xbm-life-tile-step)))))
    (setq xbm-life-tile-size size)
    (xbm-life-redraw-grid))
  (xbm-life-stats-update))

(defun xbm-life-larger-tiles (arg)
  "Make tile size larger by ARG."
  (interactive "p")
  (xbm-life-smaller-tiles (- arg)))

(defun xbm-life-copy-grid (grid size)
  "Copy GRID into a new grid dimensioned SIZE."
  (let ((new (xbm-life-create-empty-grid size))
        (size (min size (length grid))))
    (dotimes (row size)
      (dotimes (col size)
        (xbm-life-poke new row col
                       (xbm-life-peek grid row col))))
    new))

(defcustom xbm-life-grid-minimum 2
  "Minimum grid size that can be set interactively."
  :type 'integer
  :group 'xbm-life)

(defcustom xbm-life-grid-step 1
  "Grid step size for interactive grid size commands."
  :type 'integer
  :group 'xbm-life)

(defun xbm-life-smaller-grid (arg)
  "Make grid size smaller by ARG."
  (interactive "p")
  (let ((size (max xbm-life-grid-minimum
                   (+ xbm-life-grid-size (* arg xbm-life-grid-step)))))
    (setq xbm-life-grid (xbm-life-copy-grid xbm-life-grid size)
          xbm-life-grid-size size)
    (xbm-life-redraw-grid))
  (xbm-life-stats-update))

(defun xbm-life-larger-grid (arg)
  "Make grid larger by ARG."
  (interactive "p")
  (xbm-life-smaller-grid (- arg)))

(defun xbm-life-toggle-toroidal-grid ()
  "Toggle toroidal grid state."
  (interactive)
  (setq xbm-life-toroidal-grid (not xbm-life-toroidal-grid))
  (xbm-life-stats-update))

(defun xbm-life-invert-colors ()
  "Invert currently used fore- and background color."
  (interactive)
  (let ((foreground xbm-life-background)
        (background xbm-life-foreground))
    (setq xbm-life-foreground foreground
          xbm-life-background background)
    (xbm-life-redraw-grid)))

(defun xbm-life-toggle-cell (row col)
  "Toggle cell at ROW and COL.
A dead cell turns alive and vice versa."
  (let ((grid xbm-life-grid))
    (xbm-life-poke grid row col
                   (abs (- (xbm-life-peek grid row col) 1)))
    (setq xbm-life-grid grid)
    (xbm-life-redraw-grid)))

(defun xbm-life-mouse-handler (event)
  "Check whether EVENT happens on the grid.
If yes, toggle the clicked cell."
  (interactive "e")
  (let* ((x-y (posn-x-y (event-start event)))
         (x (car x-y))
         (y (cdr x-y))
         (row (/ y xbm-life-tile-size))
         (col (/ x xbm-life-tile-size)))
    (when (not (xbm-life-out-of-bounds row col))
      (xbm-life-toggle-cell row col))))

(define-key xbm-life-mode-map (kbd "l") 'xbm-life-load-pattern)
(define-key xbm-life-mode-map (kbd "L") 'xbm-life-load-random-pattern)
(define-key xbm-life-mode-map (kbd "r") 'xbm-life-randomize-grid)
(define-key xbm-life-mode-map (kbd "g") 'xbm-life-reset)
(define-key xbm-life-mode-map (kbd "p") 'xbm-life-play-or-pause)
(define-key xbm-life-mode-map (kbd "SPC") 'xbm-life-play-or-pause)
(define-key xbm-life-mode-map (kbd ".") 'xbm-life-single-step)
(define-key xbm-life-mode-map (kbd "+") 'xbm-life-speed-up)
(define-key xbm-life-mode-map (kbd "-") 'xbm-life-slow-down)
(define-key xbm-life-mode-map (kbd "M-+") 'xbm-life-smaller-tiles)
(define-key xbm-life-mode-map (kbd "M--") 'xbm-life-larger-tiles)
(define-key xbm-life-mode-map (kbd "C-+") 'xbm-life-smaller-grid)
(define-key xbm-life-mode-map (kbd "C--") 'xbm-life-larger-grid)
(define-key xbm-life-mode-map (kbd "t") 'xbm-life-toggle-toroidal-grid)
(define-key xbm-life-mode-map (kbd "i") 'xbm-life-invert-colors)
(define-key xbm-life-image-map (kbd "<mouse-1>") 'xbm-life-mouse-handler)

(defcustom xbm-life-display-stats t
  "When non-nil, display demo stats when starting a demo."
  :type 'boolean
  :group 'xbm-life)

(defvar xbm-life-stats-lighter ""
  "Current demo stats.
See `xbm-life-stats-lighter-format' for an explanation of the
displayed stats.")
(make-variable-buffer-local 'xbm-life-stats-lighter)

(defvar xbm-life-stats-lighter-format " D: %d, G: %g, T: %t, R: %r, S: %s"
  "Format string for demo stats minor mode.
Valid format specifiers are:

%d: Current delay as floating point number with one digit of
 precision.

%g: Current grid size.

%t: Current tile size.

%r: Unicode checkmark or ballot glyph, depending on whether the grid is
 a torus or not.

%s: Unicode play or pause glyph, depending on whether the demo is
 playing or paused.")

(define-minor-mode xbm-life-stats-mode
  "Toggles stats display for `xbm-life'."
  :lighter xbm-life-stats-lighter)

(defun xbm-life-stats-update ()
  "Update the current demo stats in the mode line."
  (setq xbm-life-stats-lighter
        (format-spec xbm-life-stats-lighter-format
                     (format-spec-make ?d (format "%.1f" xbm-life-delay)
                                       ?g xbm-life-grid-size
                                       ?t xbm-life-tile-size
                                       ?r (if xbm-life-toroidal-grid "✔" "✘")
                                       ?s (if xbm-life-playing "▶" "⏸"))))
  (force-mode-line-update t))

;;;###autoload
(defun xbm-life (arg)
  "Launch a XBM demo of Conway's Game of Life.
Use ARG as prefix argument to create a buffer with a different
name."
  (interactive "P")
  (let ((buffer-name (if (consp arg)
                         (read-string "Buffer name: " nil nil "*xbm life*")
                       "*xbm life*")))
    (with-current-buffer (get-buffer-create buffer-name)
      (xbm-life-mode)
      (when xbm-life-display-stats
        (xbm-life-stats-mode)
        (xbm-life-stats-update))
      (setq xbm-life-grid (xbm-life-init-grid))
      (xbm-life-redraw-grid)
      (xbm-life-play))
    (display-buffer buffer-name))
  (xbm-life-play))

(provide 'xbm-life)

;;; xbm-life.el ends here
