;; trans.el -- interface to kanji dictionary lookup program

;; Authors: 1994 Lars Huttar, with Jeffrey Friedl
;; Created: 1994/04/19
;; Version: 960412.3
;; Last Modified: 1996/04/12

;; BLURB:
;; An emacs interface to trans, written by Lars Huttar. Very nifty!
;;
;; "960412.3"
;;    Inserted small pause after process creation to allow process to
;;    get on its feet. The first command had been getting echoed to the
;;    screen, and this fixed it.
;;
;;
;;>
;; Purpose and Requirements:
;;
;; This is a facility for conveniently producing references for kanji that
;; occur in a block of text.  It requires the perl script `trans' to be in
;; your exec-path, and a dictionary compatible with Jim Breen's EDICT.
;; You'll also need a Japanese-capable Emacs, i.e. Nemacs or Mule.
;;
;; Usage:
;;
;; When you're viewing some Japanese text in a buffer, you can use the
;; commands `trans-line' and `trans-region' to invoke trans on the text.
;; The *trans* buffer will pop up, displaying all references found for the
;; kanji in the current line or region.
;;
;; Setup:
;;
;; Put trans.el somewhere in your load-path and put the following in your
;; ~/.emacs file:
;;
;; (autoload 'trans-line "trans")
;; (autoload 'trans-region "trans")
;; (define-key global-map "\C-ct" 'trans-line)      ;; suggested bindings
;; (define-key global-map "\C-c\C-t" 'trans-region)
;;
;;<
;;

(defvar trans-mark (make-marker)
  "Marker where last trans-region command started inserting.")

(defun trans-line ()
  "Run `trans' on the current line, with output to *trans* buffer."
  (interactive)
  (let (beg end)
    (save-excursion
      (beginning-of-line)
      (setq beg (point))
      (forward-line 1)
      (setq end (point)))
    (trans-region nil beg end)))

(defun trans-region (&optional arg from to)
  "Run `trans' on the current region and put the output into *trans* buffer.
Pop up *trans* buffer.  With prefix arg, use current buffer instead of region."
  (interactive "P\nr")
  (let ((buf (get-buffer-create "*trans*"))
        (proc (get-process "*trans*"))
	(origbuf (current-buffer))
        (str (buffer-substring from to)))
    (pop-to-buffer buf)
    (pop-to-buffer origbuf)
    (save-excursion
      (set-buffer buf)
      (if (or (not proc) (not (eq (process-status proc) 'run)))
          (progn
            (setq proc (start-process "*trans*" buf
				      "trans" "-noprompt" "-quiet"))

	    (sleep-for 0.5 500) ;; This seems to be required to allow the
                          	;; process to get going.

            (set-process-filter proc 'trans-filter)
            (set-marker (process-mark proc) (point-max) buf)))
      (move-marker trans-mark (marker-position (process-mark proc)) buf))
    (process-send-string proc (format "trans - %d genkigenkigenki\n"
                                      (window-width)))
    (process-send-string proc str)
    (process-send-string proc "genkigenkigenki\n")
    ))

(defun trans-filter (proc str)
  "Filter for *trans* process.  Tries to ensure visibility of output.
Does the right thing with carriage returns."
  (let* ((buf (process-buffer proc))
         (win (get-buffer-window buf)))
    ;; Can I assume the current-buffer is the process's buffer?  I don't know.
    (save-excursion
      (set-buffer buf)
      (goto-char (process-mark proc))
      ;; interpret carriage returns...
      (if (and (> (point) (point-min))
               (= (char-after (1- (point))) ?\r))
          (delete-region (point) (progn (beginning-of-line) (point))))
      (insert str)
      (move-marker (process-mark proc) (point))
      (if win    ;; If buffer not visible, do nothing.
          (let* ((curstart (window-start win))
                 (h (1- (window-height win)))
                 (sl (count-lines trans-mark (point)))
                 (bl (max h sl)))
            ;; Make the last bl lines visible in the window.
            (forward-line (- bl))
            (set-window-start win (point)))))))

