;;; rgb.el --- RGB control via OpenRGB
;; Version: 2.0.0
;; Package-Version: 20220717.1940
;; Package-Commit: 4aab5a5be16b69b47ef5e67d02782df5e41dbd7b
;; URL: https://gitlab.com/cwpitts/rgb.el
;; Package-Requires: ((emacs "24.3"))

;; Copyright © 2022 Christopher Pitts <cwpitts@protonmail.com>
;; Permission is hereby granted, free of charge, to any person
;; obtaining a copy of this software and associated documentation
;; files (the “Software”), to deal in the Software without
;; restriction, including without limitation the rights to use, copy,
;; modify, merge, publish, distribute, sublicense, and/or sell copies
;; of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;; THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
;; HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
;; WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
;; DEALINGS IN THE SOFTWARE.

;;; Commentary:
;; This package uses RGB CLI tools to control RGB devices
;; from within Emacs.  By default it uses the OpenRGB software,
;; assuming that there's a usable OpenRGB installation that can be
;; found on the path.  Other supported backends can be added and configured
;; by changing the `rgb-mode-backend` variable.

;;; Code:
(require 'cl-lib)

(defgroup rgb nil
  "Sync RGB devices with Emacs buffers."
  :group 'external
  :prefix "rgb-")

(defcustom rgb-executable (executable-find "openrgb")
  "Executable for controlling RGB hardware."
  :group 'rgb
  :type '(string))
(defcustom rgb-device-ids (list)
  "List of device IDs to control."
  :group 'rgb
  :type '(repeat string))
(defcustom rgb-argmap (cl-pairlis '() '())
  "Mapping of major modes to associated RGB setting parameters."
  :group 'rgb
  :type '(alist :key-type (symbol :tag "Major mode")
                :value-type (alist :tag "Parameters"
                                   :key-type (symbol :tag "Parameter")
                                   :value-type (string :tag "Value"))))
(defcustom rgb-mode-backend "openrgb"
  "Backend to use for RGB control."
  :group 'rgb
  :type '(string))

(defun rgb-set-rgb-from-mode (current-major-mode)
  "Select RGB color backend and pass MODE to the backend function."
  (funcall
	 (intern (format "rgb-backend-%s" rgb-mode-backend)) current-major-mode))

(cl-defun rgb-set-openrgb (&key device color light-mode)
  "Execute RGB set command on DEVICE with arguments for COLOR and MODE."
  (let ((args (list)))
    (if device (set 'args (append args (list "-d" (format "%s" device)))))
    (if color (set 'args (append args (list "-c" (format "%s" color)))))
    (if light-mode (set 'args (append args (list "-m" (format "%s" light-mode)))))
    (apply #'start-process
           (append (list rgb-executable
                         (format "*%s*" rgb-executable)
                         rgb-executable)
                   args))))

(defun rgb-backend-openrgb (current-major-mode)
  "Set RGB color based on CURRENT-MAJOR-MODE."
  (let ((params (assoc-default current-major-mode rgb-argmap)))
    (if params
        (mapc (lambda (device-id)
                (rgb-set-openrgb
                 :device device-id
                 :color (substring (assoc-default 'color params) 1)
                 :light-mode (assoc-default 'mode params)))
              rgb-device-ids))))

(defun rgb-change-hook (_window)
  "Hook for handling buffer/window change."
  (rgb-set-rgb-from-mode major-mode))

;;;###autoload
(define-minor-mode rgb-mode
  "Global RGB mode."
  :global t
  :lighter " RGB"
  :group 'rgb
  (if rgb-mode
      (add-hook 'window-state-change-functions #'rgb-change-hook)
    (remove-hook 'window-state-change-functions #'rgb-change-hook)))

(provide 'rgb)
;;; rgb.el ends here
