;;; mcharset.el --- MIME charset API

;; Copyright (C) 1997,1998 Free Software Foundation, Inc.

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

;;; Code:

(require 'poe)
(require 'pcustom)

(cond ((featurep 'mule)
       (cond ((featurep 'xemacs)
	      (require 'mcs-xm)
	      )
	     ((>= emacs-major-version 20)
	      (require 'mcs-e20)
	      )
	     (t
	      ;; for MULE 1.* and 2.*
	      (require 'mcs-om)
	      ))
       )
      ((boundp 'NEMACS)
       ;; for Nemacs and Nepoch
       (require 'mcs-nemacs)
       )
      (t
       (require 'mcs-ltn1)
       ))

(defcustom default-mime-charset-for-write
  (if (and (fboundp 'find-coding-system)
	   (find-coding-system 'utf-8))
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

(defun charsets-to-mime-charset (charsets)
  "Return MIME charset from list of charset CHARSETS.
Return nil if suitable mime-charset is not found."
  (if charsets
      (catch 'tag
	(let ((rest charsets-mime-charset-alist)
	      cell)
	  (while (setq cell (car rest))
	    (if (catch 'not-subset
		  (let ((set1 charsets)
			(set2 (car cell))
			obj)
		    (while set1
		      (setq obj (car set1))
		      (or (memq obj set2)
			  (throw 'not-subset nil))
		      (setq set1 (cdr set1)))
		    t))
		(throw 'tag (cdr cell)))
	    (setq rest (cdr rest)))
	  ))))


;;; @ end
;;;

(provide 'mcharset)

;;; mcharset.el ends here
