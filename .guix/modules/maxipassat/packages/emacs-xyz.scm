(define-module (maxipassat packages emacs-xyz)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix i18n)
  #:use-module (guix utils)
  #:use-module (guix build-system emacs)
  #:use-module (gnu packages)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages emacs-build)
  #:use-module (gnu packages emacs-xyz)
  #:use-module (guix utils)
  #:use-module (srfi srfi-1)
  #:use-module (ice-9 match))

;; ci deps:

(define-public emacs-org-ml
  (package
    (name "emacs-org-ml")
    (version "5.8.8")
    (source
     (origin
       (method git-fetch)
       (uri
        (git-reference
          (url "https://github.com/ndwarshuis/org-ml")
          (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "16j03fdikha5hwg8ifj0shsn4prbgf7dsggy3ksidpl63w3g05h4"))))
    (inputs
     (list emacs-s
           emacs-dash))
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (delete 'check))))
    (build-system emacs-build-system)
    (home-page "https://github.com/ndwarshuis/org-ml")
    (synopsis "A functional API for org-mode")
    (description "A functional API for org-mode")
    (license (@ (guix licenses) gpl3+))))

(define-public emacs-org-sql
  (package
    (name "emacs-org-sql")
    (version "3.0.4")
    (source
     (origin
       (method git-fetch)
       (uri
        (git-reference
          (url "https://github.com/wonko7/org-sql")
          (commit "777fde3c3f96d626280c7202323f145467491c22")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1qzmcv3vxrdhxx6qzwmrh4xbjw5xgghz1ddv4jdawlnqkwsmn5dl"))))
    (inputs
     (list emacs-f
           emacs-s
           emacs-dash
           emacs-org-ml))
    (build-system emacs-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (delete 'check))))
    (home-page "https://github.com/ndwarshuis/org-sql")
    (synopsis "converts org-mode files to Structured Query Language")
    (description "converts org-mode files to Structured Query Language")
    (license (@ (guix licenses) gpl3+))))
