;;; mcs-20.el --- MIME charset implementation for Emacs 20 and XEmacs/mule

;; Copyright (C) 1997,1998,1999 Free Software Foundation, Inc.

;; Author: MORIOKA Tomohiko <morioka@jaist.ac.jp>
;; Keywords: emulation, compatibility, Mule

;; This file is part of APEL (A Portable Emacs Library).

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;;    This module requires Emacs 20.0.93, XEmacs 20.3-b5 (with mule)
;;    or later.

;;; Code:

(require 'poem)
(require 'custom)
(eval-when-compile (require 'wid-edit))


;;; @ MIME charset
;;;

(defcustom mime-charset-coding-system-alist
  (let ((rest
	 '((us-ascii      . raw-text)
	   (gb2312	  . cn-gb-2312)
	   (cn-gb	  . cn-gb-2312)
	   (iso-2022-jp-2 . iso-2022-7bit-ss2)
	   (x-ctext       . ctext)
	   (unknown       . undecided)
	   (x-unknown     . undecided)
	   ))
	dest)
    (while rest
      (let ((pair (car rest)))
	(or (find-coding-system (car pair))
	    (setq dest (cons pair dest))
	    ))
      (setq rest (cdr rest))
      )
    dest)
  "Alist MIME CHARSET vs CODING-SYSTEM.
MIME CHARSET and CODING-SYSTEM must be symbol."
  :group 'i18n
  :type '(repeat (cons symbol coding-system)))

(defcustom mime-charset-to-coding-system-default-method
  nil
  "Function called when suitable coding-system is not found from MIME-charset.
It must be nil or function.
If it is a function, interface must be (CHARSET LBT CODING-SYSTEM)."
  :group 'i18n
  :type '(choice function (const nil)))

(defsubst mime-charset-to-coding-system (charset &optional lbt)
  "Return coding-system corresponding with CHARSET.
CHARSET is a symbol whose name is MIME charset.
If optional argument LBT (`CRLF', `LF', `CR', `unix', `dos' or `mac')
is specified, it is used as line break code type of coding-system."
  (if (stringp charset)
      (setq charset (intern (downcase charset)))
    )
  (let ((cs (assq charset mime-charset-coding-system-alist)))
    (setq cs
	  (if cs
	      (cdr cs)
	    charset))
    (if lbt
	(setq cs (intern (format "%s-%s" cs
				 (cond ((eq lbt 'CRLF) 'dos)
				       ((eq lbt 'LF) 'unix)
				       ((eq lbt 'CR) 'mac)
				       (t lbt)))))
      )
    (if (find-coding-system cs)
	cs
      (if mime-charset-to-coding-system-default-method
	  (funcall mime-charset-to-coding-system-default-method charset lbt cs)
	))))

(defvar widget-mime-charset-prompt-value-history nil
  "History of input to `widget-mime-charset-prompt-value'.")

(define-widget 'mime-charset 'coding-system
  "A mime-charset."
  :format "%{%t%}: %v"
  :tag "MIME-charset"
  :prompt-history 'widget-mime-charset-prompt-value-history
  :prompt-value 'widget-mime-charset-prompt-value
  :action 'widget-mime-charset-action)

(defun widget-mime-charset-prompt-value (widget prompt value unbound)
  ;; Read mime-charset from minibuffer.
  (intern
   (completing-read (format "%s (default %s) " prompt value)
		    (mapcar (function
			     (lambda (sym)
			       (list (symbol-name sym))))
			    (mime-charset-list)))))

(defun widget-mime-charset-action (widget &optional event)
  ;; Read a mime-charset from the minibuffer.
  (let ((answer
	 (widget-mime-charset-prompt-value
	  widget
	  (widget-apply widget :menu-tag-get)
	  (widget-value widget)
	  t)))
    (widget-value-set widget answer)
    (widget-apply widget :notify widget event)
    (widget-setup)))

(defcustom default-mime-charset 'x-ctext
  "Default value of MIME-charset.
It is used when MIME-charset is not specified.
It must be symbol."
  :group 'i18n
  :type 'mime-charset)

(defcustom default-mime-charset-for-write
  (if (find-coding-system 'utf-8)
      'utf-8
    default-mime-charset)
  "Default value of MIME-charset for encoding.
It may be used when suitable MIME-charset is not found.
It must be symbol."
  :group 'i18n
  :type 'mime-charset)

(defcustom default-mime-charset-detect-method-for-write
  nil
  "Function called when suitable MIME-charset is not found to encode.
It must be nil or function.
If it is nil, variable `default-mime-charset-for-write' is used.
If it is a function, interface must be (TYPE CHARSETS &rest ARGS).
CHARSETS is list of charset.
If TYPE is 'region, ARGS has START and END."
  :group 'i18n
  :type '(choice function (const nil)))

(defun detect-mime-charset-region (start end)
  "Return MIME charset for region between START and END."
  (let ((charsets (find-charset-region start end)))
    (or (charsets-to-mime-charset charsets)
	(if default-mime-charset-detect-method-for-write
	    (funcall default-mime-charset-detect-method-for-write
		     'region charsets start end)
	  default-mime-charset-for-write)
	)))

(defun write-region-as-mime-charset (charset start end filename
					     &optional append visit lockname)
  "Like `write-region', q.v., but encode by MIME CHARSET."
  (let ((coding-system-for-write
	 (or (mime-charset-to-coding-system charset)
	     'binary)))
    (write-region start end filename append visit lockname)))


;;; @ end
;;;

(provide 'mcs-20)

;;; mcs-20.el ends here
