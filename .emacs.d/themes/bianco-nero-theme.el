;;; -*- lexical-binding: t; -*-

;;; bianco-nero-theme.el

;; Disabling syntax highlighting using (global-font-lock-mode -1) will interfere
;; with other useful functionalities (such as for example whitespace-mode) that
;; are NOT syntax highlighting.
;; So you're going to do it here.

(deftheme bianco-nero
  "Black and white theme with no syntax highlighting.")

(custom-theme-set-faces
 'bianco-nero
 '(default                        ((t (:background "black" :foreground "white"))))
 '(font-lock-comment-face         ((t (:background "black" :foreground "white"))))
 '(region                         ((t (:background "white" :foreground "black"))))
 '(font-lock-builtin-face         ((t (:background "black" :foreground "white"))))
 '(font-lock-constant-face        ((t (:background "black" :foreground "white"))))
 '(font-lock-keyword-face         ((t (:background "black" :foreground "white"))))
 '(font-lock-variable-name-face   ((t (:background "black" :foreground "white"))))
 '(font-lock-function-name-face   ((t (:background "black" :foreground "white"))))
 '(font-lock-string-face          ((t (:background "black" :foreground "white"))))
 '(font-lock-type-face            ((t (:background "black" :foreground "white"))))
 '(cursor                         ((t (:background "white"))))
 )

(provide-theme 'bianco-nero)

;;; bianco-nero-theme.el ends here
