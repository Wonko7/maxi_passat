(define-module (maxipassat systems ci)
  #:use-module (gnu)
  #:use-module (gnu system file-systems)
  #:use-module (gnu bootloader)
  #:use-module (gnu bootloader grub)
  #:use-module (gnu services base)
  #:use-module (gnu services web)
  #:use-module (gnu services certbot)
  #:use-module (guix gexp)
  #:use-module (maxipassat services ci))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; example/usage: this is how I deploy these.
;;
;; you can mkdir -p the base-path and run these, you should probably
;; adapt this to your specs.
;;
;; the init-ci is a helper to make the expected file structure with
;; repos & guix profiles in the correct place.
;; couldn't run guix commands inside the container, this is why you need
;; do run these manually.
;; btw, hooks are setup from inside the container but run from your user's
;; account on git push.
;;
;; staging-init.scm returns mp-staging-init-ci-os
;; staging.scm returns mp-staging-ci-os
;;
;; init:
;;
;; sudo $(guix system container --network --share=/data/www/maxipassat/staging  staging-init.scm)
;; /data/www/maxipassat/staging/init/init-ci
;; <init db FIXME will provide an example>
;; <kill that container>
;;
;; enjoy your ci:
;;
;; sudo $(guix system container --network --share=/data/www/maxipassat/staging staging.scm)

(define users (cons* (user-account
                       (name "www")
                       (uid 1101) ;; because I like having predictable uids.
                       (group "users"))
                     %base-user-accounts))

(define-public (maxipassat-ci-os config init?)
  (operating-system
    (host-name (string-append (maxipassat-ci-deployment-name config) ".maxipass.at"))
    (timezone "Europe/Paris")
    (users users)
    (file-systems %base-file-systems)
    (bootloader (bootloader-configuration (bootloader grub-bootloader)))
    (services (cons*
               (maxipassat-ci-postgresql-service config)
               (if init?
                   (service maxipassat-init-ci-service-type config)
                   (service maxipassat-ci-service-type config))
               %base-services))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; example/usage: in systems ci.scm

(define-public mp-staging-config
  (maxipassat-ci-configuration
   (deployment-name "staging")
   (base-path "/data/www/maxipassat/staging")
   ;; minimal service config, using defaults for staging:
   (db-user "www")
   ;; dir from which the DB will be fed:
   (org-www-relative-path "here-be-dragons")
   ;; where to clone the dev repos from, used for init:
   (org-repo-origin "yggdrasill.local:/data/org")
   (maxipassat-repo-origin "yggdrasill.local:/code/maxipassat/maxipassat")
   ;; I want to know when the jobs are done on my local machine:
   (notify (lambda (title status)
             #~(system (string-append "ssh yggdrasill.local DISPLAY=:9 dunstify "
                                      "\"'" #$title "'\" \"'" #$status "'\""))))))

(define-public mp-staging-ci-os (maxipassat-ci-os mp-staging-config #f))
(define-public mp-staging-init-ci-os (maxipassat-ci-os mp-staging-config #t))

(define-public mp-preprod-config
  (maxipassat-ci-configuration
   (inherit mp-staging-config)
   (deployment-name "preprod")
   (base-path "/data/www/maxipassat/preprod")
   ;; service config:
   ;; my deployments run on the same machine in different containers that share
   ;; the machine's network so I have to specify non-conflicting listen ports:
   (db-port 6942)
   (port 8069)))

(define-public mp-preprod-ci-os (maxipassat-ci-os mp-preprod-config #f))
(define-public mp-preprod-init-ci-os (maxipassat-ci-os mp-preprod-config #t))
