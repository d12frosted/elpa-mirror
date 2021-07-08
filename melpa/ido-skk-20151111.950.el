;;; ido-skk.el --- ido interface for skk henkan

;; Author: tsukimizake <shomasd_at_gmail.com>
;; Version: 0.1
;; Package-Version: 20151111.950
;; Package-Commit: 89a2e62799bff2841ff634517c86084c4ce69246
;; Package-Requires: ((emacs "24.4") (ddskk "20150912.1820"))
;; Keywords: languages
;; URL: https://github.com/tsukimizake/ido-skk

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
;; skkの候補選択のインターフェースとしてidoを使うようにアドバイスを噛ませます。
;; ido-migemoと併用すると、その漢字の別の読み方を入力する事で絞り込むという、ありそうでなかった日本語入力ができるようになります。

;;; Usage:
;; init.elに

;; (require 'ido-skk)
;; (ido-skk-mode +1)

;; と書けば使えるようになります。

;;; Code:

(require 'skk)
(require 'nadvice)
(require 'ido)

(defvar ido-skk-not-found-str "not found (辞書登録に入ります)")

(defun ido-skk ()
  (let ((res
	 (ido-completing-read "SKK: " (add-to-list 'skk-henkan-list ido-skk-not-found-str))))
    
    (if (string= res ido-skk-not-found-str)
	nil
      (progn
	(setq skk-kakutei-flag t)
	res))
    ))

(defun ido-skk-henkan-show-candidates (orig-func &rest args)
  "An advice function to replace `skk-henkan-show-candidates'"
  (ido-skk))

;;;###autoload
(define-minor-mode ido-skk-mode "ido for skk henkan."
  :init-value nil
  :lighter idoSKK
  (if ido-skk-mode
      (progn
	(advice-add 'skk-henkan-show-candidates :around 'ido-skk-henkan-show-candidates)
	(setq enable-recursive-minibuffers t))
      (advice-remove 'skk-henkan-show-candidates 'ido-skk-henkan-show-candidates)))

(provide 'ido-skk)



;;; ido-skk.el ends here
