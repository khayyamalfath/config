;;; -*- lexical-binding: t -*-

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages '(multiple-cursors web-mode)))

;;; Profile
;; Switches some settings around depending if I am at home or at work
(defvar my-profile 'personal)
;;(defvar my-profile 'work)

;; Theme
;; Disabling syntax highlighting using (global-font-lock-mode -1) will interfere
;; with other useful functionalities (such as for example whitespace-mode) that
;; are NOT syntax highlighting.
;; So you're going to do it here.
;; (defvar bg "black")
;; (defvar fg "white")

;; (set-face-attribute 'default                      nil :background bg :foreground fg)
;; (set-face-attribute 'font-lock-comment-face       nil :background bg :foreground fg)
;; (set-face-attribute 'region                       nil :background fg :foreground bg)
;; (set-face-attribute 'font-lock-builtin-face       nil :background bg :foreground fg)
;; (set-face-attribute 'font-lock-constant-face      nil :background bg :foreground fg)
;; (set-face-attribute 'font-lock-keyword-face       nil :background bg :foreground fg)
;; (set-face-attribute 'font-lock-variable-name-face nil :background bg :foreground fg)
;; (set-face-attribute 'font-lock-function-name-face nil :background bg :foreground fg)
;; (set-face-attribute 'font-lock-string-face        nil :background bg :foreground fg)

;; (dolist (face '(default
;;                 font-lock-comment-face
;;                 font-lock-builtin-face
;;                 font-lock-constant-face
;;                 font-lock-keyword-face
;;                 font-lock-string-face
;;                 font-lock-function-name-face
;;                 font-lock-variable-name-face
;;   (when (facep face)
;;     (set-face-attribute face nil :background bg :foreground fg)))

;; ;; Selection is inverted so it stays visible
;; (set-face-attribute 'region nil :background fg :foreground bg)

;;; User interface
;;(menu-bar-mode -1)                        ; Disables menu bar
(tool-bar-mode -1)                        ; Disables toolbar
(tab-bar-mode -1)                         ; Disables tabs
(setq inhibit-startup-screen t)           ; Disables startup screen
(setq initial-scratch-message nil)        ; Disables scrach message
(setq-default truncate-lines t)           ; Disables word wrap
(column-number-mode 1)                    ; Shows column numbers (Status bar)

;; Formats line and column numbers on the status bar
(setq mode-line-position-column-line-format '(" L%l C%c"))

;; Draws a guid line for columns width
;;(global-display-fill-column-indicator-mode 1)
;;(setq-default fill-column 80)
;;(set-face-attribute 'fill-column-indicator nil :inverse-video t)

;; Highlight a line if it goes over a set column width
(require 'whitespace)
(setq whitespace-line-column 80)
(setq whitespace-style '(face lines-tail))
(global-whitespace-mode 1)
(set-face-attribute 'whitespace-line nil :inverse-video t)

(show-paren-mode -1)                      ; Disable parentheses highlighting

;;; Behavior
(setq make-backup-files nil)              ; Disables backup files
(delete-selection-mode 1)                 ; Replaces selected text when pasting

;; Various attempts at starting the editor zoomed in by 1 (+1)
;;(text-scale-set 1)
;;(set-face-attribute 'default nil :height 120)
;;(set-face-attribute 'default nil :font "Courier New-10")
;;(set-face-attribute 'default nil :font "Courier New-12")

;; https://emacs.stackexchange.com/questions/77667/emacs-starts-in-extremely-tiny-window
;;(add-to-list 'default-frame-alist '(fullscreen . maximized))
;;(add-to-list 'default-frame-alist '(width . 80))  ; Width set to 80 characters
;;(add-to-list 'default-frame-alist '(height . 24)) ; Height set to 24 lines

;; Removes trailing whitespaces
(add-hook 'before-save-hook 'delete-trailing-whitespace)

;; Indentation and tab
;; https://pement.org/emacs_tabs.htm
;; http://blog.lujun9972.win/emacs-document/blog/2018/08/17/the-ultimate-guide-to-indentation-in-emacs-(tabs-and-spaces)/

;; Permanently use tab-to-tab-stop to control TAB behavior
(global-set-key (kbd "TAB") 'tab-to-tab-stop)
;; Permanently force Emacs to indent with spaces, never with TABs
(setq-default indent-tabs-mode nil)
;; Permanently set the default tab-width to 8 characters
(setq-default tab-width 8)

;; Fixes backspacing tabs
;; https://emacs.stackexchange.com/questions/56083/how-to-make-backspace-respect-tab-stops-when-there-is-only-preceeding-white-spac
;; "&optional _arg" is required for C and C#
;;(defun my-backspace-whitespace-to-tab-stop ()
(defun my-backspace-whitespace-to-tab-stop (&optional _arg)
  "Delete whitespace backwards to the next tab-stop, otherwise delete one
    character."
  (interactive)
  (if (or indent-tabs-mode (use-region-p)
          (> (point)
             (save-excursion
               (back-to-indentation)
               (point))))
      (call-interactively 'backward-delete-char)
    (let ((step (% (current-column) tab-width))
          (pt (point)))
      (when (zerop step)
        (setq step tab-width))
      ;; Account for edge case near beginning of buffer.
      (setq step (min (- pt 1) step))
      (save-match-data
        (if (string-match "[^\t ]*\\([\t ]+\\)$"
                          (buffer-substring-no-properties
                           (- pt step) pt))
            (backward-delete-char (- (match-end 1)
                                     (match-beginning 1)))
          (call-interactively 'backward-delete-char))))))

(global-set-key [remap backward-delete-char-untabify]
                #'my-backspace-whitespace-to-tab-stop)
(global-set-key [remap delete-backward-char]
                #'my-backspace-whitespace-to-tab-stop)

;;; Language specific settings
;;; All languages
(electric-indent-mode 1)                  ; Indents automatically
(electric-pair-mode 1)                    ; Closes pairs (i.e. "")

;; Indentation settings
(defun my-by-profile (personal work)
  (if (eq my-profile 'personal) personal work))

;; If the cursor is between { and }, RET will result in Allman style braces
;; Example:
;;
;;        int main(void) {|}
;;
;; will result in
;;
;;        int  main(void)
;;        {
;;                |
;;        }
;;
(defun my-allman-newline ()
  (interactive)
  ;; Checks if the cursor is between braces
  (if (and (eq (char-before) ?{) (eq (char-after) ?}))
      (progn
        ;; Moves the { on its own line if it isn't already
        (save-excursion
          (backward-char)
          (skip-chars-backward " \t")
          (unless (bolp)
            (delete-region (point)
                           (progn (skip-chars-forward " \t") (point)))
            (newline-and-indent)))
        ;; Leave an empty line between { and }, with the } on its own line
        (newline-and-indent)
        (newline-and-indent)
        ;; Move up inside the block and indent the line, leaving the cursor
        ;; there, ready to type
        (forward-line -1)
        (indent-according-to-mode))
    ;; If it's not between braces, normal behavior applies: newline and
    ;; indentation
    (newline-and-indent)))

;;; C#
;; Indentation settings
(defvar my-csharp-indent (my-by-profile 8 4))

;; Defines C sharp settings
(defun my-csharp-setup ()
  ;; Sets the default tab-width (manual)
  (setq-local tab-width my-csharp-indent)
  ;; Forces spaces instead of tabs
  (setq-local indent-tabs-mode nil)
  ;; Sets the default tab-width (auto) for both modes
  (setq-local c-basic-offset my-csharp-indent)
  (when (boundp 'csharp-ts-mode-indent-offset)
    (setq-local csharp-ts-mode-indent-offset my-csharp-indent))
  ;; Disables the automatic newline behavior, so that it doesn't interfere with
  ;; the behavior we are defining
  (setq-local electric-pair-open-newline-between-pairs nil)
  ;; Binds our newline behavior to enter
  (local-set-key (kbd "RET") #'my-allman-newline)
  ;; Applies my function to fix backspacing tabs
  (setq-local c-backspace-function #'my-backspace-whitespace-to-tab-stop))

;; Sets the above for both modes
(add-hook 'csharp-mode-hook    #'my-csharp-setup)
(add-hook 'csharp-ts-mode-hook #'my-csharp-setup)

;;: HTML, CSS, JS (Web mode)
;; Indentation settings
(defvar my-html-indent   (my-by-profile 8 8))
(defvar my-css-indent    (my-by-profile 8 4))
(defvar my-js-indent     (my-by-profile 8 4))

;; Defines HTML, CSS and JS settings
(defun my-web-setup ()
  ;; Tab width and indentation
  (setq-local tab-width
              (pcase web-mode-content-type
                ("css"        my-css-indent)
                ("javascript" my-js-indent)
                (_            my-html-indent)))
  (setq-local web-mode-markup-indent-offset my-html-indent)
  (setq-local web-mode-css-indent-offset    my-css-indent)
  (setq-local web-mode-code-indent-offset   my-js-indent)
  ;; Required for Allman braces
  (when (eq my-profile 'personal)
    (setq-local electric-pair-open-newline-between-pairs nil)))

(add-hook 'web-mode-hook #'my-web-setup)

;; Allman braces only in CSS and JS, and only for the personal profile
;; Calls the Allman braces function or not, depending on profile
(defun my-web-newline ()
  (interactive)
  (if (and (eq my-profile 'personal)
           (member web-mode-content-type '("css" "javascript")))
      (my-allman-newline)
    (call-interactively (lookup-key (current-global-map) (kbd "RET")))))

(with-eval-after-load 'web-mode
  (define-key web-mode-map (kbd "RET") #'my-web-newline))

;;; Python
(defvar my-python-indent (my-by-profile 8 8))

;; Defines Python settings
(defun my-python-setup ()
  ;; Tab width and indentation
  (setq-local python-indent-offset my-python-indent)
  (setq-local tab-width my-python-indent))

(add-hook 'python-mode-hook    #'my-python-setup)
(add-hook 'python-ts-mode-hook #'my-python-setup)

;;; Remapped keyboard shortcuts
;; Sets Ctrl-z from suspend-frame to undo
(global-set-key (kbd "C-z") #'undo)

;;; Packages
;;; Multiple cursors
;; https://github.com/magnars/multiple-cursors.el
;; https://emacsrocks.com/e13.html
(unless (package-installed-p 'multiple-cursors)
  (package-refresh-contents)
  (package-install 'multiple-cursors))

(require 'multiple-cursors)

;; Multiple cursors shortcuts
(global-set-key (kbd "C-S-c C-S-c") 'mc/edit-lines)
(global-set-key (kbd "C->")         'mc/mark-next-like-this)
(global-set-key (kbd "C-<")         'mc/mark-previous-like-this)
(global-set-key (kbd "C-c C-<")     'mc/mark-all-like-this)

;;; Web mode
(unless (package-installed-p 'web-mode)
  (package-refresh-contents)
  (package-install 'web-mode))

(require 'web-mode)
(add-to-list 'auto-mode-alist '("\\.phtml\\'"     . web-mode))
(add-to-list 'auto-mode-alist '("\\.tpl\\.php\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.[agj]sp\\'"   . web-mode))
(add-to-list 'auto-mode-alist '("\\.as[cp]x\\'"   . web-mode))
(add-to-list 'auto-mode-alist '("\\.erb\\'"       . web-mode))
(add-to-list 'auto-mode-alist '("\\.mustache\\'"  . web-mode))
(add-to-list 'auto-mode-alist '("\\.djhtml\\'"    . web-mode))

(add-to-list 'auto-mode-alist '("\\.html?\\'"     . web-mode))

(add-to-list 'auto-mode-alist '("\\.css\\'"       . web-mode))
(add-to-list 'auto-mode-alist '("\\.js\\'"        . web-mode))
