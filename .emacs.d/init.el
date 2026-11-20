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
(add-to-list 'custom-theme-load-path "~/.emacs.d/themes/")
(load-theme 'bianco-nero t)

;;; User interface
(menu-bar-mode  1)                         ; Disables menu bar
(tool-bar-mode -1)                        ; Disables toolbar
(tab-bar-mode  -1)                         ; Disables tabs
;; se avvio emacs come server+client la barra non si vede finche non faccio
;; ev-b non capisco perché
;; con runemacs funziona normale
(horizontal-scroll-bar-mode 1)            ; Enables horizontal scroll bar
(setq inhibit-startup-screen t)           ; Disables startup screen
(setq initial-scratch-message nil)        ; Disables scrach message
(show-paren-mode -1)                      ; Disable parentheses highlighting
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
(set-face-attribute 'whitespace-line nil
                    :inherit 'default
                    :foreground 'unspecified
                    :background 'unspecified
                    :inverse-video t)

;;; Behavior
(setq make-backup-files nil)               ; Disables backup files
(setq revert-without-query '(".*"))        ; Please leave me alone
(setq-default truncate-lines t)            ; Disables word wrap
(delete-selection-mode 1)                  ; Replaces selected text when pasting

;; Disables cursor blinking when selecting a region of text
(add-hook 'activate-mark-hook   (lambda () (setq-local cursor-type nil)))
(add-hook 'deactivate-mark-hook (lambda () (kill-local-variable 'cursor-type)))

;; Removes trailing whitespaces
(add-hook 'before-save-hook 'delete-trailing-whitespace)

;; Failed or unsatisfactory attempts at starting the editor zoomed in by 1 (+1)
;;(text-scale-set 1)
;;(set-face-attribute 'default nil :height 120)
;;(set-face-attribute 'default nil :font "Courier New-10")
;;(set-face-attribute 'default nil :font "Courier New-12")

;; https://emacs.stackexchange.com/questions/77667/emacs-starts-in-extremely-tiny-window
;;(add-to-list 'default-frame-alist '(fullscreen . maximized))
;;(add-to-list 'default-frame-alist '(width . 80))  ; Width set to 80 characters
;;(add-to-list 'default-frame-alist '(height . 24)) ; Height set to 24 lines

;; Mouse wheel while dragging a selection: scrolls the window and extends the
;; selection to the text now under the pointer, without ending the drag.
;; By default the wheel isn't part of the drag-tracking keymap, so it ends the
;; tracking and deactivates the mark until the button is released.
(defun my-drag-wheel-scroll (event)
  (interactive "e")
  ;; Inside the drag, transient-mark-mode is '(only ...), which makes
  ;; mwheel-scroll deactivate the region; bind it to t just for this call
  (let ((transient-mark-mode t))
    (mwheel-scroll event))
  ;; The pointer hasn't moved but the text under it has: moves point there
  (let* ((posn (event-start event))
         (window (posn-window posn))
         (xy (posn-x-y posn)))
    (when (and xy (window-live-p window) (eq window (selected-window)))
      (let ((end (posn-point (posn-at-x-y (car xy) (cdr xy) window))))
        (when (integer-or-marker-p end)
          (goto-char end))))))

(defun my-drag-add-wheel-keys (orig-fn map &rest args)
  (when (eq track-mouse 'drag-tracking)
    (dolist (prefix '("" "double-" "triple-"))
      (dolist (dir '("up" "down"))
        (define-key map (vector (intern (concat prefix "wheel-" dir)))
                    #'my-drag-wheel-scroll))))
  (apply orig-fn map args))

(advice-add 'set-transient-map :around #'my-drag-add-wheel-keys)

;; Indentation and tab
;; https://pement.org/emacs_tabs.htm
;; http://blog.lujun9972.win/emacs-document/blog/2018/08/17/the-ultimate-guide-to-indentation-in-emacs-(tabs-and-spaces)/

;; Shifts every line touched by the region by AMOUNT columns, keeping the
;; selection active so TAB / S-TAB can be pressed multiple times
(defun my-shift-region-lines (amount)
  (let ((end (copy-marker (region-end))))
    (save-excursion
      (goto-char (region-beginning))
      (beginning-of-line)
      (while (< (point) end)
        ;; Blank lines are left alone
        (unless (looking-at-p "[ \t]*$")
          (indent-line-to (max 0 (+ (current-indentation) amount))))
        (forward-line 1)))
    (set-marker end nil))
  ;; Prevents Emacs from deactivating the region after the command
  (setq deactivate-mark nil))

;; TAB: indents the region by one level, or acts as tab-to-tab-stop
(defun my-tab ()
  (interactive)
  (if (use-region-p)
      (my-shift-region-lines tab-width)
    (call-interactively 'tab-to-tab-stop)))

;; S-TAB: dedents the region (or the current line) by one level
(defun my-backtab ()
  (interactive)
  (if (use-region-p)
      (my-shift-region-lines (- tab-width))
    (save-excursion
      (indent-line-to (max 0 (- (current-indentation) tab-width))))))

(global-set-key (kbd "TAB")       #'my-tab)
(global-set-key (kbd "<backtab>") #'my-backtab)

;; Major modes (python, web-mode...) bind TAB and <backtab> locally and would
;; win over the global bindings. This minor mode keymap takes precedence over
;; them, but only while a region is active (and never in the minibuffer).
(defun my-region-key-filter (cmd)
  (when (and (use-region-p) (not (minibufferp))) cmd))

(defvar my-indent-mode-map
  (let ((map (make-sparse-keymap)))
    (dolist (key '("TAB" "<tab>"))
      (define-key map (kbd key)
                  `(menu-item "" my-tab :filter ,#'my-region-key-filter)))
    (define-key map (kbd "<backtab>")
                `(menu-item "" my-backtab :filter ,#'my-region-key-filter))
    map))

(define-minor-mode my-indent-mode
  "Region indentation with TAB / S-TAB, overriding major mode bindings."
  :global t
  :keymap my-indent-mode-map)

(my-indent-mode 1)

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

;;; UTF-8 / encoding
(set-language-environment "UTF-8")
(prefer-coding-system 'utf-8)
(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(setq locale-coding-system 'utf-8)
(setq-default buffer-file-coding-system 'utf-8-unix)

;; Clipboard: su Windows deve essere UTF-16, sugli altri sistemi UTF-8
(if (eq system-type 'windows-nt)
    (progn
      (set-selection-coding-system 'utf-16le-dos)
      (set-clipboard-coding-system 'utf-16le-dos))
  (progn
    (set-selection-coding-system 'utf-8)
    (set-clipboard-coding-system 'utf-8)
    (setq x-select-request-type '(UTF8_STRING COMPOUND_TEXT TEXT STRING))))

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
  (setq-local tab-width my-python-indent)
  (setq-local python-indent-guess-indent-offset nil)
  (setq-local indent-tabs-mode nil))

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

;; Multiple cursors shortcuts
(global-set-key (kbd "C-S-c C-S-c") 'mc/edit-lines)
(global-set-key (kbd "C->")         'mc/mark-next-like-this)
(global-set-key (kbd "C-<")         'mc/mark-previous-like-this)
(global-set-key (kbd "C-c C-<")     'mc/mark-all-like-this)

;;; Web mode
(unless (package-installed-p 'web-mode)
  (package-refresh-contents)
  (package-install 'web-mode))

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
