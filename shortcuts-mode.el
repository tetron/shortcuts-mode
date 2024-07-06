;; shortcuts-mode.el --- minor mode providing a buffer shortcut bar    -*- lexical-binding: t; -*-

;; Copyright (C) 2024  Peter Amstutz

;; Author: Peter Amstutz <tetron@interreality.org>
;; Keywords: lisp
;; Version: 1.0.0

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

;; This is a minor mode which adds a sticky window to the top of the
;; frame listing the last ten buffers that were accessed.  You can
;; then instantly switch the current window to one of the recent
;; buffers using C-1 through C-0.
;;
;; As a special case, certain utility buffers (*Buffer List*,
;; *Ibuffer*, the *shortcuts* buffer itself) are excluded from the top
;; bar.  Dired buffers are also filtered, because otherwise navigating
;; the filesystem through dired (which creates a new buffer for each
;; directory) tends to fill up all the top slots.

;;; Code:

(defun shrink-string (p n)
  (let ((p2 (* 2 (/ p 2))))
    (if (> (length n) (1+ p2))
	(concat (substring n 0 (/ p 2)) "…" (substring n (/ p -2) nil))
      n)))

(defun filtered-buffer-list ()
  (cons nil (seq-remove (lambda (e)
		(or (string-prefix-p " " (buffer-name e))
		    (string= (buffer-name e) "*shortcuts*")
		    (string= (buffer-name e) "*Ibuffer*")
		    (string= (buffer-name e) "*Buffer List*")
		    (string= (buffer-local-value 'major-mode e) "dired-mode")))
	      (buffer-list))))

(defun switch-to-shortcut (n)
  (switch-to-buffer (elt (filtered-buffer-list) n)))

(defun goto-shortcut (@click)
  (interactive "e")
  (let ((shortcut nil))
    (with-current-buffer "*shortcuts*"
      (setq shortcut (get-text-property (posn-point (event-start @click)) 'shortcut-target)))
    (switch-to-shortcut shortcut)))

(defun close-shortcut (@click)
  (interactive "e")
  (let ((shortcut nil))
    (with-current-buffer "*shortcuts*"
      (setq shortcut (get-text-property (posn-point (event-start @click)) 'shortcut-target)))
    (kill-buffer (elt (filtered-buffer-list) shortcut))))

(defun insert-shortcut (b num shortcuts-width cols)
  (let* ((md (buffer-local-value 'major-mode (elt b num)))
	 (width (/ shortcuts-width cols))
	 (avail (- width 6))
	 (modewidth (- (/ avail 3) 2))
	 (modename (substring (format "%s" md) 0 -5))
	 (mdstr (if (> (+ (length (buffer-name (elt b num))) (length modename)) avail)
		    (concat "(" (shrink-string modewidth modename) ")")
		  (format "(%s)" modename)))
	 (bufstr (shrink-string (- avail (length mdstr)) (buffer-name (elt b num))))
	 (txt (format "C-%d %s%s%s "
		      (% num 10)
		      bufstr
		      (make-string (- avail (length bufstr) (length mdstr) -1) ?\s)
		      mdstr))
	 (k (make-sparse-keymap))
	 (bufwin (get-buffer-window (elt b num))))
    (define-key k [mouse-1] 'goto-shortcut)
    (define-key k [mouse-2] 'close-shortcut)
    (put-text-property 0 (1- (length txt)) 'keymap k txt)
    (put-text-property 0 (1- (length txt)) 'mouse-face 'highlight txt)
    (put-text-property 0 (1- (length txt)) 'shortcut-target num txt)
    (if bufwin
	(put-text-property 0 (1- (length txt)) 'face 'bold txt))
    (insert txt)))

(defun update-shortcuts ()
  (let ((win (get-buffer-window "*shortcuts*")))
    (if win
	(let* ((shortcuts-buf (get-buffer-create "*shortcuts*"))
	       (b (filtered-buffer-list))
	       (num 0)
	       (shortcuts-width (window-body-width win))
	       (cols (min (/ shortcuts-width 25) 5)))
	  (with-current-buffer shortcuts-buf
	    (make-local-variable 'buffer-read-only)
	    (setq buffer-read-only nil)
	    (erase-buffer)
	    (setq num 1)
	    (while (and (< num (length b)) (<= num (* cols 2)))
	      (insert-shortcut b num shortcuts-width cols)
	      (setq num (+ num 2)))
	    (insert ?\n)
	    (setq num 2)
	    (while (and (< num (length b)) (<= num (* cols 2)))
	      (insert-shortcut b num shortcuts-width cols)
	      (setq num (+ num 2)))
	    (goto-char 0)
	    (setq buffer-read-only t))
	  (with-selected-window win
	    (shrink-window-if-larger-than-buffer))))))

(defun do-shortcut-1 ()
  (interactive)
  (switch-to-shortcut 1))
(defun do-shortcut-2 ()
  (interactive)
  (switch-to-shortcut 2))
(defun do-shortcut-3 ()
  (interactive)
  (switch-to-shortcut 3))
(defun do-shortcut-4 ()
  (interactive)
  (switch-to-shortcut 4))
(defun do-shortcut-5 ()
  (interactive)
  (switch-to-shortcut 5))
(defun do-shortcut-6 ()
  (interactive)
  (switch-to-shortcut 6))
(defun do-shortcut-7 ()
  (interactive)
  (switch-to-shortcut 7))
(defun do-shortcut-8 ()
  (interactive)
  (switch-to-shortcut 8))
(defun do-shortcut-9 ()
  (interactive)
  (switch-to-shortcut 9))
(defun do-shortcut-0 ()
  (interactive)
  (switch-to-shortcut 10))

(defun shortcuts-mode ()
  (interactive)
  (let ((n (display-buffer-in-side-window (get-buffer-create "*shortcuts*") (list '(side . top)))))
    (set-window-dedicated-p n t)
    (set-window-parameter n 'no-other-window t)
    (with-selected-window n
       (make-local-variable 'window-size-fixed)
       (make-local-variable 'mode-line-format)
       (setq mode-line-format (list ""))))
  (add-hook 'buffer-list-update-hook 'update-shortcuts)
  (add-hook 'window-configuration-change-hook 'update-shortcuts)
  (global-set-key [?\C-1] 'do-shortcut-1)
  (global-set-key [?\C-2] 'do-shortcut-2)
  (global-set-key [?\C-3] 'do-shortcut-3)
  (global-set-key [?\C-4] 'do-shortcut-4)
  (global-set-key [?\C-5] 'do-shortcut-5)
  (global-set-key [?\C-6] 'do-shortcut-6)
  (global-set-key [?\C-7] 'do-shortcut-7)
  (global-set-key [?\C-8] 'do-shortcut-8)
  (global-set-key [?\C-9] 'do-shortcut-9)
  (global-set-key [?\C-0] 'do-shortcut-0))

(provide 'shortcuts-mode)
