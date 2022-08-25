;;; mxf-view.el --- Simple MXF viewer -*- lexical-binding: t; -*-

;; Copyright (C) 2018 Tomotaka SUWA

;; Author: Tomotaka SUWA <tomotaka.suwa@gmail.com>
;; Package: mxf-view
;; Package-Requires: ((emacs "25"))
;; Package-Version: 20180501.740
;; Package-Commit: c4825f35fad81c4624a2fcaea95cc605addf5cbc
;; Version: 0.2
;; Keywords: data multimedia
;; URL: https://github.com/t-suwa/mxf-view

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
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

;; An MXF(Material eXchange Format) file viewer.

;; (require 'mxf-view)

;;; Code:

(require 'cl-lib)
(require 'seq)
(require 'subr-x)
(require 'hexl)

;; ============================================================
;; custom vars
;; ============================================================

(defgroup mxf-view nil
  "MXF file viewer."
  :version "0.2"
  :group 'utility)

(defcustom mxf-view-leaf-icon "   "
  "Icon for leaf item."
  :type 'string
  :group 'mxf-view)

(defcustom mxf-view-open-icon "[-]"
  "Icon for open status."
  :type 'string
  :group 'mxf-view)

(defcustom mxf-view-close-icon "[+]"
  "Icon for close status."
  :type 'string
  :group 'mxf-view)

(defface mxf-view-node
  '((t :inherit font-lock-keyword-face))
  "Face for node."
  :group 'mxf-view)

(defface mxf-view-leaf
  '((t :inherit default))
  "Face for leaf."
  :group 'mxf-view)

(defface mxf-view-property
  '((t :inherit font-lock-comment-face))
  "Face for property."
  :group 'mxf-view)

(defface mxf-view-string
  '((t :inherit font-lock-string-face))
  "Face for string."
  :group 'mxf-view)

(defface mxf-view-value
  '((t :inherit font-lock-constant-face))
  "Face for constant."
  :group 'mxf-view)

(defface mxf-view-warning
  '((t :inherit font-lock-warning-face))
  "Face for warning."
  :group 'mxf-view)

;; ============================================================
;; font lock support
;; ============================================================

(defmacro mxf-view-define-font-lock (face)
  "Define wrapper to set font-lock-face to FACE."
  (let ((name (intern (format "%s-str" face))))
    `(defun ,name (str)
       (propertize str 'font-lock-face ',face))))

(mxf-view-define-font-lock mxf-view-node)
(mxf-view-define-font-lock mxf-view-leaf)
(mxf-view-define-font-lock mxf-view-property)
(mxf-view-define-font-lock mxf-view-string)
(mxf-view-define-font-lock mxf-view-value)
(mxf-view-define-font-lock mxf-view-warning)

;; ============================================================
;; MXF-View mode
;; ============================================================

(defvar mxf-view-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "n") 'mxf-view-next-widget)
    (define-key map (kbd "j") 'mxf-view-next-widget)
    (define-key map (kbd "p") 'mxf-view-previous-widget)
    (define-key map (kbd "k") 'mxf-view-previous-widget)
    (define-key map (kbd "u") 'mxf-view-goto-parent)
    (define-key map (kbd "h") 'mxf-view-goto-parent)
    (define-key map (kbd "M-n") 'mxf-view-next-sibling-widget)
    (define-key map (kbd "M-p") 'mxf-view-previous-sibling-widget)
    (define-key map (kbd "c") 'mxf-view-toggle-widget)
    (define-key map (kbd "TAB") 'mxf-view-toggle-widget)
    (define-key map (kbd "RET") 'mxf-view-toggle-widget)
    (define-key map (kbd "/") 'mxf-view-toggle-all-widget)
    (define-key map (kbd "*") 'mxf-view-toggle-all-widget)
    (define-key map (kbd "e") 'mxf-view-extract-essence)
    (define-key map (kbd "x") 'mxf-view-hexlify-essence)
    (define-key map (kbd "z") 'mxf-view-suspend)
    (define-key map (kbd "q") 'mxf-view-close)
    map))

;;;###autoload
(define-derived-mode mxf-view-mode special-mode "MXF-View"
  (setq imenu-create-index-function 'mxf-view-imenu-index)
  (setq imenu-default-goto-function 'mxf-view-imenu-goto)
  (setq revert-buffer-function 'mxf-view-revert-buffer)
  (buffer-disable-undo)
  (mxf-view-setup (mxf-view-decode-buffer)))

;; ============================================================
;; buffer-local vars
;; ============================================================

(defvar mxf-view--pindex-length 0
  "We can determine partition index length only at decode timing.")

(defvar mxf-view--index-slice-count 0
  "We can determine slice count only at decode timing.")

(defvar mxf-view--index-pos-table-count 0
  "We can determine pos table count only at decode timing.")

(defvar mxf-view--local-tags-plist nil
  "Plist of (tag1 ul1 tag2 ul2 ...) made from local tags.")

(defvar mxf-view--data nil
  "Contain parsed MXF data.")

;; ============================================================
;; constants
;; ============================================================

(defconst mxf-view-fill-spec
  '((:klv-fill
     "060e2b34010101020301021001000000")
    (:klv-legacy-fill
     "060e2b34010101010301021001000000")))

(defconst mxf-view-pindex-spec
  '((:body-sid u32)
    (:byte-offset u64)))

(defconst mxf-view-random-index-pack-spec
  '(:random-index-pack
    "060e2b34020501010d01020101110100"
    (:partition-index mxf-view-pindex-spec until mxf-view--pindex-length)
    (:rip-len u32)))

(defconst mxf-view-partition-pack-spec
  '(:partition-pack
    "060e2b34020501010d01020101......"
    (:major-version u16)
    (:minor-version u16)
    (:kag-size u32)
    (:this-partition u64)
    (:previous-partition u64)
    (:footer-partition u64)
    (:header-byte-count u64)
    (:index-byte-count u64)
    (:index-sid u32)
    (:body-offset u64)
    (:body-sid u32)
    (:operational-pattern ul)
    (:essence-containers batch ul)))

(defconst mxf-view-local-tag-spec
  '((:tag u16)
    (:ul ul)))

(defconst mxf-view-primer-pack-spec
  '(:primer-pack
    "060e2b34020501010d01020101050100"
    (:local-tags batch mxf-view-local-tag-spec)))

;; TODO: provide meta data for local tags

;; ============================================================
;; header metadata
;; ============================================================

(defconst mxf-view-interchange-set-spec
  '((#x0102 :generation-uid uuid)
    (#x3c0a :instance-uid uuid)))

(defconst mxf-view-version-spec
  '((:major u8)
    (:minor u8)))

(defconst mxf-view-preface-set-spec
  `(:preface
    "060e2b34025301010d01010101012f00"
    ,@mxf-view-interchange-set-spec
    (#x3b01 :byte-order u16)
    (#x3b02 :file-last-modified ts)
    (#x3b03 :content-storage ref)
    (#x3b04 :dictionary ref)
    (#x3b05 :format-version mxf-view-version-spec)
    (#x3b06 :identifications batch ref)
    (#x3b07 :object-model-version u32)
    (#x3b08 :primery-package ref)
    (#x3b09 :operational-pattern ul)
    (#x3b0a :essence-containers batch ul)
    (#x3b0b :dm-schemes batch ul)))

(defconst mxf-view-product-version-spec
  '((:major u16)
    (:minor u16)
    (:tertiary u16)
    (:patch-level u16)
    (:build-type u8)))

(defconst mxf-view-identifications-set-spec
  `(:identifications
    "060e2b34025301010d01010101013000"
    ,@mxf-view-interchange-set-spec
    (#x3c01 :company-name utf16)
    (#x3c02 :product-name utf16)
    (#x3c03 :product-version mxf-view-product-version-spec)
    (#x3c04 :product-version-string utf16)
    (#x3c05 :product-uid uuid)
    (#x3c06 :modification-date ts)
    (#x3c07 :toolkit-version mxf-view-product-version-spec)
    (#x3c08 :product-platform utf16)
    (#x3c09 :this-generation-uid uuid)))

(defconst mxf-view-content-storage-set-spec
  `(:content-storage
    "060e2b34025301010d01010101011800"
    ,@mxf-view-interchange-set-spec
    (#x1901 :packages batch ref)
    (#x1902 :essence-container-data batch ref)))

(defconst mxf-view-essence-container-data-set-spec
  `(:essence-container-data
    "060e2b34025301010d01010101012300"
    ,@mxf-view-interchange-set-spec
    (#x2701 :linked-package-uid umid)
    (#x3f06 :index-sid u32)
    (#x3f07 :body-sid u32)))

(defconst mxf-view-generic-package-set-spec
  `(,@mxf-view-interchange-set-spec
    (#x4401 :package-uid umid)
    (#x4402 :name utf16)
    (#x4403 :tracks batch ref)
    (#x4404 :package-modified-date ts)
    (#x4405 :package-creation-date ts)))

(defconst mxf-view-material-package-set-spec
  `(:material-package
    "060e2b34025301010d01010101013600"
    ,@mxf-view-generic-package-set-spec
    (#x1101 :source-package-id umid)))

(defconst mxf-view-source-package-set-spec
  `(:source-package
    "060e2b34025301010d01010101013700"
    ,@mxf-view-generic-package-set-spec
    (#x4701 :descriptor ref)))

(defconst mxf-view-network-locator-set-spec
  `(:network-locator
    "060e2b34025301010d01010101013200"
    ,@mxf-view-interchange-set-spec
    (#x4001 :url-string utf16)))

(defconst mxf-view-text-locator-set-spec
  `(:text-locator
    "060e2b34025301010d01010101013300"
    ,@mxf-view-interchange-set-spec
    (#x4101 :locator-name utf16)))

(defconst mxf-view-generic-descriptor-set-spec
  `(,@mxf-view-interchange-set-spec))

(defconst mxf-view-file-descriptor-set-spec
  `(:file-descriptor
    "060e2b34025301010d01010101012500"
    ,@mxf-view-generic-descriptor-set-spec
    (#x3001 :sample-rate rat)
    (#x3002 :container-duration u64)
    (#x3004 :essence-container ul)
    (#x3005 :codec ul)
    (#x3006 :linked-track-id u32)
    (#x3006 :locators batch ref)))

(defconst mxf-view-multiple-descriptor-set-spec
  `(:multiple-descriptor
    "060e2b34025301010d01010101014400"
    ,@mxf-view-file-descriptor-set-spec
    (#x3f01 :sub-descriptor-uids batch ref)))

(defconst mxf-view-color-primary-spec
  '((:x u16)
    (:y u16)))

(defconst mxf-view-generic-picture-essence-descriptor-set-spec
  `(:generic-picture-essence-descriptor
    "060e2b34025301010d01010101012700"
    ,@mxf-view-file-descriptor-set-spec
    (#x3201 :picture-essence-coding ul)
    (#x3202 :stored-height u32)
    (#x3203 :stored-width u32)
    (#x3204 :sampled-height u32)
    (#x3205 :sampled-width u32)
    (#x3206 :sampled-x-offset u32)
    (#x3207 :sampled-y-offset u32)
    (#x3208 :display-height u32)
    (#x3209 :display-width u32)
    (#x320a :display-x-offset u32)
    (#x320b :display-y-offset u32)
    (#x320c :frame-layout u8)
    (#x320d :video-line-map batch u32)
    (#x320e :aspect-ratio rat)
    (#x320f :alpha-transparency u8)
    (#x3210 :capture-gamma ul)
    (#x3211 :image-align-offset u32)
    (#x3212 :field-dominance u8)
    (#x3213 :image-start-offset u32)
    (#x3214 :image-end-offset u32)
    (#x3215 :signal-standard u8)
    (#x3216 :stored-f2-offset u32)
    (#x3217 :display-f2-offset u32)
    (#x3218 :active-format-descriptor u8)
    (#x3219 :color-primaries mxf-view-color-primary-spec)
    (#x321a :coding-equations ul)))

(defconst mxf-view-cdci-picture-essence-descriptor-set-spec
  `(:cdci-picture-essence-descriptor
    "060e2b34025301010d01010101012800"
    ,@mxf-view-generic-picture-essence-descriptor-set-spec
    (#x3301 :component-depth u32)
    (#x3302 :horizontal-subsampling u32)
    (#x3303 :color-sitting u8)
    (#x3304 :black-ref-level u32)
    (#x3305 :white-ref-level u32)
    (#x3306 :color-range u32)
    (#x3307 :padding-bits u16)
    (#x3308 :vertical-subsampling u32)
    (#x3309 :alpha-sample-depth u32)
    (#x330b :reversed-byte-order bool)))

(defconst mxf-view-generic-sound-essence-descriptor-set-spec
  `(:generic-sound-essence-descriptor
    "060e2b34025301010d01010101014200"
    ,@mxf-view-file-descriptor-set-spec
    (#x3d01 :quantization-bits u32)
    (#x3d02 :locked bool)
    (#x3d03 :audio-sampling-rate rat)
    (#x3d04 :audio-ref-level u8)
    (#x3d05 :electrospatial-formulation u8)
    (#x3d06 :sound-essence-compression ul)
    (#x3d07 :channel-count u32)
    (#x3d0c :dial-norm u8)))

(defconst mxf-view-aes-fixed-data-spec
  '((:aes3-fixed-data vec 24)))

(defconst mxf-view-aes3-audio-essence-descriptor-set-spec
  `(:aes3-audio-essence-descriptor
    "060e2b34025301010d01010101014700"
    ,@mxf-view-generic-sound-essence-descriptor-set-spec
    (#x3d08 :aux-bits-mode u8)
    (#x3d09 :average-bytes/sec u32)
    (#x3d0a :block-align u16)
    (#x3d0d :emphasis u8)
    (#x3d0f :block-start-offset u16)
    (#x3d10 :channel-status-mode batch u8)
    (#x3d11 :fixed-channel-status-data batch mxf-view-aes-fixed-data-spec)
    (#x3d12 :user-data-mode vec 2)
    (#x3d13 :fixed-user-data vec 48)))

(defconst mxf-view-wave-audio-essence-descriptor-set-spec
  `(:wave-audio-essence-descriptor
    "060e2b34025301010d01010101014800"
    ,@mxf-view-generic-sound-essence-descriptor-set-spec
    (#x3d0a :block-align u16)
    (#x3d0b :sequence-offset u8)
    (#x3d09 :avg-bps u32)
    (#x3d29 :peak-envelope-version u32)
    (#x3d2a :peak-envelope-format u32)
    (#x3d2b :points-per-peak-value u32)
    (#x3d2c :peak-envelop-block-size u32)
    (#x3d2d :peak-channels u32)
    (#x3d2e :peak-frames u32)
    (#x3d2f :peak-of-peaks-position u64)
    (#x3d30 :peak-envelop-timestamp ts)
    (#x3d31 :peak-envelop-data u8)
    (#x3d32 :channel-assignment ul)))

(defconst mxf-view-generic-data-essence-descriptor-set-spec
  `(:generic-data-essence-descriptor
    "060e2b34025301010d01010101014300"
    ,@mxf-view-file-descriptor-set-spec
    (#x3e01 :data-essence-coding ul)))

(defconst mxf-view-anc-data-descriptor-set-spec
  `(:anc-data-descriptor
    "060e2b34025301010d01010101015c00"
    ,@mxf-view-generic-data-essence-descriptor-set-spec))

(defconst mxf-view-vbi-data-descriptor-set-spec
  `(:vbi-data-descriptor
    "060e2b34025301010d01010101015b00"
    ,@mxf-view-generic-data-essence-descriptor-set-spec))

(defconst mxf-view-mpeg2-video-descriptor-set-spec
  `(:mpeg2-video-descriptor
    "060e2b34025301010d01010101015100"
    ,@mxf-view-cdci-picture-essence-descriptor-set-spec
    ("060e2b34010101050401060201020000" :single-sequence bool)
    ("060e2b34010101050401060201030000" :constant-bframes bool)
    ("060e2b34010101050401060201040000" :coded-content-type u8)
    ("060e2b34010101050401060201050000" :low-delay bool)
    ("060e2b34010101050401060201060000" :closed-gop bool)
    ("060e2b34010101050401060201070000" :identical-gop bool)
    ("060e2b34010101050401060201080000" :max-gop u16)
    ("060e2b34010101050401060201090000" :bpicture-count u16)
    ("060e2b340101010504010602010a0000" :profile-and-level u8)
    ("060e2b340101010504010602010b0000" :bit-rate u32)))

(defconst mxf-view-timeline-track-set-spec
  `(:timeline-track
    "060e2b34025301010d01010101013b00"
    ,@mxf-view-interchange-set-spec
    (#x4801 :track-id u32)
    (#x4802 :track-name utf16)
    (#x4803 :track-segment ref)
    (#x4804 :track-number u32)
    (#x4b01 :edit-rate rat)
    (#x4b02 :origin u64)
    (#x4b03 :mark-in u64)
    (#x4b04 :mark-out u64)
    (#x4b05 :user-position u64)
    (#x4b06 :package-mark-in-position u64)
    (#x4b07 :package-mark-out-position u64)))

(defconst mxf-view-structural-component-set-spec
  `(:structural-component
    "060e2b34025301010d01010101010200"
    ,@mxf-view-interchange-set-spec
    (#x0201 :data-definition ul)
    (#x0202 :duration u64)))

(defconst mxf-view-sequence-set-spec
  `(:sequence
    "060e2b34025301010d01010101010f00"
    ,@mxf-view-structural-component-set-spec
    (#x1001 :structural-components batch ref)))

(defconst mxf-view-timecode-component-set-spec
  `(:timecode-component
    "060e2b34025301010d01010101011400"
    ,@mxf-view-structural-component-set-spec
    (#x1501 :start-timecode u64)
    (#x1502 :rounded-timecode-base u16)
    (#x1503 :drop-frame bool)))

(defconst mxf-view-source-clip-set-spec
  `(:source-clip
    "060e2b34025301010d01010101011100"
    ,@mxf-view-structural-component-set-spec
    (#x1101 :source-package-id umid)
    (#x1102 :source-track-id u32)
    (#x1201 :start-position u64)
    (#x1202 :fade-in-length u64)
    (#x1203 :fade-in-type u16)
    (#x1204 :fade-out-length u64)
    (#x1205 :fade-out-type u16)))

(defconst mxf-view-header-metadata-list
  '(mxf-view-primer-pack-spec
    mxf-view-preface-set-spec
    mxf-view-identifications-set-spec
    mxf-view-content-storage-set-spec
    mxf-view-essence-container-data-set-spec
    mxf-view-material-package-set-spec
    mxf-view-source-package-set-spec
    mxf-view-network-locator-set-spec
    mxf-view-text-locator-set-spec
    mxf-view-multiple-descriptor-set-spec
    mxf-view-cdci-picture-essence-descriptor-set-spec
    mxf-view-mpeg2-video-descriptor-set-spec
    mxf-view-aes3-audio-essence-descriptor-set-spec
    mxf-view-wave-audio-essence-descriptor-set-spec
    mxf-view-anc-data-descriptor-set-spec
    mxf-view-vbi-data-descriptor-set-spec
    mxf-view-timeline-track-set-spec
    mxf-view-sequence-set-spec
    mxf-view-timecode-component-set-spec
    mxf-view-source-clip-set-spec))

;; ============================================================
;; index table
;; ============================================================

(defconst mxf-view-delta-entry-spec
  '((:pos-table-index u8)
    (:slice u8)
    (:element-delta u32)))

(defconst mxf-view-index-entry-spec
  '((:temporal-offset u8)
    (:key-frame-offset u8)
    (:flags u8)
    (:stream-offset u64)
    (:slice-offset u32 array mxf-view--index-slice-count)
    (:pos-table rat array mxf-view--index-pos-table-count)))

(defconst mxf-view-index-table-spec
  '(:index-table
    "060e2b34025301010d01020101100100"
    (#x3c0a :instance-uid uuid)
    (#x3f0b :index-edit-rate rat)
    (#x3f0c :index-start-position u64)
    (#x3f0d :index-duration u64)
    (#x3f05 :edit-unit-byte-count u32)
    (#x3f06 :index-sid u32)
    (#x3f07 :body-sid u32)
    (#x3f08 :slice-count u8 mxf-view--index-slice-count)
    (#x3f0e :pos-table-count u8 mxf-view--index-pos-table-count)
    (#x3f09 :delta-entry-array batch mxf-view-delta-entry-spec)
    (#x3f0a :index-entry-array batch mxf-view-index-entry-spec)))

;; ============================================================
;; essence container
;; ============================================================

(defconst mxf-view-content-package-items
  '(("060e2b34020501..0d01030104......" . :cp-system-item)
    ("060e2b34024301..0d01030104..02.." . :package-metadata-set)
    ("060e2b34024301..0d01030104..03.." . :picture-metadata-set)
    ("060e2b34024301..0d01030104..04.." . :sound-metadata-set)
    ("060e2b34024301..0d01030104..05.." . :data-metadata-set)
    ("060e2b34026301..0d01030104..06.." . :control-data-set)
    ("060e2b34010201..0d01030105......" . :cp-picture-item)
    ("060e2b34010201..0d01030106......" . :cp-sound-item)
    ("060e2b34010201..0d01030107......" . :cp-data-item)
    ("060e2b34010201..0d01030115......" . :gc-picture-item)
    ("060e2b34010201..0d01030116......" . :gc-sound-item)
    ("060e2b34010201..0d01030117......" . :gc-data-item)
    ("060e2b34010201..0d01030118......" . :gc-compound-item)))

;; ============================================================
;; utilities
;; ============================================================

(defun mxf-view-log (level format &rest args)
  "At LEVEL, display a message made from (format-message FORMAT ARGS)."
  (display-warning 'mxf (apply 'format-message format args) level))

(defun mxf-view-err (format &rest args)
  "Display error message made from (format-message FORMAT ARGS)."
  (apply 'mxf-view-log :error format args))

(defun mxf-view-warn (format &rest args)
  "Display error message made from (format-message FORMAT ARGS)."
  (apply 'mxf-view-log :warning format args))

(defun mxf-view-debug (format &rest args)
  "Display error message made from (format-message FORMAT ARGS)."
  (apply 'mxf-view-log :debug format args))

(defun mxf-view-not-found ()
  "Message constant."
  (mxf-view-warning-str "Not found."))

(defun mxf-view-detect-fill-spec (kl)
  "Return fill spec of KL.  Return nil if no spec found."
  (seq-find (lambda (spec)
              (string= (car kl) (nth 1 spec)))
            mxf-view-fill-spec))

;; ============================================================
;; basic type readers
;; ============================================================

(defun mxf-view-read-u8 ()
  "Read a byte."
  (prog1 (char-after)
    (forward-char)))

(defun mxf-view-read-u16 ()
  "Read a 16 bit integer of big endian."
  (logior (lsh (mxf-view-read-u8) 8) (mxf-view-read-u8)))

(defun mxf-view-read-u24 ()
  "Read a 24 bit integer of big endian."
  (logior (lsh (mxf-view-read-u8) 16) (mxf-view-read-u16)))

(defun mxf-view-read-u32 ()
  "Read a 32 bit integer of big endian."
  (logior (lsh (mxf-view-read-u16) 16) (mxf-view-read-u16)))

(defun mxf-view-read-u64 ()
  "Read a 64 bit integer of big endian."
  (logior (lsh (mxf-view-read-u32) 32) (mxf-view-read-u32)))

(defun mxf-view-read-bool ()
  "Read a bool."
  (logand (mxf-view-read-u8) #x01))

(defun mxf-view-read-value (len)
  "Read a substring in LEN length."
  (buffer-substring (point)
                    (progn
                      (forward-char len)
                      (point))))

(defun mxf-view-read-vec (len)
  "Read a vector in LEN length."
  (string-to-vector (mxf-view-read-value len)))

(defun mxf-view-read-ul ()
  "Read a UL(Universal Label)."
  (mxf-view-read-vec 16))

(defalias 'mxf-view-read-ref 'mxf-view-read-ul)
(defalias 'mxf-view-read-uuid 'mxf-view-read-ul)

(defun mxf-view-read-utf16 (len)
  "Read a UTF-16BE string in LEN length."
  (decode-coding-string (mxf-view-read-value len) 'utf-16be))

;; ============================================================
;; complex type readers
;; ============================================================

(defun mxf-view-read-rat ()
  "Read a rational number."
  (mxf-view-unpack '((:numerator u32)
                     (:denominator u32))))

(defun mxf-view-read-ts ()
  "Read a timestamp."
  (mxf-view-unpack '((:year u16)
                     (:month u8)
                     (:day u8)
                     (:hour u8)
                     (:minutes u8)
                     (:seconds u8)
                     (:qmsec u8))))

(defun mxf-view-read-umid ()
  "Read a UMID."
  (mxf-view-unpack '((:content-type vec 16)
                     (:guid vec 16))))

(defun mxf-view-normalize-key (key)
  "Return interned symbol if KEY is number, otherwise return KEY."
  (if (numberp key)
      (intern (format ":item-%d" key))
    key))

(defun mxf-view-normalize-value (val)
  "Return bound value if VAL is of symbol, otherwise return VAL."
  (if (symbolp val)
      (symbol-value val)
    val))

(defun mxf-view-read-number-item (spec num)
  "Read an item of SPEC as number NUM."
  (mxf-view-read-item
   `(,(mxf-view-normalize-key num) ,spec)))

(defun mxf-view-read-batch (spec)
  "Read a batch of SPEC values.

Automatically read batch length and count."
  (let ((batch (mxf-view-unpack '((:count u32)
                                  (:length u32)))))
    (dotimes (i (mxf-view-get :count batch))
      (push (mxf-view-read-number-item spec (1+ i)) batch))
    (nreverse batch)))

(defun mxf-view-read-until (spec length)
  "Read a sequence of SPEC with max LENGTH length.

LENGTH should be an integer or a symbol bound to an integer."
  (let ((end (+ (point) (mxf-view-normalize-value length)))
        (i 0)
        array)
    (while (< (point) end)
      (push (mxf-view-read-number-item spec (cl-incf i)) array))
    (nreverse array)))

(defun mxf-view-read-array (spec count)
  "Read an array of SPEC with max COUNT elements.

COUNT should be an integer or a symbol bound to an integer."
  (let (array)
    (dotimes (i (mxf-view-normalize-value count))
      (push (mxf-view-read-number-item spec (1+ i)) array))
    (nreverse array)))

;; ============================================================
;; item related functions
;; ============================================================

(defun mxf-view-read-item (item &optional item-len)
  "Read an ITEM.  ITEM-LEN is required if ITEM is of UTF-16."
  (let ((result (pcase (cdr item)
                  (`(utf16)
                   `((:type utf16 :len ,item-len)
                     ,@(mxf-view-read-utf16 item-len)))
                  (`(,type)
                   `((:type ,type)
                     ,@(mxf-view-read-field type)))
                  (`(vec ,len)
                   `((:type vec :len ,len)
                     ,@(mxf-view-read-vec len)))
                  (`(batch ,spec)
                   `((:type batch)
                     ,@(mxf-view-read-batch spec)))
                  (`(,spec until ,len)
                   `((:type array :len ,len)
                     ,@(mxf-view-read-until spec len)))
                  (`(,spec array ,count)
                   `((:type array :count ,count)
                     ,@(mxf-view-read-array spec count)))
                  (`(,type ,sym)
                   (set (make-local-variable sym) (mxf-view-read-field type))
                   `((:type ,type)
                     ,@(symbol-value sym)))
                  (_ (cons nil nil)))))
    (push (car item) (car result))
    result))

(defun mxf-view-unpack (spec)
  "Read an item of SPEC."
  (let (result)
    (dolist (item spec)
      (push (mxf-view-read-item item) result))
    (nreverse result)))

(defun mxf-view-read-field (type)
  "Read a field of TYPE."
  (let ((reader (intern-soft (format "mxf-view-read-%s" type))))
    (if reader
        (funcall (symbol-function reader))
      (mxf-view-unpack (symbol-value type)))))

(defun mxf-view-get (key item)
  "Get the KEY's value from ITEM."
  (let ((key (mxf-view-normalize-key key)))
    (cdr (seq-find (lambda (field)
                     (eq (caar field) key))
                   item))))

;; ============================================================
;; KLV(Key Length Value triplet) related functions
;; ============================================================

(defmacro mxf-view-with-rollback (&rest body)
  "Evaluate BODY, move back to previous point if error occurred."
  (declare (indent 0) (debug t))
  (let ((pos (make-symbol "--pos--"))
        (err (make-symbol "--err--")))
    `(let ((,pos (point)))
       (condition-case ,err
           (progn ,@body)
         ((error user-error quit)
          (goto-char ,pos)
          (message (error-message-string ,err)))))))

(defun mxf-view-hex (vec)
  "Make a hex string of VEC."
  (mapconcat #'(lambda (x) (format "%02x" x)) vec ""))

(defun mxf-view-read-key ()
  "Read a KLV key."
  (pcase (mxf-view-hex (mxf-view-read-vec 16))
    ((and key
          (pred (string-match "^060e2b34")))
     key)
    (_
     (error "No MXF key found"))))

(defun mxf-view-read-ber ()
  "Read a lenght of BER(Basic Encoding Rules)."
  (let ((b1 (mxf-view-read-u8)))
    (if (< b1 128) b1
      (let ((vec (nreverse (mxf-view-read-vec (logand b1 127))))
            (result 0)
            (i 0))
        (while (< i (length vec))
          (setq result (logior result
                               (lsh (aref vec i) (* i 8))))
          (cl-incf i))
        result))))

(defun mxf-view-read-kl ()
  "Return a cons-pair of KLV key and length."
  (condition-case nil
      (cons (mxf-view-read-key)
            (mxf-view-read-ber))
    (error
     (mxf-view-err "Can't read key or ber length")
     nil)))

(defun mxf-view-skip (len)
  "Move point forward by LEN length."
  (let ((pos (point))
        (end-of-buffer (point-max)))
    (cond ((< end-of-buffer (+ pos len))
           (mxf-view-warn "Detected an attempt to go beyond end of buffer")
           (goto-char end-of-buffer))
          (t
           (forward-char len)))))

(defun mxf-view-skip-fill ()
  "Find a non-filler packet."
  (let ((start (point))
        (kl (mxf-view-read-kl)))
    (pcase (mxf-view-detect-fill-spec kl)
      (`(,tag . ,_)
       (mxf-view-skip (cdr kl))
       (mxf-view-make-instance
        start tag kl '(((:fill) . (lambda ()
                                    (mxf-view-warning-str "Omitted."))))))
      (_
       (goto-char start)
       nil))))

;; ============================================================
;; instance factory
;; ============================================================

(defun mxf-view-make-instance (offset tag kl data)
  "Make a klv instnace with OFFSET, TAG, KL and DATA."
  `((,tag :type klv
          :offset ,(1- offset)
          :key ,(car kl)
          :len ,(cdr kl))
    ,@data))

(defun mxf-view-make-essence (offset tag kl)
  "Make a klv instnace with OFFSET, TAG and KL."
  `((,tag :type klv
          :offset ,(1- offset)
          :key ,(car kl)
          :len ,(cdr kl))
    ((:data :beg ,(1- (point))
            :end ,(+ (point) (cdr kl) -1))
     . (lambda ()
         (mxf-view-warning-str
          (format-message "Omitted. (`x': hexlify essence, `e': extract essence)"))))))

(defun mxf-view-make-group (offset tag data)
  "Make a group of klvs with OFFSET, TAG and DATA."
  `((,tag :type group
          :offset ,(1- offset))
    ,@data))

(defun mxf-view-make-partition (index data len)
  "Make an mxf partition with INDEX, DATA and LEN."
  (let ((ppack (cdr (caar data)))
        (sym (make-symbol (format ":partition-%02d" index))))
    `((,sym :type klv
            :offset ,(plist-get ppack :offset)
            :key ,(plist-get ppack :key)
            :len ,len)
      ,@data)))

;; ============================================================
;; partition parsers
;; ============================================================

(defun mxf-view-read-pack (spec)
  "Read a pack of SPEC."
  (mxf-view-with-rollback
    (let ((start (point))
          (kl (mxf-view-read-kl))
          (regexp (nth 1 spec)))
      (if (string-match regexp (car kl))
          (mxf-view-make-instance start (car spec) kl (mxf-view-unpack (nthcdr 2 spec)))
        (error "Not found key of %s" (car spec))))))

(defun mxf-view-tag-or-ul (tag)
  "If TAG is for descriptive metadata, find ul from primer pack."
  (if (< tag #x8000) tag
    (plist-get mxf-view--local-tags-plist tag)))

(defun mxf-view-read-set (spec set-length)
  "Read a header metadata of SPEC with max length SET-LENGTH."
  (let ((end (+ (point) set-length))
        result)
    (while (< (point) end)
      (let ((tag (mxf-view-read-u16))
            (len (mxf-view-read-u16)))
        (pcase (assoc (mxf-view-tag-or-ul tag) spec)
          ((pred null)
           (mxf-view-warn "Unknown tag found: tag=%d, len=%d" tag len))
          (`(,_ . ,item)
           (save-excursion
             (push (mxf-view-read-item item len) result))))
        (mxf-view-skip len)))
    (nreverse result)))

(defun mxf-view-read-primer-pack (pos)
  "Read primer pack from POS then build `mxf-view--local-tags-plist'."
  (goto-char pos)
  (let ((ppack (mxf-view-read-pack mxf-view-primer-pack-spec))
        plist)
    (dolist (item (mxf-view-get :local-tags (cdr ppack)))
      (pcase item
        (`((,_ :type mxf-view-local-tag-spec)
           ((:tag ,_ ,_) . ,tag)
           ((:ul ,_ ,_ ) . ,ul))
         (push (mxf-view-hex ul) plist)
         (push tag plist))))
    (setq-local mxf-view--local-tags-plist plist)
    ppack))

(defun mxf-view-read-metadata ()
  "Read a header metadata.  Skip unknown metadata."
  (let* ((start (point))
         (kl (mxf-view-read-kl))
         (spec (seq-find (lambda (spec)
                           (string-match (nth 1 spec) (car kl)))
                         (mapcar 'symbol-value mxf-view-header-metadata-list))))
    (if spec
        (if (eq spec mxf-view-primer-pack-spec)
            (mxf-view-read-primer-pack start)
          (mxf-view-make-instance start (car spec) kl (mxf-view-read-set spec (cdr kl))))
      (mxf-view-warn "Unknown data detected: key=0x%s, len=%d, offset=%d"
                     (car kl) (cdr kl) start)
      (mxf-view-skip (cdr kl))
      (mxf-view-make-instance start :unknown kl
                              `(lambda ()
                                 ,(mxf-view-warning-str
                                   (format "Omitted. (key=0x%s, len=%d, offset=%d)"
                                           (car kl) (cdr kl) start)))))))

(defun mxf-view-read-all-metadata (ppack)
  "Read all header metadata within current partition along with PPACK."
  (let ((len (mxf-view-get :header-byte-count ppack))
        result)
    (if (zerop len)
        'mxf-view-not-found
      (push (mxf-view-skip-fill) result)
      (let ((end (+ (point) len)))
        (while (< (point) end)
          (push (mxf-view-read-metadata) result)
          (push (mxf-view-skip-fill) result))
        (nreverse result)))))

(defun mxf-view-read-index-table (ppack)
  "Read an index table along with PPACK."
  (let ((len (mxf-view-get :index-byte-count ppack))
        (spec mxf-view-index-table-spec)
        result)
    (if (zerop len)
        'mxf-view-not-found
      (let ((start (point))
            (kl (mxf-view-read-kl))
            (regexp (nth 1 spec)))
        (when (string-match regexp (car kl))
          (push (mxf-view-make-instance start (car spec) kl
                                        (mxf-view-read-set spec (cdr kl)))
                result)
          (let ((end (+ start len)))
            (while (< (point) end)
              (push (mxf-view-skip-fill) result)))
          (nreverse result))))))

(defun mxf-view-read-content-packages ()
  "Read content packages."
  (let ((partition-key (nth 1 mxf-view-partition-pack-spec))
        finish content-package result)
    (while (not finish)
      (let* ((pos (point))
             (kl (or (mxf-view-read-kl)
                     (cons partition-key 0)))
             (end-of-cp (assoc-string (car kl) content-package)))
        (setq finish (string-match partition-key (car kl)))
        (when (or end-of-cp finish)
          (push (mapcar 'cdr (nreverse content-package)) result)
          (setq content-package nil)
          (if finish (goto-char pos)))  ; rewind
        (unless finish
          (pcase (seq-find (lambda (item)
                             (string-match (car item) (car kl)))
                           mxf-view-content-package-items)
            (`(,_ . ,tag)
             (push (cons (car kl) (mxf-view-make-essence pos tag kl)) content-package)
             (mxf-view-skip (cdr kl)))
            (_
             (cond ((mxf-view-detect-fill-spec kl)
                    (goto-char pos)     ; rewind for skip
                    (push (cons nil (mxf-view-skip-fill)) content-package))
                   (t                   ; unknown data
                    (push (cons nil (mxf-view-make-essence pos :unknown kl)) content-package)
                    (mxf-view-skip (cdr kl)))))))))
    (nreverse result)))

(defun mxf-view-read-essence-container (ppack)
  "Read an essence container along with PPACK."
  (if (zerop (mxf-view-get :body-sid ppack))
      'mxf-view-not-found
    (let ((index 0))
      (mapcar (lambda (package)
                (let ((key (make-symbol
                            (format ":content-package-%d" (cl-incf index)))))
                  (mxf-view-make-group 0 key package)))
              (mxf-view-read-content-packages)))))

(defun mxf-view-find-rip ()
  "Find an RIP(Random Index Pack)."
  (goto-char (- (point-max) 4))
  (pcase (mxf-view-read-u32)
    ((pred zerop)
     nil)
    (len
     (goto-char (- (point-max) len))
     (save-excursion
       (setq-local mxf-view--pindex-length (- (cdr (mxf-view-read-kl)) 4)))
     (pcase (mxf-view-read-pack mxf-view-random-index-pack-spec)
       ((pred stringp) nil)
       (rip
        rip)))))

(defun mxf-view-find-next-partition ()
  "Find next partition."
  (let ((pos (point))
        (partition-key (nth 1 mxf-view-partition-pack-spec))
        (run-in-limit (* 64 1024)))
    (catch 'found
      (while (< (- (point) pos) run-in-limit)
        (condition-case nil
            (save-excursion
              (if (string-match partition-key (mxf-view-read-key))
                  (throw 'found t)))
          (end-of-buffer
           (throw 'found nil))
          (error
           (forward-char)))))))

(defun mxf-view-read-partition (index)
  "Read a partition at index INDEX."
  (let ((start (point))
        (ppack (mxf-view-read-pack mxf-view-partition-pack-spec))
        result)
    (unless ppack
      (error "No partition pack found"))
    (push ppack result)
    (push (mxf-view-skip-fill) result)
    (push (mxf-view-make-group (point) :header-meta-data
                               (mxf-view-read-all-metadata (cdr ppack)))
          result)
    (push (mxf-view-make-group (point) :index-table-segment
                               (mxf-view-read-index-table (cdr ppack)))
          result)
    (push (mxf-view-make-group (point) :essence-container
                               (mxf-view-read-essence-container (cdr ppack)))
          result)
    (mxf-view-make-partition index (nreverse result) (- (point) start))))

;; ============================================================
;; widget factory
;; ============================================================

(defun mxf-view-add-node-widget (parent value pos-list depth)
  "Put a node text property along with PARENT, VALUE, POS-LIST and DEPTH."
  (let ((children-end (1- (pop pos-list)))
        (children-beg (1- (pop pos-list)))
        (item-beg (pop pos-list)))
    (put-text-property item-beg
                       children-beg
                       'mxf-view-item
                       `((:type . mxf-view-node)
                         (:value . ,value)
                         (:parent . ,parent)
                         (:depth . ,depth)
                         (:children-beg . ,children-beg)
                         (:children-end . ,children-end)
                         ,(cons :closed nil)))
    (when (zerop parent)
      (let ((name (substring (symbol-name (caar value)) 1)))
        (put-text-property item-beg children-end
                           'mxf-view-partition
                           `((:name . ,name)
                             (:range . (,children-beg . ,children-end))))))))

(defun mxf-view-add-leaf-widget (parent value pos-list depth)
  "Put a leaf text property along with PARENT, VALUE, POS-LIST and DEPTH."
  (let ((item-end (pop pos-list))
        (item-beg (pop pos-list)))
    (put-text-property item-beg
                       item-end
                       'mxf-view-item
                       `((:type . mxf-view-leaf)
                         (:value . ,value)
                         (:parent . ,parent)
                         (:depth . ,depth)
                         (:children-beg . ,item-end)
                         (:children-end . ,item-end)
                         ,(cons :closed nil)))))

;; ============================================================
;; widget accessor
;; ============================================================

(defmacro mxf-view-define-widget-accessor (sym)
  "Define widget accessor of SYM."
  (let* ((symstr (substring (symbol-name sym) 1))
         (getter (intern (format "mxf-view-getw-%s" symstr)))
         (setter (intern (format "mxf-view-setw-%s" symstr))))
    `(progn
       (defun ,getter (widget)
         ,(format "Return %s of WIDGET." sym)
         (alist-get ,sym (if (numberp widget)
                             (mxf-view-widget-at widget)
                           widget)))
       (defun ,setter (widget val)
         ,(format "Set %s of WIDGET to VAL." sym)
         (setf (alist-get ,sym widget) val)))))

(mxf-view-define-widget-accessor :type)
(mxf-view-define-widget-accessor :value)
(mxf-view-define-widget-accessor :parent)
(mxf-view-define-widget-accessor :depth)
(mxf-view-define-widget-accessor :children-beg)
(mxf-view-define-widget-accessor :children-end)
(mxf-view-define-widget-accessor :closed)

(defun mxf-view-isw-node-p (widget)
  "Return t if WIDGET is of node."
  (eq (mxf-view-getw-type widget) 'mxf-view-node))

(defun mxf-view-getw-label (widget)
  "Return label of WIDGET value."
  (caar (mxf-view-getw-value widget)))

(defun mxf-view-getw-data (widget)
  "Return data of WIDGET value."
  (cdar (mxf-view-getw-value widget)))

(defun mxf-view-setw-visibility (widget flag)
  "Set WIDGET visibility to FLAG."
  (let ((beg (mxf-view-getw-children-beg widget))
        (end (mxf-view-getw-children-end widget)))
    (put-text-property beg end 'invisible (not flag))))

(defun mxf-view-setw-icon (widget icon)
  "Set WIDGET icon ICON."
  (let ((pos (point))
        (icon-regexp (format "\\(%s\\|%s\\)"
                             (regexp-quote mxf-view-open-icon)
                             (regexp-quote mxf-view-close-icon))))
    (goto-char (1- (mxf-view-getw-children-beg widget)))
    (beginning-of-line)
    (when (re-search-forward icon-regexp)
      (insert-and-inherit icon)
      (delete-region (match-beginning 0)
                     (match-end 0)))
    ;; `save-excursion' does not restore position...
    (goto-char pos)))

(defun mxf-view-setw-status (widget open-flag)
  "Set icon and status of WIDGET to OPEN-FLAG."
  (mxf-view-setw-icon widget (if open-flag mxf-view-open-icon
                              mxf-view-close-icon))
  (mxf-view-setw-closed widget (not open-flag)))

(defun mxf-view-getw-partition-name (point)
  "Get partition name from POINT."
  (alist-get :name (get-text-property point 'mxf-view-partition)))

(defun mxf-view-getw-partition-range (point)
  "Get partition range from POINT."
  (alist-get :range (get-text-property point 'mxf-view-partition)))

;; ============================================================
;; widget motion
;; ============================================================

(defun mxf-view-widget-at (&optional point)
  "Get MXF item property at POINT."
  (get-text-property
   (save-mark-and-excursion
    (goto-char (or point (point)))
    (line-beginning-position))
   'mxf-view-item))

(defmacro mxf-view-with-widget (spec &rest body)
  "In SPEC, mxf widget property will bound to VAR, then Evaluate BODY.

\(fn \(VAR\) BODY...\)"
  (declare (indent 1))
  (let ((prop (car spec)))
    `(let ((,prop (mxf-view-widget-at)))
       (and (eobp)
            (user-error "End of buffer"))
       (unless ,prop
         (user-error "No MXF item property found"))
       ,@body)))

(defmacro mxf-view-with-each-children (spec &rest body)
  "In SPEC, each child of WIDGET will bound to VAR, then Evaluate BODY.

\(fn (VAR WIDGET) BODY...)"
  (declare (indent 1)
           (debug (listp body)))
  (let ((var (car spec))
        (widget (nth 1 spec))
        (pos (make-symbol "--pos--"))
        (beg (make-symbol "--beg--"))
        (end (make-symbol "--end--")))
    `(let ((,beg (mxf-view-getw-children-beg ,widget))
           (,end (mxf-view-getw-children-end ,widget)))
       (while (< ,beg ,end)
         (let* ((,var (get-text-property ,beg 'mxf-view-item))
                (,pos (or (text-property-not-all ,beg ,end 'mxf-view-item ,var)
                          (1+ ,end))))
           (setq ,beg ,pos)
           ,@body)))))

(defun mxf-view-adjust-cursor-pos ()
  "Adjust cursor position and return the depth of it."
  (mxf-view-with-widget (w)
    (beginning-of-line)
    (if (search-forward ":" nil 'no-error)
        (backward-char))
    (mxf-view-getw-depth w)))

(defun mxf-view-goto-parent ()
  "Move cursor to parent item of this item."
  (interactive)
  (mxf-view-with-widget (w)
    (goto-char (mxf-view-getw-parent w))
    (mxf-view-adjust-cursor-pos)))

(defun mxf-view-next-widget-internal (&optional arg)
  "Move forward up to ARG count.  Internal use only."
  (pcase (forward-line arg)
    ((pred (< 0))
     (user-error "End of buffer"))
    ((pred (> 0))
     (user-error "Beginning of buffer"))
    (_
     (while (invisible-p (point))
       (forward-line arg))
     (mxf-view-adjust-cursor-pos))))

(defun mxf-view-next-widget (&optional arg)
  "Move forward up to ARG count."
  (interactive "p")
  (mxf-view-with-rollback
    (mxf-view-next-widget-internal arg)))

(defun mxf-view-previous-widget (&optional arg)
  "Move backward up to ARG count."
  (interactive "p")
  (mxf-view-next-widget (if (null arg) -1 (- arg))))

(defun mxf-view-next-sibling-widget (&optional arg)
  "Move forward to next sibling item up to ARG count."
  (interactive "p")
  (mxf-view-with-rollback
    (mxf-view-with-widget (w)
      (catch 'found
        (let ((this-depth (mxf-view-getw-depth w)))
          (while t
            (let ((next-depth (mxf-view-next-widget-internal arg)))
              (cond ((= next-depth this-depth)
                     (throw 'found t))
                    ((< next-depth this-depth)
                     (user-error "No more sibling item"))))))))))

(defun mxf-view-previous-sibling-widget (&optional arg)
  "Move backward to prior sibling item until ARG count."
  (interactive "p")
  (mxf-view-next-sibling-widget (if (null arg) -1 (- arg))))

(defun mxf-view-toggle-widget (widget)
  "Toggle WIDGET."
  (interactive
   (list (mxf-view-widget-at)))
  (or (mxf-view-isw-node-p widget)
      (user-error "Can't toggle leaf item"))
  (let ((inhibit-read-only t)
        (open (mxf-view-getw-closed widget)))
    (mxf-view-setw-visibility widget open)
    (mxf-view-setw-status widget open)
    (when open
      (mxf-view-with-each-children (child widget)
        (if (mxf-view-getw-closed child)
            (mxf-view-setw-visibility child nil))))
    (set-buffer-modified-p nil)))

(defun mxf-view-toggle-all-widget (widget)
  "Toggle WIDGET and her children."
  (interactive
   (list (mxf-view-widget-at)))
  (or (mxf-view-isw-node-p widget)
      (user-error "Can't toggle leaf item"))
  (let ((inhibit-read-only t)
        (open (mxf-view-getw-closed widget)))
    (mxf-view-setw-visibility widget open)
    (mxf-view-setw-status widget open)
    (mxf-view-with-each-children (child widget)
      (and (mxf-view-isw-node-p child)
           (mxf-view-setw-status child open))))
  (set-buffer-modified-p nil))

(defun mxf-view-collapse-all ()
  "Collapse all widget."
  (goto-char (point-min))
  (save-excursion
    (while (not (eobp))
      (mxf-view-with-widget (w)
        (call-interactively 'mxf-view-toggle-all-widget)
        (goto-char (1+ (mxf-view-getw-children-end w))))))
  (mxf-view-adjust-cursor-pos))

(defun mxf-view-extract-essence (widget)
  "Extract essence of WIDGET to file."
  (interactive
   (list (mxf-view-widget-at)))
  (or (eq (mxf-view-getw-label widget) :data)
      (user-error "No essence under cursor"))
  (let ((mxf-view-file buffer-file-name)
        (data (mxf-view-getw-data widget))
        (file (read-file-name "Extract essence to: ")))
    (and (string-blank-p file)
         (user-error "Canceled"))
    (and (file-exists-p file)
         (or (y-or-n-p (format-message "File `%s' exists; overwrite? " file))
             (user-error "Canceled")))
    (with-temp-file file
      (set-buffer-multibyte nil)
      (set-buffer-file-coding-system 'binary)
      (insert-file-contents-literally mxf-view-file nil
                                      (plist-get data :beg)
                                      (plist-get data :end)))
    (message "Essence exported to %s" file)))

(defun mxf-view-hexlify-essence (widget)
  "Hexlify essence of WIDGET."
  (interactive
   (list (mxf-view-widget-at)))
  (or (eq (mxf-view-getw-label widget) :data)
      (user-error "No essence under cursor"))
  (let ((buffer (get-buffer-create "MXF-View-Essence"))
        (mxf-view-file buffer-file-name)
        (data (mxf-view-getw-data widget))
        (inhibit-read-only t))
    (with-current-buffer buffer
      (erase-buffer)
      (set-buffer-multibyte nil)
      (set-buffer-file-coding-system 'binary)
      (insert-file-contents-literally mxf-view-file nil
                                      (plist-get data :beg)
                                      (plist-get data :end))
      (setq buffer-undo-list nil)
      (hexlify-buffer)
      (set-buffer-modified-p nil)
    (view-buffer-other-window buffer))))

(defun mxf-view-open-parent (widget)
  "Open parent of WIDGET until root."
  (let ((parent (mxf-view-getw-parent widget)))
    (when (< 0 parent)
      (goto-char parent)
      (mxf-view-with-widget (w)
        (if (mxf-view-getw-closed w)
            (call-interactively 'mxf-view-toggle-widget))
        (mxf-view-open-parent w)))))

(defun mxf-view-goto (&optional pos)
  "Move to the given POS."
  (let ((inhibit-read-only t))
    (goto-char (or pos (point)))
    (save-excursion
      (mxf-view-with-widget (w)
        (if (mxf-view-getw-closed w)
            (call-interactively 'mxf-view-toggle-all-widget))
        (mxf-view-open-parent w)))
    (mxf-view-adjust-cursor-pos))
  (set-buffer-modified-p nil))

(defun mxf-view-suspend ()
  "Suspend mxf-view buffer."
  (interactive)
  (bury-buffer))

(defun mxf-view-close ()
  "Close mxf-view buffer."
  (interactive)
  (kill-buffer))

;; ============================================================
;; imenu support functions
;; ============================================================

(defvar mxf-view-imenu-expression
  '(("Partition Pack" "\\]:\\(partition-pack\\) " 1)
    ("Header Meta" "\\]:\\(preface\\) " 1)
    ("Header Meta" "\\]:\\(identifications\\) " 1)
    ("Header Meta" "\\]:\\(.*-package\\) " 1)
    ("Header Meta" "\\]:\\(.*-descriptor\\) " 1)
    ("Header Meta" "\\]:\\(.*-track\\) " 1)
    ("Index Table" "\\]:\\(index-table\\) " 1)
    ("Essence Container" "\\]:\\(content-package-.*\\)" 1)))

(defun mxf-view-imenu-index ()
  "Create an index for imenu."
  (let (result)
    (save-excursion
      (pcase-dolist (`(,group ,exp ,pos) mxf-view-imenu-expression)
        (goto-char (point-min))
        (while (re-search-forward exp nil t)
          (let ((name (match-string-no-properties pos))
                (idx (match-beginning pos)))
            (push (list (mxf-view-getw-partition-name idx)
                        (cons (format "(%s) %s" group name) idx))
                  result)))))
    ;; stable sort
    (sort (nreverse result)
          (lambda (a b)
            (string< (car a) (car b))))))

(defun mxf-view-imenu-goto (_ position &rest __)
  "Move to the given POSITION."
  (mxf-view-goto position))

;; ============================================================
;; widget renderer
;; ============================================================

(defun mxf-view-render-indent (depth)
  "Insert white spaces of DEPTH count."
  (make-string (* depth (length mxf-view-open-icon)) #x20))

(defun mxf-view-render-vector (vec)
  "Render a vector VEC as a sequence of hexadecimal strings."
  (mapconcat (lambda (x)
               (format "%02x" x)) vec " "))

(defun mxf-view-render-value (val)
  "Render value VAL."
  (pcase val
    ((pred integerp)
     (mxf-view-value-str
      (format "%d (0x%02x)" val val)))
    ((pred vectorp)
     (concat "[" (mxf-view-value-str (mxf-view-render-vector val)) "]"))
    ((pred functionp)
     (funcall val))
    ((pred stringp)
     (mxf-view-string-str
      (prin1-to-string val)))
    (_
     (mxf-view-value-str
      (prin1-to-string val)))))

(defun mxf-view-render-properties (klv)
  "Render KLV properties."
  (if (eq (plist-get klv :type) 'klv)
      (mxf-view-property-str
       (format " (key=0x%s, len=%d, offset=%d)"
               (plist-get klv :key)
               (plist-get klv :len)
               (plist-get klv :offset)))
    ""))

(defun mxf-view-make-uuid-pos-list (button)
  "Make a list of uuid positions with BUTTON."
  (let ((ref (overlay-get button 'uuid))
        (start (overlay-start button))
        (end (overlay-end button))
        (range (mxf-view-getw-partition-range (point)))
        list)
    (save-excursion
      (goto-char (car range))
      (while (< (point) (cdr range))
        (let ((found (text-property-any (point) (cdr range)
                                        'mxf-view-reference ref)))
          (cond ((null found)
                 (goto-char (1+ (cdr range))))
                ((and (<= start found)
                      (<= found end))
                 ;; ignore self
                 (goto-char found)
                 (end-of-line))
                (t
                 (push (goto-char found) list)
                 (end-of-line))))))
    (nreverse list)))

(defun mxf-view-goto-uuid (button)
  "Find another uuid BUTTON and jump to it."
  (let ((list (mxf-view-make-uuid-pos-list button)))
    (cond ((null list)
           (user-error "No reference found"))
          ((null (cdr list))
           (mxf-view-goto (car list)))
          (t
           (let ((candidates
                  (mapcar (lambda (pos)
                            (cons (format "%s/%s"
                                          (mxf-view-getw-label (mxf-view-getw-parent pos))
                                          (mxf-view-getw-label pos))
                                  pos))
                          (nreverse list))))
             (pcase (completing-read "Select location: " candidates nil t)
               ((pred null)
                (user-error "Canceled"))
               (key
                (mxf-view-goto (cdr (assoc key candidates))))))))))

(defun mxf-view-render-ref-button (uuid beg end)
  "Make a link button of UUID between buffer position BEG and END."
  (let ((ref (intern (concat "mxf-view-ref-"
                             (mxf-view-hex uuid)))))
    (make-button beg end
                 'action 'mxf-view-goto-uuid
                 'uuid ref)
    (put-text-property beg end 'mxf-view-reference ref)))

(defun mxf-view-render-leaf (node children depth)
  "Render a leaf with NODE, CHILDREN and DEPTH."
  (insert (mxf-view-render-indent depth)
          mxf-view-leaf-icon
          (mxf-view-leaf-str
           (prin1-to-string (car node)))
          " = "
          (mxf-view-render-value children)
          "\n")
  (pcase node
    ((or `(,_ :type ref)
         `(:instance-uid :type uuid))
     (save-excursion
       (forward-line -1)
       (if (re-search-forward ":[^ ]+" nil t)
           (mxf-view-render-ref-button children
                                       (match-beginning 0)
                                       (match-end 0)))))))

(defun mxf-view-render-node (node depth)
  "Render a node with NODE and DEPTH."
  (insert (mxf-view-render-indent depth)
          mxf-view-open-icon
          (mxf-view-node-str
           (prin1-to-string (car node)))
          (mxf-view-render-properties (cdr node))
          "\n"))

(defun mxf-view-render-instance (instance depth parent)
  "Render INSTANCE in DEPTH as children of PARENT."
  (let ((this (point))
        (node (car instance))
        (children (cdr instance))
        pos-list)
    (push this pos-list)
    (pcase children
      ((or (pred atom)
           (pred vectorp)
           (pred functionp))
       (mxf-view-render-leaf node children depth)
       (push (point) pos-list)
       (mxf-view-add-leaf-widget parent instance pos-list depth))
      (_
       (mxf-view-render-node node depth)
       (push (point) pos-list)
       (mxf-view-render children (1+ depth) this)
       (push (point) pos-list)
       (mxf-view-add-node-widget parent (cons node nil) pos-list depth)))))

(defun mxf-view-render (list &optional depth parent)
  "Render LIST in DEPTH as children of PARENT into current buffer."
  (dolist (instance list)
    (when instance
      (mxf-view-render-instance instance (or depth 0) (or parent 0)))))

;; ============================================================
;; initializer
;; ============================================================

(defun mxf-view-decode-buffer ()
  "Decode current buffer as MXF."
  (let ((coding-system-for-read 'binary)
        result)
    (set-buffer-multibyte nil)
    (pcase (mxf-view-find-rip)
      ((pred null)
       (let ((i 0))
         (goto-char (point-min))
         (while (mxf-view-find-next-partition)
           (push (mxf-view-read-partition (cl-incf i)) result))))
      (rip
       (let ((indexes (mxf-view-get :partition-index (cdr rip))))
         (dotimes (i (length indexes))
           (goto-char (+ (point-min)
                         (mxf-view-get :byte-offset (mxf-view-get (1+ i) indexes))))
           (push (mxf-view-read-partition (1+ i)) result))
         (push rip result))))
    (nreverse result)))

(defun mxf-view-setup (parsed-data)
  "Setup buffer with PARSED-DATA."
  (let ((inhibit-read-only t))
    (setq-local mxf-view--data parsed-data) ; currently for debug purposes only
    (erase-buffer)
    (set-buffer-multibyte t)
    (mxf-view-render parsed-data)
    (mxf-view-collapse-all)
    (set-buffer-modified-p nil)))

(defun mxf-view-revert-buffer (&optional _ __)
  "Revert buffer."
  (interactive)
  (let ((gc-cons-threshold most-positive-fixnum)
        (file-name buffer-file-name))
    (or (file-exists-p file-name)
        (user-error "File `%s' no longer exists" file-name))
    (message "Reverting `%s'..." (buffer-name))
    (mxf-view-setup
     (with-temp-buffer
       (insert-file-contents-literally file-name t)
       (mxf-view-decode-buffer)))
    (message nil)))

;;;###autoload
(let ((mxf-file-regexp "\\.mxf\\'"))
  (add-to-list 'auto-mode-alist `(,mxf-file-regexp . mxf-view-mode))
  (add-to-list 'auto-coding-alist `(,mxf-file-regexp . binary)))

(provide 'mxf-view)
;;; mxf-view.el ends here
