(define-module (maxipassat services ci)
  #:use-module (ice-9 ports)
  #:use-module (gnu)
  #:use-module (gnu services databases)
  #:use-module (gnu services shepherd)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages gawk)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages package-management)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages emacs-xyz)
  #:use-module (gnu packages emacs-build)
  #:use-module (guix records)
  #:use-module (guix modules)
  #:use-module (maxipassat packages emacs-xyz)
  #:use-module (maxipassat packages ocaml)
  #:export (maxipassat-ci-service-type
            maxipassat-ci-configuration
            make-maxipassat-ci-configuration
            maxipassat-ci-configuration?
            maxipassat-ci-deployment-name
            maxipassat-ci-base-path
            maxipassat-ci-notify
            maxipassat-ci-port
            maxipassat-ci-db-user
            maxipassat-ci-db-port
            maxipassat-ci-db-host
            maxipassat-ci-db-pass
            maxipassat-ci-db-name
            maxipassat-ci-org-www-relative-path
            maxipassat-ci-org-repo-origin
            maxipassat-ci-maxipassat-repo-origin))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; config

(define-record-type* <maxipassat-ci-configuration>
  maxipassat-ci-configuration make-maxipassat-ci-configuration
  maxipassat-ci-configuration?
  (deployment-name maxipassat-ci-deployment-name (default "staging"))
  (base-path maxipassat-ci-base-path (default #f)) ;; you need to set this
  (notify maxipassat-ci-notify (default (lambda (title status) #~#t)))
  (port maxipassat-ci-port (default 8080))
  (db-user maxipassat-ci-db-user (default "www"))
  (db-port maxipassat-ci-db-port (default 5432))
  (db-host maxipassat-ci-db-host (default "localhost"))
  (db-pass maxipassat-ci-db-pass (default ""))
  (db-name maxipassat-ci-db-name (default "maxipassat"))
  (org-www-relative-path maxipassat-ci-org-www-relative-path (default "roam-dir"))
  (org-repo-origin maxipassat-ci-org-repo-origin (default #f))
  (maxipassat-repo-origin maxipassat-ci-maxipassat-repo-origin (default #f)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; paths helper

(define (make-paths base-path)
  (let* ((ci-path (string-append base-path "/ci"))
         (git-path ci-path)
         (db-path (string-append base-path "/db"))
         (org-repo-path (string-append git-path "/org"))
         (mp-repo-path (string-append git-path "/maxipassat"))
         (emacs-update-db-job-path (string-append org-repo-path "/.ci/update-db.el")) ;; could be anywhere
         (run-path (string-append base-path "/run"))
         (guix-prof-root-path (string-append ci-path "/gp"))
         (guix-prof-path (string-append guix-prof-root-path "/guix-profile"))
         ;; keeping this as a profile and not an guix shell so you can rollback to previous versions:
         (mp-prof-path (string-append guix-prof-root-path "/mp-profile"))
         (mp-channel-path (string-append guix-prof-root-path "/mp-channel.scm")))
    (lambda (s)
      (assoc-ref
       `((ci                  . ,ci-path)
         (git                 . ,git-path)
         (db                  . ,db-path)
         (org-repo            . ,org-repo-path)
         (mp-repo             . ,mp-repo-path)
         (emacs-update-db-job . ,emacs-update-db-job-path)
         (run                 . ,run-path)
         (guix-prof-root      . ,guix-prof-root-path)
         (guix-prof           . ,guix-prof-path)
         (mp-prof             . ,mp-prof-path)
         (mp-channel          . ,mp-channel-path))
       s))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; job helpers

(define (make-mp-channel mp-repo-path) ;; used to guix pull & build on each git push
  #~(list (channel
            (name 'mp)
            (url #$mp-repo-path)
            (branch "master"))
          (channel
            (name 'guix)
            (url "https://codeberg.org/guix/guix")
            (branch "master")
            (introduction
             (make-channel-introduction
              "9edb3f66fd807b096b48283debdcddccfea34bad"
              (openpgp-fingerprint
               "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA"))))))

(define (update-mp-guix-build-cmds chan-path paths)
  #~(begin
      (invoke
       "/run/current-system/profile/bin/guix"
       "pull" "--allow-downgrades" "-p" #$(paths 'guix-prof) "-C" #$chan-path)
      (invoke
       (string-append #$(paths 'guix-prof) "/bin/guix")
       "install" "-p" #$(paths 'mp-prof) "maxipassat")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; files: job hooks

(define maxipassat-ci-files-service
  (match-record-lambda <maxipassat-ci-configuration>
      (base-path deployment-name db-name db-user db-pass db-port db-host notify
                 org-www-relative-path)

    (define paths (make-paths base-path))

    (define mp-channel (make-mp-channel (paths 'mp-repo))) ;; during init will be orig

    (define update-mp-job
      (with-imported-modules
          '((guix build utils))
        #~(begin
            (use-modules (ice-9 ports)
                         (guix build utils))
            #$(notify "mp-update" (string-append deployment-name ": started"))
            #$(update-mp-guix-build-cmds (paths 'mp-channel) paths)
            #$(notify "mp-update" (string-append deployment-name ": done"))
            (let ((port (open-file (string-append #$(paths 'run)
                                                  "/local/var/run/maxipassat-cmd")
                                   "w")))
              (display "maxipassat:kys\n" port)
              (close-port port)))))

    (define update-db-job
      (with-imported-modules
          '((guix build utils)
            (ice-9 ports))
        (let ((packages '("git-minimal" "findutils" "postgresql"
                          "emacs-minimal" "emacs-org-sql" "emacs-org-ml"
                          "emacs-dash" "emacs-s" "emacs-f")))
          #~(begin
              (use-modules (ice-9 ports)
                           (guix build utils))
              (display "yes, new db update file") ;; FIXME
              #$(notify "db-update" (string-append deployment-name ": started"))
              (unsetenv "GIT_DIR")
              (chdir "../working-org")
              (invoke
               (string-append #$(paths 'guix-prof) "/bin/guix") "shell" #$@packages
               "--" "git" "pull" "--force")
              (mkdir-p ".ci/filtered")
              (if (string= "staging" #$deployment-name)
                  (copy-recursively #$org-www-relative-path
                                    (string-append ".ci/filtered/" #$org-www-relative-path))
                  (invoke
                   #$(file-append findutils "/bin/find")
                   #$org-www-relative-path "-name" "*.org" "-exec"
                   #$(file-append filter-org "/bin/filter_org") "{}" ".ci/filtered/{}" ";"))
              (chdir ".ci/filtered/")
              (invoke
               (string-append #$(paths 'guix-prof) "/bin/guix") "shell" #$@packages
               "--" "emacs" "-Q" "--script" #$(paths 'emacs-update-db-job))
              (chdir "../..")
              (delete-file-recursively ".ci/filtered")
              #$(notify "db-update" (string-append deployment-name ": done"))
              (let ((port (open-file (string-append #$(paths 'run)
                                                    "/local/var/run/maxipassat-cmd")
                                     "w")))
                (display "maxipassat:preprocess_org\n" port)
                (close-port port))))))

    (define emacs-update-db-job
      (scheme-file
       "update-db.el"
       #~(progn
          (require 'org-sql)

          (defun org-sql--disk-get-hashpathpairs ()
            "Get a list of hashpathpair for org files on disk.
Each hashpathpair will have it's :db-path set to nil. Only files in
`org-sql-files' will be considered."
            (cl-flet
             ((get-md5
               (fp)
               (org-sql--on-success (org-sql--run-command "md5sum" (list fp) nil)
                                    (car (s-split-up-to " " it-out 1))
                                    (error "Could not get md5"))))
             ;; This is why I'm redefining this: -> I want the relative path, so bypassing expand:
             (if (stringp org-sql-files)
                 (error "`org-sql-files' must be a list of paths")
                 (--map (cons (get-md5 it) it) org-sql-files))))

          ;; (org-sql-user-init) -> you'll need to run that once first time you're creating your db

          (setq org-sql-db-config '(postgres
                                    :hostname #$db-host
                                    :port     #$db-port
                                    :username #$db-user
                                    :schema   "org"
                                    :database #$db-name))

          (setq org-base-path #$org-www-relative-path)

          (setq org-sql-files (split-string
                               (shell-command-to-string
                                (concat "find " org-base-path " -name '*.org'"))
                               "\n" t))

          (org-sql-user-push))))

    `((,(string-append (paths 'mp-repo) "/hooks/post-receive")
       ,(program-file "mp_post-receive" update-mp-job))
      (,(string-append (paths 'org-repo) "/hooks/post-receive")
       ,(program-file "org_post-receive" update-db-job))
      (,(paths 'emacs-update-db-job)
       ,emacs-update-db-job)
      (,(paths 'mp-channel)
       ,(scheme-file "mp-channel.scm" mp-channel)))))

(define maxipassat-init-ci-files-service
  (match-record-lambda <maxipassat-ci-configuration>
      (base-path maxipassat-repo-origin org-repo-origin)

    (define paths (make-paths base-path))

    (define init-path (string-append base-path "/init"))
    (define init-chan-path (string-append init-path "/init-chan.scm"))
    (define init-channel (make-mp-channel (paths 'mp-repo)))

    (define init-job
      (with-imported-modules '((guix build utils))
        #~(begin
            (use-modules (guix build utils))
            (display "hello!\n")
            (when (not (directory-exists? #$(paths 'guix-prof)))
              (display "making paths!\n")
              (mkdir-p #$(paths 'ci))
              (mkdir-p #$(paths 'guix-prof-root))
              (mkdir-p #$(string-append base-path "/static")) ;; unused for now
              (mkdir-p (string-append #$(paths 'run) "/local/var/run"))
              (mkdir-p (string-append #$(paths 'run) "/local/var/log/maxipassat"))
              (display "git repos init!\n")
              (invoke "git" "clone" "--bare"
                      #$maxipassat-repo-origin #$(paths 'mp-repo))
              (invoke "git" "clone" "--bare"
                      #$org-repo-origin #$(paths 'org-repo))
              (invoke "git" "clone"
                      #$(paths 'org-repo)
                      (string-append #$(paths 'org-repo) "/../working-org"))
              (chdir (string-append #$(paths 'org-repo) "/../working-org"))
              (invoke "git" "config" "pull.rebase" "true")
              (display "guix profile build!\n")
              (invoke "guix" "pull" "-p" #$(paths 'guix-prof) "-C" #$init-chan-path)
              #$(update-mp-guix-build-cmds init-chan-path paths))
            #t)))

    `((,(string-append base-path "/init/init-ci")
       ,(program-file "init-ci" init-job))
      (,init-chan-path
       ,(scheme-file "tmp-channel.scm" init-channel)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; db services

(define-public maxipassat-ci-postgresql-service
  (match-record-lambda <maxipassat-ci-configuration>
      (base-path db-port)
    (define paths (make-paths base-path))
    (service postgresql-service-type
             (postgresql-configuration
               (postgresql postgresql)
               (port db-port)
               (data-directory (paths 'db))
               (config-file
                (postgresql-config-file
                  (log-destination "stderr")
                  (hba-file
                   (plain-file "pg_hba.conf"
                               "\
local	all	all			trust
host	all	all	127.0.0.1/32	trust
#host	all	all	192.168.1.7/32	trust
#host	all	all	10.42.0.1/32	trust"))
                  (extra-config
                   '(("listen_addresses" "*")
                     ("log_directory"    "/var/log/postgresql")))))))))

(define-public maxipassat-ci-postgresql-role
  (match-record-lambda <maxipassat-ci-configuration>
      (db-user)
    (list (postgresql-role
            (name db-user)
            (create-database? #t))
          (postgresql-role
            (name "wonko")
            (create-database? #t)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; run maxipassat in shepherd service:

(define-public maxipassat-ci-shepherd-service
  (match-record-lambda <maxipassat-ci-configuration>
      (base-path port db-name db-user db-pass db-port)
    (define paths (make-paths base-path))
    (list
     (shepherd-service
       (provision '(maxipassat-ownership))
       (requirement '(user-processes networking))
       (documentation "init ownership")
       (one-shot? #t)
       (start (with-imported-modules
                  '((guix build utils))
                #~(lambda _
                    (use-modules (guix build utils))
                    (let* ((users-gid (group:gid (getgrnam "users")))
                           (dbuser    (getpw "postgres"))
                           (mpuser    (getpw "www")))
                      (for-each (lambda (path)
                                  (chown path (passwd:uid mpuser) users-gid))
                                (find-files #$(paths 'run) #:directories? #t))
                      (for-each (lambda (path)
                                  (chown path (passwd:uid dbuser) (passwd:gid dbuser)))
                                (find-files #$(paths 'db) #:directories? #t)))))))

     (shepherd-service
       (provision '(maxipassat))
       (requirement '(user-processes networking maxipassat-ownership))
       (documentation "maxipassat")
       ;; (respawn-delay 1)
       (respawn-limit #~'(5000 . 1))
       (start #~(make-forkexec-constructor
                 (list (string-append #$(paths 'mp-prof) "/bin/maxipassat"))
                 #:user #$db-user
                 #:group "users"
                 #:environment-variables (cons*
                                          (string-append "PORT="
                                                         #$(number->string port))
                                          (string-append "DBPORT="
                                                         #$(number->string db-port))
                                          (string-append "DBUSER=" #$db-user)
                                          (default-environment-variables))
                 #:directory #$(paths 'run)))
       (stop #~(make-kill-destructor))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; maxipassat service types:

(define-public maxipassat-ci-service-type
  (service-type
    (name 'maxipassat-ci)
    (default-value (maxipassat-ci-configuration))
    (extensions
     (list
      (service-extension postgresql-role-service-type
                         maxipassat-ci-postgresql-role)
      (service-extension shepherd-root-service-type
                         maxipassat-ci-shepherd-service)
      (service-extension special-files-service-type
                         maxipassat-ci-files-service)))
    (description "maxipassat ci")))

(define-public maxipassat-init-ci-service-type
  (service-type
    (name 'maxipassat-ci)
    (default-value (maxipassat-ci-configuration))
    (extensions
     (list
      (service-extension postgresql-role-service-type
                         maxipassat-ci-postgresql-role)
      (service-extension special-files-service-type
                         maxipassat-init-ci-files-service)))
    (description "init maxipassat ci")))
