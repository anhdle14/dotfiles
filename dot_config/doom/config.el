(setq user-full-name "Le Anh Duc"
      user-login-name "anhdle14"
      user-mail-address "anhdle14@icloud.com")

(setq auth-sources '("~/.authinfo.gpg")
      auth-source-cache-expiry nil)

(setq default-tab-width 2)

(setq-default delete-by-moving-to-trash t) ; delete files to trash

(setq undo-limit 80000000            ; Raise undo-limit to 80Mb
      evil-want-fine-undo t          ; By default while in insert all changes are done in big blob. Be more granular
      auto-save-default t            ; Just auto-save because of auto-forget
      truncate-string-ellipsis "..." ; Unicode ellipsis are nicer than "...", and also save /precious/ space
      password-cache-expiry nil      ; I can trust my computers
      scroll-margin 2)
; Enable time in the mode-line
(display-time-mode 1)

; Iterate through CamelCase words
(global-subword-mode 1)

(setq doom-theme 'doom-gruvbox)

(setq display-line-numbers-type t)

(setq doom-font (font-spec :family "Iosevka" :size 14)
      doom-big-font (font-spec :family "Iosevka" :size 24)
      doom-variable-pitch-font (font-spec :family "Iosevka" :size 18)
      doom-unicode-font (font-spec :family "Iosevka")
      doom-serif-font (font-spec :family "Iosevka" :weight 'light))

(setq org-directory "~/Developer/github.com/anhdle14/org")
