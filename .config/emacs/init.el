;;; init.el --- Personal Emacs configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Elpaca manages packages; the local Vague theme supplies colors.

;;; Code:

(add-to-list 'custom-theme-load-path (expand-file-name "themes/" user-emacs-directory))
(load-theme 'vague t)
(set-face-attribute 'default nil :family "JetBrainsMono Nerd Font" :height 120)

;; Watch the source directory: atomic renders replace the symlink's referent.
(require 'filenotify)
(defvar dotfiles-theme-watch nil)
(when dotfiles-theme-watch
  (file-notify-rm-watch dotfiles-theme-watch))
(let ((directory (file-name-directory
                  (file-truename (expand-file-name "themes/vague-theme.el"
                                                   user-emacs-directory)))))
  (setq dotfiles-theme-watch
        (file-notify-add-watch directory '(change)
          (lambda (_event) (load-theme 'vague t)))))

;; Upstream Elpaca installer. Downloads Elpaca on first startup.
(defvar elpaca-installer-version 0.12)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-sources-directory (expand-file-name "sources/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1 :inherit ignore
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca-activate)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-sources-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil)) (load "./elpaca-autoloads"))))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

;; Enable :ensure support and wait so declarations below can use it immediately.
(elpaca elpaca-use-package
  (elpaca-use-package-mode))
(elpaca-wait)

(use-package emacs
  :custom
  (menu-bar-mode nil)
  (tool-bar-mode nil)
  (scroll-bar-mode nil)

  (delete-selection-mode t)
  (electric-indent-mode nil)
  (electric-pair-mode t)

  (ring-bell-function 'ignore)

  (blink-cursor-mode nil)
  (global-auto-revert-mode t)

  (global-display-line-numbers-mode t)

  (mouse-wheel-progressive-speed nil)
  (scroll-conservatively 10)

  (tab-width 2)

  (auto-save-default nil)
  (make-backup-files nil)

  :hook (prog-mode . (lambda () (hs-minor-mode t)))
  :config
  (setq custom-file (locate-user-emacs-file "custom.el"))
  (load custom-file :no-error-if-file-is-missing)

  (setq backup-directory-alist '(("." . "~/.emacs.d/backup")))
  (setq backup-by-copying-when-linked t)
  (setq backup-by-copying             t) ; Backup by copying rather renaming
  
  :bind (([escape] . keyboard-escape-quit) ;; Makes Escape quit prompts (Minibuffer Escape)
         ;; Zooming In/Out
         ("C-+" . text-scale-increase)
         ("C--" . text-scale-decrease)
         ("<C-wheel-up>" . text-scale-increase)
         ("<C-wheel-down>" . text-scale-decrease))
  )

;; Load each project's direnv environment into its Emacs buffers.
(use-package envrc
  :ensure t
  :hook (after-init . envrc-global-mode))

;;; status line
(use-package doom-modeline
	:ensure t
  :custom
  (doom-modeline-height 25) ;; Set modeline height
  :hook (after-init . doom-modeline-mode))

;;; nerd-icons
(use-package nerd-icons
	:ensure t
  :if (display-graphic-p))

(use-package dired-sidebar
	:ensure t
	:bind (("C-x C-n" . dired-sidebar-toggle-sidebar))
	:commands (dired-sidebar-toggle-sidebar)
	:init
	(add-hook 'dired-sidebar-mode-hook
            (lambda ()
              (unless (file-remote-p default-directory)
                (auto-revert-mode))))
  :config
  (push 'toggle-window-split dired-sidebar-toggle-hidden-commands)
  (push 'rotate-windows dired-sidebar-toggle-hidden-commands)

  (setq dired-sidebar-subtree-line-prefix "__")
  (setq dired-sidebar-use-term-integration t)
  (setq dired-sidebar-use-custom-font t)
	)

;;; eglot
(use-package eglot
  :ensure nil
  :hook (c-mode . eglot-ensure)
	(c++-mode . eglot-ensure)
	(java-mode . eglot-ensure)
	(js-ts-mode . eglot-ensure)
	(tsx-ts-mode . eglot-ensure)
	(typescript-mode . eglot-ensure)
	(cmake-ts-mode . eglot-ensure)
  (eglot-events-buffer-size 0)
  (eglot-autoshutdown t)
  (eglot-report-progress nil))

;;; treesitter (automatically installs treesitter grammars)
(use-package treesit-auto
	:ensure t
  :custom
  (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))

;;; magit
(use-package magit
	:ensure t
  :defer
  :custom (magit-diff-refine-hunk (quote all)) ;; Shows inline diff
  :config (define-key transient-map (kbd "<escape>") 'transient-quit-one) ;; Make escape quit magit prompts
  )

;;; corfu
(use-package corfu
	:ensure t
  ;; Optional customizations
  :custom
  (corfu-cycle t)                ;; Enable cycling for `corfu-next/previous'
  (corfu-auto t)                 ;; Enable auto completion
  (corfu-auto-prefix 2)          ;; Minimum length of prefix for auto completion.
  (corfu-popupinfo-mode t)       ;; Enable popup information
  (corfu-popupinfo-delay 0.5)    ;; Lower popup info delay to 0.5 seconds from 2 seconds
  (corfu-separator ?\s)          ;; Orderless field separator, Use M-SPC to enter separator
  ;; (corfu-quit-at-boundary nil)   ;; Never quit at completion boundary
  ;; (corfu-quit-no-match nil)      ;; Never quit, even if there is no match
  ;; (corfu-preview-current nil)    ;; Disable current candidate preview
  ;; (corfu-preselect 'prompt)      ;; Preselect the prompt
  ;; (corfu-on-exact-match nil)     ;; Configure handling of exact matches
  ;; (corfu-scroll-margin 5)        ;; Use scroll margin
  (completion-ignore-case t)

  ;; Emacs 30 and newer: Disable Ispell completion function.
  ;; Try `cape-dict' as an alternative.
  (text-mode-ispell-word-completion nil)

  ;; Enable indentation+completion using the TAB key.
  ;; `completion-at-point' is often bound to M-TAB.
  (tab-always-indent 'complete)

  (corfu-preview-current nil) ;; Don't insert completion without confirmation
  ;; Recommended: Enable Corfu globally.  This is recommended since Dabbrev can
  ;; be used globally (M-/).  See also the customization variable
  ;; `global-corfu-modes' to exclude certain modes.
  :init
  (global-corfu-mode))
(use-package nerd-icons-corfu
	:ensure t
  :after corfu
  :init (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

(use-package cape
	:ensure t
  :after corfu
  :init
  ;; Add to the global default value of `completion-at-point-functions' which is
  ;; used by `completion-at-point'.  The order of the functions matters, the
  ;; first function returning a result wins.  Note that the list of buffer-local
  ;; completion functions takes precedence over the global list.

  ;; The functions that are added later will be the first in the list
  (add-hook 'completion-at-point-functions #'cape-dabbrev) ;; Complete word from current buffers
  (add-hook 'completion-at-point-functions #'cape-dict) ;; Dictionary completion
  (add-hook 'completion-at-point-functions #'cape-file) ;; Path completion
  (add-hook 'completion-at-point-functions #'cape-elisp-block) ;; Complete elisp in Org or Markdown mode
  (add-hook 'completion-at-point-functions #'cape-keyword) ;; Keyword completion

  ;;(add-hook 'completion-at-point-functions #'cape-abbrev) ;; Complete abbreviation
  ;;(add-hook 'completion-at-point-functions #'cape-history) ;; Complete from Eshell, Comint or minibuffer history
  ;;(add-hook 'completion-at-point-functions #'cape-line) ;; Complete entire line from current buffer
  (add-hook 'completion-at-point-functions #'cape-elisp-symbol) ;; Complete Elisp symbol
  ;;(add-hook 'completion-at-point-functions #'cape-tex) ;; Complete Unicode char from TeX command, e.g. \hbar
  ;;(add-hook 'completion-at-point-functions #'cape-sgml) ;; Complete Unicode char from SGML entity, e.g., &alpha
  ;;(add-hook 'completion-at-point-functions #'cape-rfc1345) ;; Complete Unicode char using RFC 1345 mnemonics
  )

;;; orderless
(use-package orderless
	:ensure t 
  :config
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion))))
  (completion-category-defaults nil)
  (completion-pcm-leading-wildcard t))

;;; vertico
(use-package vertico
	:ensure t
  :custom (vertico-cycle t)
  :init (vertico-mode 1))

;;; marginalia
(use-package marginalia :ensure t :init (marginalia-mode 1))

;;; consult
(use-package consult
	:ensure t
  :defer t
  :init (advice-add #'register-preview :override #'consult-register-window)
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref))

;;; embark
(use-package embark :ensure t :defer t)

;;; embark-consult
(use-package embark-consult
  :ensure t
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

;;; REPL's and other Lisp stuff
(use-package paredit
	:ensure t
	:hook
	(enable-paredit-mode . emacs-lisp-mode)
	(enable-paredit-mode . eval-expression-minibuffer-setup)
	(enable-paredit-mode . ielm-mode)
	(enable-paredit-mode . lisp-mode)
	(enable-paredit-mode . lisp-interaction-mode)
	(enable-paredit-mode . scheme-mode))

(use-package sly :ensure t) ; Common Lisp

;;; init.el ends here
