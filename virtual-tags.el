;;; virtual-tags.el --- 仮想的にtagsするための拡張

;; Copyright (C) 2010 tm8st

;; Author: tm8st <tm8st@hotmail.co.jp>
(defconst virtual-tags-version "0.1")
;; Keywords: tags, virtual

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the

;; GNU General Public License for more details.

;; You should have received ba  copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.	If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; 仮想的にTAGSとやりとりするためのelです。
;; 現状gtags, etagsに対応しています。

;; Installation:

;; (require 'virtual-tags)
;; (global-set-key (kbd "C-q C-e") 'virtual-tags-update-tags)
;; (global-set-key (kbd "C-q C-@") 'virtual-tags-init-tags)
;; (global-set-key (kbd "C-q C-j") 'virtual-tags-find-tags-from-here)
;; (global-set-key (kbd "C-q C-m") 'virtual-tags-find-tags)

;;; Code:

(require 'gtags)
(require 'etags)
(require 'anything-etags)

;; TAGS system info.
(defstruct virtual-tags-info
  (name nil)
  ;; (init-tags-func dir)
  (init-tags-func nil)
  ;; (update-tags-func dir)
  (update-tags-func nil)
  ;; (get-rootpath-func)
  (get-rootpath-func nil)
  ;; (find-tag-from-here-func)
  (find-tag-from-here-func nil)
  ;; (find-tag-func)
  (find-tag-func nil)
  )

(defvar virtual-tags-default-tags-system "ETAGS")

(defvar virtual-tags-info-list '()
  "TAGSシステムのリスト")

(defun virtual-tags-info-add-info (info)
  (add-to-list 'virtual-tags-info-list info))

(virtual-tags-info-add-info
 (make-virtual-tags-info
  :name "GTAGS"
  :init-tags-func 'virtual-tags-gtags-init-tags
  :update-tags-func 'virtual-tags-gtags-update-tags
  :get-rootpath-func 'gtags-get-rootpath
  :find-tag-from-here-func 'gtags-find-tag-from-here
  :find-tag-func 'gtags-find-tag
  ))

(virtual-tags-info-add-info
 (make-virtual-tags-info
  :name "ETAGS"
  :init-tags-func 'virtual-tags-etags-init-tags
  :update-tags-func 'virtual-tags-gtags-update-tags
  :get-rootpath-func 'virtual-tags-etags-get-rootpath
  :find-tag-from-here-func 'anything-etags-select-from-here
  :find-tag-func 'anything-etags-select
  ))

(defmacro virtual-tags-info-smart-call-func (access-func)
  (let ((info (virtual-tags-get-use-tags-system)))
    (when info
      (funcall (funcall access-func info))
      )))

(defun virtual-tags-get-use-tags-system ()
  "カレントバッファで使用するtagsシステムの取得"
  (let ((ret nil))
	(dolist (i virtual-tags-info-list)
	  (when (funcall (virtual-tags-info-get-rootpath-func i))
	    (setq ret i))
	  )
	ret))
  
(defun virtual-tags-find-tags-from-here ()
  "現在カーソル下にあるタグの検索"
  (interactive)
  (virtual-tags-info-smart-call-func virtual-tags-info-find-tag-from-here-func))

(defun virtual-tags-find-tags ()
  "入力されたタグの検索"
  (interactive)
  (virtual-tags-info-smart-call-func virtual-tags-info-find-tag-func))

(defun virtual-tags-update-tags ()
  "TAGSファイルの更新"
  (interactive)
  (virtual-tags-info-smart-call-func virtual-tags-info-update-tags-func))

(defun virtual-tags-get-info-name-alist ()
  "TAGSのシステムの"
  (mapcar
   '(lambda (info)
      (list (virtual-tags-info-name info) info))
   virtual-tags-info-list))

(defun virtual-tags-init-tags ()
  "TAGSの初期化"
  (interactive)
  (funcall
   (virtual-tags-info-init-tags-func
    (car (cdr (assoc 
	       (completing-read "select using tags system:" '(("GTAGS") ("ETAGS")) nil nil virtual-tags-default-tags-system)
	       (virtual-tags-get-info-name-alist)))))
   (expand-file-name (read-directory-name "root directory:"))
   ))
  
;;;-------------------------------
;;; for gtags
;;;-------------------------------
(defun virtual-tags-gtags-update-tags ()
 ""
  (interactive)
  (async-shell-command (concat "cd \"" (gtags-get-rootpath) "\" && gtags -v -i")))

(defun virtual-tags-gtags-init-tags (dir)
 ""
  (interactive)
  (async-shell-command (concat "cd \"" dir "\" && gtags -v")))

;;;-------------------------------
;;; for etags
;;;-------------------------------
(defun virtual-tags-etags-get-rootpath ()
  ""
  (anything-etags-find-tag-file (file-name-directory (buffer-file-name))))

(defvar virtual-tags-etags-command "ctags -e --recurse"
  "ETAGSの更新に使用するコマンド")

(defun virtual-tags-etags-update ()
  ""
  (interactive)
  (async-shell-command (concat "cd \"" (virtual-tags-etags-get-rootpath) "\" " virtual-tags-etags-command)))

(defun virtual-tags-etags-get-rootpath ()
  ""
  (anything-etags-find-tag-file (file-name-directory (buffer-file-name))))

(defun virtual-tags-etags-init-tags (dir)
 ""
  (interactive)
  (async-shell-command (concat "cd \"" dir "\" && " virtual-tags-etags-command)))

(provide 'virtual-tags)
