(define-module (maxipassat)
  #:use-module (guix)
  #:use-module (guix gexp)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system dune)
  #:use-module (guix build-system ocaml)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages bdw-gc)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages flex)
  #:use-module (gnu packages gdb)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages gperf)
  #:use-module (gnu packages libffi)
  #:use-module (gnu packages libunistring)
  #:use-module (gnu packages libevent)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages ocaml)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages llvm)
  #:use-module (gnu packages node)
  #:use-module (gnu packages m4)
  #:use-module (gnu packages multiprecision)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages readline)
  #:use-module (gnu packages tex)
  #:use-module (gnu packages texinfo)
  #:use-module (gnu packages unicode)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages web))

(define-public dune-bootstrap-17
  (package
    (name "dune")
    (version "3.17.0")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/ocaml/dune")
                    (commit version)))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "07id6bw4fmwaf7q5f6rpmcqryg5lr5z8ijbp3ifwq40gzxig067j"))))
    (build-system ocaml-build-system)
    (arguments
     `(#:tests? #f; require odoc
       #:make-flags ,#~(list "release"
                             (string-append "PREFIX=" #$output)
                             (string-append "LIBDIR=" #$output
                                            "/lib/ocaml/site-lib"))
       #:phases
       (modify-phases %standard-phases
         (replace 'configure
           (lambda* (#:key outputs #:allow-other-keys)
             (mkdir-p "src/dune")
             (invoke "./configure")
             #t)))))
    (home-page "https://github.com/ocaml/dune")
    (synopsis "OCaml build system")
    (description "Dune is a build system for OCaml.  It provides a consistent
experience and takes care of the low-level details of OCaml compilation.
Descriptions of projects, libraries and executables are provided in
@file{dune} files following an s-expression syntax.")
    (properties '((hidden? . #t)))
    (license license:expat)))

(define-public ocaml4.09-dune-bootstrap-17
  (package-with-ocaml4.09 dune-bootstrap-17))

(define-public ocaml5.0-dune-bootstrap-17
  (package-with-ocaml5.0 dune-bootstrap-17))

(define-public dune-configurator-17
  (package
    (inherit dune-bootstrap-17)
    (name "dune-configurator")
    (build-system dune-build-system)
    (arguments
     `(#:package "dune-configurator"
       #:dune ,dune-bootstrap-17
                                        ; require ppx_expect
       #:tests? #f
       #:phases
       (modify-phases %standard-phases
         ;; When building dune, these directories are normally removed after
         ;; the bootstrap.
         (add-before 'build 'remove-vendor
           (lambda _
             (delete-file-recursively "vendor/csexp")
             (delete-file-recursively "vendor/pp"))))))
    (propagated-inputs
     (list ocaml-csexp))
    (properties `((ocaml4.09-variant . ,(delay ocaml4.09-dune-configurator-17))
                  (ocaml5.0-variant . ,(delay ocaml5.0-dune-configurator-17))))
    (synopsis "Dune helper library for gathering system configuration")
    (description "Dune-configurator is a small library that helps writing
OCaml scripts that test features available on the system, in order to generate
config.h files for instance.  Among other things, dune-configurator allows one to:

@itemize
@item test if a C program compiles
@item query pkg-config
@item import #define from OCaml header files
@item generate config.h file
@end itemize")))


;; BEGIN redefined as is from guix's ocaml, needed to avoid conflict slot
(define-public ocaml-bos
  (package
    (name "ocaml-bos")
    (version "0.2.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://erratique.ch/software/bos/releases/"
                                  "bos-" version ".tbz"))
              (sha256
               (base32
                "0dwg7lpaq30rvwc5z1gij36fn9xavvpah1bj8ph9gmhhddw2xmnq"))))
    (build-system ocaml-build-system)
    (arguments
     `(#:tests? #f
       #:build-flags (list "build")
       #:phases
       (modify-phases %standard-phases
         (delete 'configure))))
    (native-inputs
     (list ocamlbuild opam-installer))
    (propagated-inputs
     `(("topkg" ,ocaml-topkg)
       ("astring" ,ocaml-astring)
       ("fmt" ,ocaml-fmt)
       ("fpath" ,ocaml-fpath)
       ("logs" ,ocaml-logs)
       ("rresult" ,ocaml-rresult)))
    (home-page "https://erratique.ch/software/bos")
    (synopsis "Basic OS interaction for OCaml")
    (description "Bos provides support for basic and robust interaction with
the operating system in OCaml.  It has functions to access the process
environment, parse command line arguments, interact with the file system and
run command line programs.")
    (license license:isc)))

(define-public ocaml-ptime
  (package
    (name "ocaml-ptime")
    ;; TODO 1.1.0 has some issues, so for now we are stuck with 0.8.5
    (version "0.8.5")
    (source (origin
              (method url-fetch)
              (uri
               "https://erratique.ch/software/ptime/releases/ptime-0.8.5.tbz")
              (sha256
               (base32
                "1fxq57xy1ajzfdnvv5zfm7ap2nf49znw5f9gbi4kb9vds942ij27"))))
    (build-system ocaml-build-system)
    (arguments
     `(#:build-flags (list "build" "--with-js_of_ocaml" "true" "--tests"
                           "true")
       #:phases (modify-phases %standard-phases
                  (delete 'configure))))
    (propagated-inputs (list ocaml-result ocaml-js-of-ocaml))
    (native-inputs (list ocaml-findlib ocamlbuild ocaml-topkg opam-installer))
    (home-page "https://erratique.ch/software/ptime")
    (synopsis "POSIX time for OCaml")
    (description
     "Ptime offers platform independent POSIX time support in pure OCaml.  It
provides a type to represent a well-defined range of POSIX timestamps with
picosecond precision, conversion with date-time values, conversion with RFC
3339 timestamps and pretty printing to a human-readable, locale-independent
representation.")
    (license license:isc)))
;; END redefined as is from guix's ocaml, needed to avoid conflict slot

(define-public ocaml-re
  (package
    (name "ocaml-re")
    (version "1.12.0")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/ocaml/ocaml-re/releases/download/1.12.0/re-1.12.0.tbz")
       (sha256
        (base32 "1m6ipbd4si87l3axc6m4qmmvzh9mbriyglyqmfmz9hkj5zr2n7x0"))))
    (build-system dune-build-system)
    (propagated-inputs (list ocaml-seq))
    (native-inputs (list ocaml-ounit2))
    (home-page "https://github.com/ocaml/ocaml-re")
    (synopsis "RE is a regular expression library for OCaml")
    (description
     "Pure OCaml regular expressions with: * Perl-style regular expressions (module
Re.Perl) * Posix extended regular expressions (module Re.Posix) * Emacs-style
regular expressions (module Re.Emacs) * Shell-style file globbing (module
Re.Glob) * Compatibility layer for OCaml's built-in Str module (module Re.Str).")
    (license license:lgpl2.1+)))

(define-public ocaml-alcotest ;; redefine with our ocaml-re
  (package
    (name "ocaml-alcotest")
    (version "1.7.0")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/mirage/alcotest")
                    (commit version)))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0v01vciihd12r30pc4dai70s15p38gy990b4842sn16pvl0ab1az"))))
    (build-system dune-build-system)
    (arguments
     `(#:package "alcotest"
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'fix-test-format
           (lambda _
             ;; cmdliner changed the format and the tests fail
             (substitute* "test/e2e/alcotest/failing/unknown_option.expected"
               (("`") "'")
               (("\\.\\.\\.") "…")))))))
    (native-inputs
     (list ocamlbuild))
    (propagated-inputs
     (list ocaml-astring
           ocaml-cmdliner
           ocaml-fmt
           ocaml-re
           ocaml-stdlib-shims
           ocaml-uuidm
           ocaml-uutf))
    (home-page "https://github.com/mirage/alcotest")
    (synopsis "Lightweight OCaml test framework")
    (description "Alcotest exposes simple interface to perform unit tests.  It
exposes a simple TESTABLE module type, a check function to assert test
predicates and a run function to perform a list of unit -> unit test callbacks.
Alcotest provides a quiet and colorful output where only faulty runs are fully
displayed at the end of the run (with the full logs ready to inspect), with a
simple (yet expressive) query language to select the tests to run.")
    (license license:isc)))

(define-public ocaml-lwt
  (package
    (name "ocaml-lwt")
    (version "5.9.0")
    (source
     (origin
       (method url-fetch)
       (uri "https://github.com/ocsigen/lwt/archive/refs/tags/5.9.0.tar.gz")
       (sha256
        (base32 "1p9fc6kkjb0dh1c1lrvf929l342hpmkr0rp66kfxb4scwzs10ws2"))))
    (build-system dune-build-system)
    (arguments
     `(#:package "lwt"))
    (propagated-inputs (list ocaml-odoc dune-configurator
                             ocaml-ocplib-endian))
    (native-inputs (list ocaml-cppo))
    (home-page "https://github.com/ocsigen/lwt")
    (synopsis "Promises and event-driven I/O")
    (description
     "This package provides a promise is a value that may become determined in the
future.  Lwt provides typed, composable promises.  Promises that are resolved by
I/O are resolved by Lwt in parallel.  Meanwhile, OCaml code, including code
creating and waiting on promises, runs in a single thread by default.  This
reduces the need for locks or other synchronization primitives.  Code can be run
in parallel on an opt-in basis.")
    (license license:expat)))

;; redefine here to depend on our updated ocaml-lwt
(define-public ocaml-lwt-log
  (package
    (name "ocaml-lwt-log")
    (version "1.1.2")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/aantron/lwt_log")
                    (commit version)))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0mbv5l9gj09jd1c4lr2axcl4v043ipmhjd9xrk27l4hylzfc6d1q"))))
    (build-system dune-build-system)
    (arguments
     `(#:tests? #f)); require lwt_ppx
    (propagated-inputs
     `(("lwt" ,ocaml-lwt)))
    (properties `((upstream-name . "lwt_log")))
    (home-page "https://github.com/aantron/lwt_log")
    (synopsis "Logging library")
    (description "This package provides a deprecated logging component for
ocaml lwt.")
    (license license:lgpl2.1)))

;; redefine here to depend on our updated ocaml-lwt
(define-public ocaml-lwt-react
  (package
    (inherit ocaml-lwt)
    (name "ocaml-lwt-react")
    (version "1.2.0")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/ocsigen/lwt")
                    ;; Version from opam
                    (commit "5.6.0")))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "12sglfwdx4anfslj437g7gxchklgzfvba6i4p478kmqr56j2xd0c"))))
    (arguments
     `(#:package "lwt_react"))
    (properties `((upstream-name . "lwt_react")))
    (propagated-inputs
     (list ocaml-lwt ocaml-react))))

(define-public ocaml-logs
  (package
    (name "ocaml-logs")
    (version "0.7.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://erratique.ch/software/logs/releases/"
                                  "logs-" version ".tbz"))
              (sha256
               (base32
                "1jnmd675wmsmdwyb5mx5b0ac66g4c6gpv5s4mrx2j6pb0wla1x46"))))
    (build-system ocaml-build-system)
    (arguments
     `(#:tests? #f
       #:build-flags (list "build" "--with-js_of_ocaml" "false")
       #:phases
       (modify-phases %standard-phases
         (delete 'configure))))
    (native-inputs
     (list ocamlbuild opam-installer))
    (propagated-inputs
     `(("fmt" ,ocaml-fmt)
       ("lwt" ,ocaml-lwt)
       ("mtime" ,ocaml-mtime)
       ("result" ,ocaml-result)
       ("cmdliner" ,ocaml-cmdliner)
       ("topkg" ,ocaml-topkg)))
    (home-page "https://erratique.ch/software/logs")
    (synopsis "Logging infrastructure for OCaml")
    (description "Logs provides a logging infrastructure for OCaml.  Logging is
performed on sources whose reporting level can be set independently.  Log
message report is decoupled from logging and is handled by a reporter.")
    (license license:isc)))

(define-public ocaml-tyxml
  (package
    (name "ocaml-tyxml")
    (version "4.6.0")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/ocsigen/tyxml/releases/download/4.6.0/tyxml-4.6.0.tbz")
       (sha256
        (base32 "1p82r68lxk6wzxihzd620a6kzp27vn548j2cr970l4jfdcy6gsxz"))))
    (build-system dune-build-system)
    (arguments `(#:package "tyxml"))
    (propagated-inputs (list ocaml-re ocaml-seq ocaml-uutf ocaml-odoc))
    (native-inputs
     (list ocaml-alcotest))
    (home-page "https://github.com/ocsigen/tyxml/")
    (synopsis "TyXML is a library for building correct HTML and SVG documents")
    (description "TyXML provides a set of convenient combinators that uses the
OCaml type system to ensure the validity of the generated documents.  TyXML can
be used with any representation of HTML and SVG: the textual one, provided
directly by this package, or DOM trees (@code{js_of_ocaml-tyxml}) virtual DOM
(@code{virtual-dom}) and reactive or replicated trees (@code{eliom}).  You can
also create your own representation and use it to instantiate a new set of
combinators.")
    (license license:lgpl2.1)))

(define-public ocaml-xml-light
  (package
    (name "ocaml-xml-light")
    (version "2.5")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/ncannasse/xml-light/releases/download/2.5/xml-light-2.5.tbz")
       (sha256
        (base32 "0g809vjd2ry4rncwb4mvvaavpk425zinlc0d1c4bml8anwyjp37m"))))
    (build-system dune-build-system)
    (home-page "https://github.com/ncannasse/xml-light")
    (synopsis "Xml-Light is a minimal XML parser & printer for OCaml")
    (description
     "It provide functions to parse an XML document into an OCaml data structure, work
with it, and print it back to an XML document.  It support also DTD parsing and
checking, and is entirely written in OCaml, hence it does not require additional
C library.")
    (license license:lgpl2.1+)))

(define-public ocaml-resource-pooling
  (package
    (name "ocaml-resource-pooling")
    (version "1.2")
    (source
     (origin
       (method url-fetch)
       (uri "https://github.com/ocsigen/resource-pooling/archive/1.2.tar.gz")
       (sha256
        (base32 "0z9ik320ip8xhpklwq8q1cfrvf2frc9n37zfc575bzkil3vm76md"))))
    (build-system dune-build-system)
    (propagated-inputs (list ocaml-lwt ocaml-lwt-log))
    (home-page "https://github.com/ocsigen/resource-pooling")
    (synopsis
     "Library for pooling resources like connections, threads, or similar")
    (description
     "This package is derived from the module Lwt_pool from the lwt package, which
implements resource pooling.  With Resource_pool this package provides a
modified version with additional features.  Also there is a module called
Server_pool that manages resource clusters, specifically a cluster of servers
each with its own connection pool.")
    (license license:expat)))

(define-public ocaml-ocsigen-ppx-rpc
  (package
    (name "ocaml-ocsigen-ppx-rpc")
    (version "1.0")
    (source
     (origin
       (method url-fetch)
       (uri "https://github.com/ocsigen/ocsigen-ppx-rpc/archive/1.0.tar.gz")
       (sha256
        (base32 "0wmdj1szpnfx8jh07cxwknmzdnwzhdyjpmvvcscrd7bbgyh0pv0j"))))
    (build-system dune-build-system)
    (propagated-inputs (list ocaml-ppxlib))
    (home-page "https://github.com/ocsigen/ocsigen-ppx-rpc/")
    (synopsis "This PPX adds a syntax for RPCs for Eliom and Ocsigen Start")
    (description #f)
    (license license:lgpl2.1)))

(define-public ocaml-ocsigen-toolkit
  (package
    (name "ocaml-ocsigen-toolkit")
    (version "4.1.0")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/ocsigen/ocsigen-toolkit/archive/refs/tags/4.1.0.tar.gz")
       (sha256
        (base32 "1gan4qbcd8vsw5ibfh6fm4v8m6jkalickdvig2s2v6g7jjg5xnp8"))))
    (build-system ocaml-build-system)
    (arguments
     (list
      #:tests? #f
      #:phases #~(modify-phases %standard-phases
                   (add-after 'prepare-install 'mkdir
                     (lambda*  (#:key outputs #:allow-other-keys)
                       (let* ((out (assoc-ref outputs "out"))
                              (dst (string-append out "/lib/ocaml/site-lib/ocsigen-toolkit")))
                         (mkdir-p (string-append dst "/client"))
                         (mkdir-p (string-append dst "/server"))
                         (substitute* "Makefile"
                           (("`\\$\\(OCAMLFIND\\) query \\$\\(PKG_NAME\\)`") dst)))
                       #t))
                   (add-after 'install 'css
                     (lambda*  (#:key outputs #:allow-other-keys)
                       (let* ((out (assoc-ref outputs "out"))
                              (dst (string-append out "/share/ocsigen-toolkit/css")))
                         (mkdir-p (string-append dst))
                         (copy-recursively "css" dst))
                       #t))
                   (delete 'configure))))
    (propagated-inputs (list ocaml-js-of-ocaml ocaml-eliom ocaml-calendar))
    (home-page "http://www.ocsigen.org")
    (synopsis
     "Reusable UI components for Eliom applications (client only, or client-server)")
    (description
     "The Ocsigen Toolkit is a set of user interface widgets that facilitate the
development of Eliom applications.")
    (license license:lgpl2.1)))

(define-public ocaml-ocsipersist-lib
  (package
    (name "ocaml-ocsipersist-lib")
    (version "2.0.0")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/ocsigen/ocsipersist/archive/refs/tags/2.0.0.tar.gz")
       (sha256
        (base32 "0ppa3y8ldfw0jbi1njk7p3ygssh5hpa63ns4fglmcpdsy151ybvb"))))
    (build-system dune-build-system)
    (arguments
     (list #:package "ocsipersist-lib"))
    (propagated-inputs (list ocaml-lwt ocaml-lwt-ppx))
    (home-page "https://github.com/ocsigen/ocsipersist")
    (synopsis "Persistent key/value storage for OCaml - support library")
    (description
     "This library defines signatures and auxiliary tools for defining backends for
the Ocsipersist frontent.  Ocsipersist is used pervasively in Eliom/Ocsigen to
handle sessions and references.  It can be used as an extension for
ocsigenserver or as a library.  Implementations of the following backends
currently exist: DBM, @code{PostgreSQL}, SQLite.")
    (license license:lgpl2.1)))

(define-public ocaml-ocsipersist
  (package
    (name "ocaml-ocsipersist")
    (version "2.0.0")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/ocsigen/ocsipersist/archive/refs/tags/2.0.0.tar.gz")
       (sha256
        (base32 "0ppa3y8ldfw0jbi1njk7p3ygssh5hpa63ns4fglmcpdsy151ybvb"))))
    (build-system dune-build-system)
    (arguments
     (list #:package "ocsipersist"))
    (propagated-inputs (list ocaml-lwt ocaml-ocsipersist-lib))
    (home-page "https://github.com/ocsigen/ocsipersist")
    (synopsis "Persistent key-value storage for OCaml using multiple backends")
    (description
     "This is an virtual library defining a unified frontend for a number of key-value
storage implementations.  Implementations of the following backends currently
exist: DBM, @code{PostgreSQL}, SQLite.")
    (license license:lgpl2.1)))

(define-public ocaml-ocsipersist-pgsql
  (package
    (name "ocaml-ocsipersist-pgsql")
    (version "2.0.0")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/ocsigen/ocsipersist/archive/refs/tags/2.0.0.tar.gz")
       (sha256
        (base32 "0ppa3y8ldfw0jbi1njk7p3ygssh5hpa63ns4fglmcpdsy151ybvb"))))
    (build-system dune-build-system)
    (arguments
     (list #:package "ocsipersist-pgsql"))
    (propagated-inputs (list ocaml-lwt ocaml-lwt-log ocaml-ocsipersist
                             ocaml-pgocaml))
    (home-page "https://github.com/ocsigen/ocsipersist")
    (synopsis "Persistent key/value storage for OCaml using PostgreSQL")
    (description
     "This library provides a @code{PostgreSQL} backend for the unified key/value
storage frontend as defined in the ocsipersist package.")
    (license license:lgpl2.1)))

(define-public ocaml-ocsipersist-pgsql-config
  (package
    (name "ocaml-ocsipersist-pgsql-config")
    (version "2.0.0")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/ocsigen/ocsipersist/archive/refs/tags/2.0.0.tar.gz")
       (sha256
        (base32 "0ppa3y8ldfw0jbi1njk7p3ygssh5hpa63ns4fglmcpdsy151ybvb"))))
    (build-system dune-build-system)
    (arguments
     (list #:package "ocsipersist-pgsql-config"))
    (propagated-inputs (list ocaml-xml-light ocaml-ocsigenserver
                             ocaml-ocsipersist-pgsql))
    (home-page "https://github.com/ocsigen/ocsipersist")
    (synopsis
     "Ocsigen Server configuration file extension for ocsipersist-pgsql")
    (description
     "Load this package from Ocsigen Server's configuration file if you want to use
the @code{PostgreSQL} storage backend.")
    (license license:lgpl2.1)))

(define-public ocaml-camlzip
  (package
    (name "ocaml-camlzip")
    (version "1.13")
    (source
     (origin
       (method url-fetch)
       (uri "https://github.com/xavierleroy/camlzip/archive/rel113.tar.gz")
       (sha256
        (base32 "17jxasc7sx99mrz1hh960k115adpj9c7pczrvwpxs741mj98c0wa"))))
    (build-system ocaml-build-system)
    (arguments
     (list #:phases #~(modify-phases %standard-phases
                        (delete 'configure))))
    (propagated-inputs (list zlib))
    (native-inputs (list ocaml-findlib))
    (home-page "https://github.com/xavierleroy/camlzip")
    (synopsis "Accessing compressed files in ZIP, GZIP and JAR format")
    (description
     "The Camlzip library provides easy access to compressed files in ZIP and GZIP
format, as well as to Java JAR files.  It provides functions for reading from
and writing to compressed files in these formats.")
    (license license:lgpl2.1+)))

(define-public ocaml-magic-mime
  (package
    (name "ocaml-magic-mime")
    (version "1.3.1")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/mirage/ocaml-magic-mime/releases/download/v1.3.1/magic-mime-1.3.1.tbz")
       (sha256
        (base32 "021vy409qq0gzsn4kzr1lvlsax9dcy3y6mwfqpx1xfjxc81ls8z0"))))
    (build-system dune-build-system)
    (home-page "https://github.com/mirage/ocaml-magic-mime")
    (synopsis "Map filenames to common MIME types")
    (description
     "This library contains a database of MIME types that maps filename extensions
into MIME types suitable for use in many Internet protocols such as HTTP or
e-mail.  It is generated from the `mime.types` file found in Unix systems, but
has no dependency on a filesystem since it includes the contents of the database
as an ML datastructure.  For example, here's how to lookup MIME types in the
[utop] REPL: #require \"magic-mime\";; Magic_mime.lookup \"/foo/bar.txt\";; - :
bytes = \"text/plain\" Magic_mime.lookup \"bar.css\";; - : bytes = \"text/css\".")
    (license license:isc)))

(define-public ocaml-digestif ;; opam
  (package
    (name "ocaml-digestif")
    (version "1.2.0")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/mirage/digestif/releases/download/v1.2.0/digestif-1.2.0.tbz")
       (sha256
        (base32 "0255nb9wjpkdh9v0w9p5y5s79zcqcdg3wsw0cx9nd6i7zv56h0f3"))))
    (build-system dune-build-system)
    (propagated-inputs (list ocaml-eqaf))
    (native-inputs (list ocaml-fmt
                         ocaml-alcotest
                         ocaml-bos
                         ocaml-astring
                         ocaml-fpath
                         ocaml-rresult
                         ocaml-findlib
                         ocaml-crowbar))
    (home-page "https://github.com/mirage/digestif")
    (synopsis "Hashes implementations (SHA*, RIPEMD160, BLAKE2* and MD5)")
    (description
     "Digestif is a toolbox to provide hashes implementations in C and OCaml.  It uses
the linking trick and user can decide at the end to use the C implementation or
the OCaml implementation.  We provides implementation of: * MD5 * SHA1 * SHA224
* SHA256 * SHA384 * SHA512 * SHA3 * Keccak-256 * WHIRLPOOL * BLAKE2B * BLAKE2S *
RIPEMD160.")
    (license license:expat)))

(define-public ocaml-kdf
  (package
    (name "ocaml-kdf")
    (version "1.0.0")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/robur-coop/kdf/releases/download/v1.0.0/kdf-1.0.0.tbz")
       (sha256
        (base32 "1kp0cbn3v0l7rzb7g0r1rra697wf0qhrr33bvmcdjrpy1qmmhqfi"))))
    (build-system dune-build-system)
    (arguments
     (list #:package "kdf"))
    (propagated-inputs (list ocaml-digestif ocaml-mirage-crypto))
    (native-inputs (list ocaml-alcotest ocaml-ohex))
    (home-page "https://github.com/robur-coop/kdf")
    (synopsis
     "Key Derivation Functions: HKDF RFC 5869, PBKDF RFC 2898, SCRYPT RFC 7914")
    (description
     "This package provides a pure OCaml implementation of
[scrypt](https://tools.ietf.org/html/rfc7914), [PBKDF 1 and 2 as defined by
PKCS#5](https://tools.ietf.org/html/rfc2898), and
[HKDF](https://tools.ietf.org/html/rfc5869).")
    (license license:bsd-2)))

(define-public ocaml-gmap
  (package
    (name "ocaml-gmap")
    (version "0.3.0")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/hannesm/gmap/releases/download/0.3.0/gmap-0.3.0.tbz")
       (sha256
        (base32 "073wa0lrb0jj706j87cwzf1a8d1ff14100mnrjs8z3xc4ri9xp84"))))
    (build-system dune-build-system)
    (native-inputs (list ocaml-alcotest ocaml-fmt))
    (home-page "https://github.com/hannesm/gmap")
    (synopsis "Heterogenous maps over a GADT")
    (description
     "Gmap exposes the functor `Make` which takes a key type (a
[GADT](https://en.wikipedia.org/wiki/Generalized_algebraic_data_type) a key) and
outputs a type-safe Map where each a key is associated with a a value.  This
removes the need for additional packing.  It uses OCaml's stdlib
[Map](http://caml.inria.fr/pub/docs/manual-ocaml/libref/Map.html) data
structure.")
    (license license:isc)))

(define-public ocaml-mirage-crypto-ec
  (package
    (name "ocaml-mirage-crypto-ec")
    (version "1.2.0")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/mirage/mirage-crypto/releases/download/v1.2.0/mirage-crypto-1.2.0.tbz")
       (sha256
        (base32 "0zp60zp101mcygwhsh62jj61sy61yh2k31d8kgznily1jv6jnm09"))))
    (build-system dune-build-system)
    (arguments
     (list #:package "mirage-crypto-ec"))
    (propagated-inputs (list dune-configurator ocaml-eqaf
                             ocaml-mirage-crypto-rng ocaml-digestif))
    (native-inputs (list ocaml-alcotest
                         ocaml-ppx-deriving-yojson
                         ocaml-ppx-deriving
                         ocaml-yojson
                         ocaml-asn1-combinators
                         ocaml-ohex
                         ocaml-ounit2))
    (home-page "https://github.com/mirage/mirage-crypto")
    (synopsis "Elliptic Curve Cryptography with primitives taken from Fiat")
    (description
     "An implementation of key exchange (ECDH) and digital signature
(ECDSA/@code{EdDSA}) algorithms using code from Fiat
(<https://github.com/mit-plv/fiat-crypto>).  The curves P256 (SECP256R1), P384
(SECP384R1), P521 (SECP521R1), and 25519 (X25519, Ed25519) are implemented by
this package.")
    (license license:expat)))

(define-public ocaml-mirage-crypto-rng
  (package
    (name "ocaml-mirage-crypto-rng")
    (version "1.2.0")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/mirage/mirage-crypto/releases/download/v1.2.0/mirage-crypto-1.2.0.tbz")
       (sha256
        (base32 "0zp60zp101mcygwhsh62jj61sy61yh2k31d8kgznily1jv6jnm09"))))
    (build-system dune-build-system)
    (arguments
     (list #:package "mirage-crypto-rng")) ;; also -lwt
    (propagated-inputs (list dune-configurator ocaml-duration ocaml-logs
                             ocaml-mirage-crypto ocaml-digestif))
    (native-inputs (list ocaml-ounit2 ocaml-randomconv ocaml-ohex))
    (home-page "https://github.com/mirage/mirage-crypto")
    (synopsis "A cryptographically secure PRNG")
    (description
     "Mirage-crypto-rng provides a random number generator interface, and
implementations: Fortuna, HMAC-DRBG, getrandom/getentropy based (in the unix
sublibrary).")
    (license license:isc)))

(define-public ocaml-randomconv
  (package
    (name "ocaml-randomconv")
    (version "0.2.0")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/hannesm/randomconv/releases/download/v0.2.0/randomconv-0.2.0.tbz")
       (sha256
        (base32 "1sk3bdfz1nlqrivp8vy3slpbhqw858gc5zwjix3a8hg30zgiw5xk"))))
    (build-system dune-build-system)
    (home-page "https://github.com/hannesm/randomconv")
    (synopsis
     "Convert from random byte vectors (int -> string) to random native numbers")
    (description
     "Given a function which produces random byte vectors, convert it to a number of
your choice (int8/int16/int32/int64/int/float).")
    (license license:isc)))

;; (define-public ocaml-zarith
;;   (package
;;     (name "ocaml-zarith")
;;     (version "1.14")
;;     (source
;;      (origin
;;        (method url-fetch)
;;        (uri "https://github.com/ocaml/Zarith/archive/release-1.14.tar.gz")
;;        (sha256
;;         (base32 "0n8q9lnlgq17a62qprkzqswg5wyh8vcan7sq10m98lwijfyxrfax"))))
;;     (build-system ocaml-build-system)
;;     (propagated-inputs (list pkg-config gmp))
;;     (home-page "https://github.com/ocaml/Zarith")
;;     (synopsis
;;      "Implements arithmetic and logical operations over arbitrary-precision integers")
;;     (description
;;      "The Zarith library implements arithmetic and logical operations over
;; arbitrary-precision integers.  It uses GMP to efficiently implement arithmetic
;; over big integers.  Small integers are represented as Caml unboxed integers, for
;; speed and space economy.")
;;     (license license:lgpl2.0)))
(define-public ocaml-zarith
  (package
    (name "ocaml-zarith")
    (version "1.14")
    (source
     (origin
       (method url-fetch)
       (uri "https://github.com/ocaml/Zarith/archive/release-1.14.tar.gz")
       (sha256
        (base32 "0n8q9lnlgq17a62qprkzqswg5wyh8vcan7sq10m98lwijfyxrfax"))))
    (build-system ocaml-build-system)
    (native-inputs
     (list perl))
    (inputs
     (list gmp))
    (arguments
     `(#:tests? #f ; no test target
       #:phases
       (modify-phases %standard-phases
         (replace 'configure
           (lambda _ (invoke "./configure")))
         (add-after 'install 'move-sublibs
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (lib (string-append out "/lib/ocaml/site-lib")))
               (mkdir-p (string-append lib "/stublibs"))
               (rename-file (string-append lib "/zarith/dllzarith.so")
                            (string-append lib "/stublibs/dllzarith.so"))))))))
    (home-page "https://forge.ocamlcore.org/projects/zarith/")
    (synopsis "Implements arbitrary-precision integers")
    (description "Implements arithmetic and logical operations over
arbitrary-precision integers.  It uses GMP to efficiently implement arithmetic
over big integers. Small integers are represented as Caml unboxed integers,
for speed and space economy.")
    (license license:lgpl2.1+)))

(define-public ocaml-mirage-crypto-pk
  (package
    (name "ocaml-mirage-crypto-pk")
    (version "1.2.0")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/mirage/mirage-crypto/releases/download/v1.2.0/mirage-crypto-1.2.0.tbz")
       (sha256
        (base32 "0zp60zp101mcygwhsh62jj61sy61yh2k31d8kgznily1jv6jnm09"))))
    (build-system dune-build-system)
    (arguments
     (list #:package "mirage-crypto-pk"))
    (propagated-inputs (list ocaml-mirage-crypto ocaml-mirage-crypto-rng
                             ocaml-digestif ocaml-zarith ocaml-eqaf))
    ;; (native-inputs (list gmp-powm-sec ocaml-ounit2 ocaml-randomconv ocaml-ohex)) FIXME
    (native-inputs (list gmp ocaml-ounit2 ocaml-randomconv ocaml-ohex))
    (home-page "https://github.com/mirage/mirage-crypto")
    (synopsis "Simple public-key cryptography for the modern age")
    (description
     "Mirage-crypto-pk provides public-key cryptography (RSA, DSA, DH).")
    (license license:isc)))

(define-public ocaml-asn1-combinators
  (package
    (name "ocaml-asn1-combinators")
    (version "0.3.2")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/mirleft/ocaml-asn1-combinators/releases/download/v0.3.2/asn1-combinators-0.3.2.tbz")
       (sha256
        (base32 "0zwa1pxprzq77h5y6j2s7dj14zkmsrdkb14zrlyhf8i7drgrh9ib"))))
    (build-system dune-build-system)
    (propagated-inputs (list ocaml-ptime))
    (native-inputs (list ocaml-alcotest ocaml-ohex))
    (home-page "https://github.com/mirleft/ocaml-asn1-combinators")
    (synopsis "Embed typed ASN.1 grammars in OCaml")
    (description
     "asn1-combinators is a library for expressing ASN.1 in OCaml.  Skip the notation
part of ASN.1, and embed the abstract syntax directly in the language.  These
abstract syntax representations can be used for parsing, serialization, or
random testing.  The only ASN.1 encodings currently supported are BER and DER.")
    (license license:isc)))

(define-public ocaml-x509
  (package
    (name "ocaml-x509")
    (version "1.0.5")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/mirleft/ocaml-x509/releases/download/v1.0.5/x509-1.0.5.tbz")
       (sha256
        (base32 "06r9k862g52jzpf588lmx5mvnf8rikrgqd5gm6i1wlhfwnxrvc7g"))))
    (build-system dune-build-system)
    (propagated-inputs (list ocaml-asn1-combinators
                             ocaml-ptime
                             ocaml-base64
                             ocaml-mirage-crypto
                             ocaml-mirage-crypto-pk
                             ocaml-mirage-crypto-ec
                             ocaml-mirage-crypto-rng
                             ocaml-fmt
                             ocaml-gmap
                             ocaml-domain-name
                             ocaml-logs
                             ocaml-kdf
                             ocaml-ohex
                             ocaml-ipaddr
                             gmp))
    (native-inputs (list ocaml-mirage-crypto-rng ocaml-alcotest))
    (home-page "https://github.com/mirleft/ocaml-x509")
    (synopsis "Public Key Infrastructure (RFC 5280, PKCS) purely in OCaml")
    (description
     "X.509 is a public key infrastructure used mostly on the Internet.  It consists
of certificates which include public keys and identifiers, signed by an
authority.  Authorities must be exchanged over a second channel to establish the
trust relationship.  This library implements most parts of RFC5280 and RFC6125.
The Public Key Cryptography Standards (PKCS) defines encoding and decoding (in
ASN.1 DER and PEM format), which is also implemented by this library - namely
PKCS 1, PKCS 5, PKCS 7, PKCS 8, PKCS 9, PKCS 10, and PKCS 12.")
    (license license:bsd-2)))

(define-public ocaml-ohex
  (package
    (name "ocaml-ohex")
    (version "0.2.0")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/ocaml/opam-source-archives/raw/main/ohex-0.2.0.tar.gz")
       (sha256
        (base32 "1v6qwz6a0anbcjy74bgfinmib4c8wzc64y3b9dvhrc1lpanppdd6"))))
    (build-system dune-build-system)
    (native-inputs (list ocaml-alcotest))
    (home-page "https://git.robur.coop/robur/ohex")
    (synopsis "Hexadecimal encoding and decoding")
    (description
     "This package provides a library to encode and decode hexadecimal byte sequences.")
    (license license:bsd-2)))

(define-public ocaml-mirage-crypto
  (package
    (name "ocaml-mirage-crypto")
    (version "1.2.0")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/mirage/mirage-crypto/releases/download/v1.2.0/mirage-crypto-1.2.0.tbz")
       (sha256
        (base32 "0zp60zp101mcygwhsh62jj61sy61yh2k31d8kgznily1jv6jnm09"))))
    (build-system dune-build-system)
    (arguments
     (list #:package "mirage-crypto"))
    (propagated-inputs (list dune-configurator ocaml-eqaf))
    (native-inputs (list ocaml-ounit2 ocaml-ohex))
    (home-page "https://github.com/mirage/mirage-crypto")
    (synopsis "Simple symmetric cryptography for the modern age")
    (description "Mirage-crypto provides symmetric ciphers (DES, AES, RC4,
@code{ChaCha20/Poly1305}).")
    (license license:isc)))

(define-public ocaml-ca-certs
  (package
    (name "ocaml-ca-certs")
    (version "1.0.0")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/mirage/ca-certs/releases/download/v1.0.0/ca-certs-1.0.0.tbz")
       (sha256
        (base32 "0wha5i3f5dz2l01lh5nl4yq2gdhnxj2bd8fqyaclfwj64cqz5446"))))
    (build-system dune-build-system)
    (arguments
     (list #:tests? #f))
    (propagated-inputs (list ocaml-bos
                             ocaml-fpath
                             ocaml-ptime
                             ocaml-logs
                             ocaml-digestif
                             ocaml-mirage-crypto
                             ocaml-x509
                             ocaml-ohex))
    (native-inputs (list ocaml-alcotest ocaml-fmt))
    (home-page "https://github.com/mirage/ca-certs")
    (synopsis "Detect root CA certificates from the operating system")
    (description
     "TLS requires a set of root anchors (Certificate Authorities) to authenticate
servers.  This library exposes this list so that it can be registered with
ocaml-tls.")
    (license license:isc)))

(define-public ocaml-conduit-lwt
  (package
    (name "ocaml-conduit-lwt")
    (version "7.0.0")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/mirage/ocaml-conduit/releases/download/v7.0.0/conduit-7.0.0.tbz")
       (sha256
        (base32 "060jrfmy3kh59nbfmw0argwj9js6g8p7jdfiv1wd35bai62c43iy"))))
    (build-system dune-build-system)
    (arguments
     (list #:package "conduit-lwt"))
    (propagated-inputs (list ocaml-ppx-sexp-conv ocaml-sexplib0 ocaml-conduit
                             ocaml-lwt))
    (home-page "https://github.com/mirage/ocaml-conduit")
    (synopsis "A portable network connection establishment library using Lwt")
    (description #f)
    (license license:isc)))

(define-public ocaml-conduit-lwt-unix
  (package
    (name "ocaml-conduit-lwt-unix")
    (version "7.0.0")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/mirage/ocaml-conduit/releases/download/v7.0.0/conduit-7.0.0.tbz")
       (sha256
        (base32 "060jrfmy3kh59nbfmw0argwj9js6g8p7jdfiv1wd35bai62c43iy"))))
    (build-system dune-build-system)
    (arguments
     (list #:package "conduit-lwt-unix"
           #:tests? #f)) ;; FIXME feels like a real problem :/
    (propagated-inputs (list ocaml-logs
                             ocaml-ppx-sexp-conv
                             ocaml-conduit-lwt
                             ocaml-lwt
                             ocaml-uri
                             ocaml-ipaddr
                             ocaml-ipaddr-sexp
                             ocaml-ca-certs))
    (native-inputs (list ocaml-lwt-log ocaml-ssl ocaml-lwt-ssl))
    (home-page "https://github.com/mirage/ocaml-conduit")
    (synopsis "A network connection establishment library for Lwt_unix")
    (description #f)
    (license license:isc)))

(define-public ocaml-ipaddr
  (package
    (name "ocaml-ipaddr")
    (version "5.6.0")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/mirage/ocaml-ipaddr/releases/download/v5.6.0/ipaddr-5.6.0.tbz")
       (sha256
        (base32 "0cw1431idd54v067p3mqbxhsgsx5mixl9ywgmak3g92cvczl6c4y"))))
    (build-system dune-build-system)
    (arguments
     (list #:package "ipaddr"))
    (propagated-inputs (list ocaml-macaddr ocaml-domain-name))
    (native-inputs (list ocaml-ounit2 ocaml-ppx-sexp-conv))
    (home-page "https://github.com/mirage/ocaml-ipaddr")
    (synopsis
     "A library for manipulation of IP (and MAC) address representations")
    (description
     "Features: * Depends only on sexplib (conditionalization under consideration) *
ounit2-based tests * IPv4 and IPv6 support * IPv4 and IPv6 CIDR prefix support *
IPv4 and IPv6 [CIDR-scoped
address](http://tools.ietf.org/html/rfc4291#section-2.3) support * `Ipaddr.V4`
and `Ipaddr.V4.Prefix` modules are `Map.@code{OrderedType`} * `Ipaddr.V6` and
`Ipaddr.V6.Prefix` modules are `Map.@code{OrderedType`} * `Ipaddr` and
`Ipaddr.Prefix` modules are `Map.@code{OrderedType`} * `Ipaddr_unix` in findlib
subpackage `ipaddr.unix` provides compatibility with the standard library `Unix`
module * `Ipaddr_top` in findlib subpackage `ipaddr.top` provides top-level
pretty printers (requires compiler-libs default since OCaml 4.0) * IP address
scope classification * IPv4-mapped addresses in IPv6 (::ffff:0:0/96) are an
embedding of IPv4 * MAC-48 (Ethernet) address support * `Macaddr` is a
`Map.@code{OrderedType`} * All types have sexplib serializers/deserializers.")
    (license license:isc)))

(define-public ocaml-ipaddr-cstruct
  (package
    (name "ocaml-ipaddr-cstruct")
    (version "5.6.0")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/mirage/ocaml-ipaddr/releases/download/v5.6.0/ipaddr-5.6.0.tbz")
       (sha256
        (base32 "0cw1431idd54v067p3mqbxhsgsx5mixl9ywgmak3g92cvczl6c4y"))))
    (build-system dune-build-system)
    (arguments
     (list #:package "ipaddr-cstruct"))
    (propagated-inputs (list ocaml-ipaddr ocaml-cstruct))
    (home-page "https://github.com/mirage/ocaml-ipaddr")
    (synopsis
     "A library for manipulation of IP address representations using Cstructs")
    (description "Cstruct convertions for macaddr.")
    (license license:isc)))

(define-public ocaml-ipaddr-sexp
  (package
    (name "ocaml-ipaddr-sexp")
    (version "5.6.0")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/mirage/ocaml-ipaddr/releases/download/v5.6.0/ipaddr-5.6.0.tbz")
       (sha256
        (base32 "0cw1431idd54v067p3mqbxhsgsx5mixl9ywgmak3g92cvczl6c4y"))))
    (build-system dune-build-system)
    (arguments
     (list #:package "ipaddr-sexp"))
    (propagated-inputs (list ocaml-ipaddr ocaml-ppx-sexp-conv ocaml-sexplib0))
    (native-inputs (list ocaml-ipaddr-cstruct ocaml-ounit2))
    (home-page "https://github.com/mirage/ocaml-ipaddr")
    (synopsis
     "A library for manipulation of IP address representations using sexp")
    (description "Sexp convertions for ipaddr.")
    (license license:isc)))

(define-public ocaml-conduit
  (package
    (name "ocaml-conduit")
    (version "7.1.0")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/mirage/ocaml-conduit/releases/download/v7.1.0/conduit-7.1.0.tbz")
       (sha256
        (base32 "1xspxb5v8hb9f1zx7b2cbgrp1s9k68js1373bl10c5z70y523ljq"))))
    (build-system dune-build-system)
    (arguments
     (list #:package "conduit"))
    (propagated-inputs (list ocaml-ppx-sexp-conv
                             ocaml-sexplib0
                             ocaml-astring
                             ocaml-uri
                             ocaml-logs
                             ocaml-ipaddr
                             ocaml-ipaddr-sexp))
    (home-page "https://github.com/mirage/ocaml-conduit")
    (synopsis "A network connection establishment library")
    (description
     "The `conduit` library takes care of establishing and listening for TCP and
SSL/TLS connections for the Lwt and Async libraries.  The reason this library
exists is to provide a degree of abstraction from the precise SSL library used,
since there are a variety of ways to bind to a library (e.g. the C FFI, or the
Ctypes library), as well as well as which library is used (just @code{OpenSSL}
for now).  By default, @code{OpenSSL} is used as the preferred connection
library, but you can force the use of the pure OCaml TLS stack by setting the
environment variable `CONDUIT_TLS=native` when starting your program.  The
useful opam packages available that extend this library are: - `conduit`: the
main `Conduit` module - `conduit-lwt`: the portable Lwt implementation -
`conduit-lwt-unix`: the Lwt/Unix implementation - `conduit-async` the Jane
Street Async implementation - `conduit-mirage`: the @code{MirageOS} compatible
implementation.")
    (license license:isc)))

(define-public ocaml-cohttp
  (package
    (name "ocaml-cohttp")
    (version "5.3.1")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/mirage/ocaml-cohttp/releases/download/v5.3.1/cohttp-5.3.1.tbz")
       (sha256
        (base32 "0sspsj44qhxwhn4j005y80dd0v1x3wzb4vg1sxxz97zjqb9p7qpm"))))
    (build-system dune-build-system)
    (arguments
     `(#:package "cohttp"
       #:tests? #f))
    (propagated-inputs (list ocaml-re
                             ocaml-uri
                             ocaml-uri-sexp
                             ocaml-sexplib0
                             ocaml-ppx-sexp-conv
                             ocaml-stringext
                             ocaml-base64
                             ocaml-fmt
                             ocaml-jsonm
                             ;; ocaml-alcotest
                             ocaml-crowbar))
    (native-inputs (list ocaml-fmt ocaml-alcotest))
    (home-page "https://github.com/mirage/ocaml-cohttp")
    (synopsis "CoHTTP implementation using the Lwt concurrency library")
    (description
     "This is a portable implementation of HTTP that uses the Lwt concurrency library
to multiplex IO. It implements as much of the logic in an OS-independent way as
possible, so that more specialised modules can be tailored for different
targets.  For example, you can install `cohttp-lwt-unix` or `cohttp-lwt-jsoo`
for a Unix or @code{JavaScript} backend, or `cohttp-mirage` for the
@code{MirageOS} unikernel version of the library.  All of these implementations
share the same IO logic from this module.")
    (license license:isc)))

(define-public ocaml-cohttp-lwt
  (package
    (name "ocaml-cohttp-lwt")
    (version "5.3.1")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/mirage/ocaml-cohttp/releases/download/v5.3.1/cohttp-5.3.1.tbz")
       (sha256
        (base32 "0sspsj44qhxwhn4j005y80dd0v1x3wzb4vg1sxxz97zjqb9p7qpm"))))
    (build-system dune-build-system)
    (arguments
     `(#:package "cohttp-lwt"
       #:tests? #f))
    (propagated-inputs (list ;;ocaml-http
                        ocaml-cohttp
                        ocaml-lwt
                        ocaml-sexplib0
                        ocaml-ppx-sexp-conv
                        ocaml-logs
                        ocaml-uri
                        ocaml-odoc))
    (home-page "https://github.com/mirage/ocaml-cohttp")
    (synopsis "CoHTTP implementation using the Lwt concurrency library")
    (description
     "This is a portable implementation of HTTP that uses the Lwt concurrency library
to multiplex IO. It implements as much of the logic in an OS-independent way as
possible, so that more specialised modules can be tailored for different
targets.  For example, you can install `cohttp-lwt-unix` or `cohttp-lwt-jsoo`
for a Unix or @code{JavaScript} backend, or `cohttp-mirage` for the
@code{MirageOS} unikernel version of the library.  All of these implementations
share the same IO logic from this module.")
    (license license:isc)))

(define-public ocaml-cohttp-lwt-unix
  (package
    (name "ocaml-cohttp-lwt-unix")
    (version "5.3.1")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/mirage/ocaml-cohttp/releases/download/v5.3.1/cohttp-5.3.1.tbz")
       (sha256
        (base32 "0sspsj44qhxwhn4j005y80dd0v1x3wzb4vg1sxxz97zjqb9p7qpm"))))
    (build-system dune-build-system)
    (arguments
     `(#:package "cohttp-lwt-unix"
       #:tests? #f))
    (propagated-inputs (list ;;ocaml-http
                        ocaml-cohttp
                        ocaml-cohttp-lwt
                        ocaml-cmdliner
                        ocaml-lwt
                        ocaml-lwt-ssl
                        ocaml-conduit-lwt
                        ocaml-conduit-lwt-unix
                        ocaml-fmt
                        ocaml-ppx-sexp-conv
                        ocaml-magic-mime
                        ocaml-logs
                        ocaml-odoc))
    (native-inputs (list ocaml-ounit))
    (home-page "https://github.com/mirage/ocaml-cohttp")
    (synopsis "CoHTTP implementation for Unix and Windows using Lwt")
    (description
     "An implementation of an HTTP client and server using the Lwt concurrency
library.  See the `Cohttp_lwt_unix` module for information on how to use this.
The package also installs `cohttp-curl-lwt` and a `cohttp-server-lwt` binaries
for quick uses of a HTTP(S) client and server respectively.  Although the name
implies that this only works under Unix, it should also be fine under Windows
too.")
    (license license:isc)))

(define-public ocaml-cryptokit
  (package
    (name "ocaml-cryptokit")
    (version "1.20")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/xavierleroy/cryptokit/archive/release1201.tar.gz")
       (sha256
        (base32 "19nf1wjphnil3yxwmlmbivzswhgj7mc2z74nvmm27rq39qmw6cxr"))))
    (build-system dune-build-system)
    (propagated-inputs (list dune-configurator ocaml-zarith zlib
                             ;; FIXME gmp-powm-sec
                             gmp
                             ))
    (home-page "https://github.com/xavierleroy/cryptokit")
    (synopsis "A library of cryptographic primitives")
    (description
     "Cryptokit includes authenticated encryption (AES-GCM, Chacha20-Poly1305), block
ciphers (AES, DES, 3DES), stream ciphers (Chacha20, ARCfour), public-key
cryptography (RSA, DH), hashes (SHA-256, SHA-512, SHA-3, Blake2, Blake3), MACs,
compression, random number generation -- all presented with a compositional,
extensible interface.")
    (license license:lgpl2.0+)))

(define-public ocaml-lwt-ssl
  (package
    (name "ocaml-lwt-ssl")
    (version "1.2.0")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/ocsigen/lwt_ssl/releases/download/1.2.0/lwt_ssl-1.2.0.tbz")
       (sha256
        (base32 "0xwsi140ahap2d8ncc443ycvmjvdnc40lx7jqghpgwzcgb90l0mk"))))
    (build-system dune-build-system)
    (propagated-inputs (list ocaml-lwt ocaml-ssl))
    (properties `((upstream-name . "lwt_ssl")))
    (home-page "https://github.com/ocsigen/lwt_ssl")
    (synopsis "OpenSSL binding with concurrent I/O")
    (description #f)
    (license license:lgpl2.1))) ;; looked it up on the webpage

(define-public ocaml-ocsigenserver
  (package
    (name "ocaml-ocsigenserver")
    (version "6.0.0")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/ocsigen/ocsigenserver/archive/refs/tags/6.0.0.tar.gz")
       (sha256
        (base32 "061y0rlnlf6awsqx66w8n8k4pzq6ria16hhmydmvjqz9ra72qsa0"))))
    (build-system dune-build-system)
    (arguments
     `(;; #:package "ocsigenserver"
       #:phases ,#~(modify-phases %standard-phases
                     (add-before 'build 'config
                       (lambda* (#:key outputs #:allow-other-keys)
                         (let ((out (assoc-ref outputs "out")))
                           (invoke "./configure"
                                   "--prefix" out
                                   "--ocsigen-user" "wonko"
                                   "--ocsigen-group" "users"
                                   ;; "--commandpipe"
                                   ;; (string-append out "/ocsigenserver/var/run/ocsigenserver_command")
                                   ;; "--logdir"
                                   ;; (string-append out "/var/log/ocsigenserver") ;; FIXME
                                   ;; ;; "%{lib}%/ocsigenserver/var/log/ocsigenserver"
                                   ;; "--mandir"
                                   ;; "%{man}%/man1"
                                   ;; "--docdir"
                                   ;; "%{lib}%/ocsigenserver/share/doc/ocsigenserver"
                                   ;; "--commandpipe"
                                   ;; "%{lib}%/ocsigenserver/var/run/ocsigenserver_command"
                                   ;; "--staticpagesdir"
                                   ;; "%{lib}%/ocsigenserver/var/www"
                                   ;; "--datadir"
                                   ;; "%{lib}%/ocsigenserver/var/lib/ocsigenserver"
                                   ;; "--temproot"
                                   ;; ""
                                   ;; "--sysconfdir"
                                   ;; "%{lib}%/ocsigenserver/etc/ocsigenserver"
                                   )
                           (invoke "make" "-C" "src" "confs"))
                         #t)))))
    (propagated-inputs (list ocaml-react
                             ocaml-ssl
                             ocaml-lwt
                             ocaml-lwt-ssl
                             ocaml-lwt-react
                             ocaml-lwt-log
                             ocaml-re
                             ocaml-cryptokit
                             ocaml-ipaddr
                             ocaml-cohttp-lwt-unix
                             ocaml-conduit-lwt-unix
                             ocaml-xml-light
                             ocaml-camlzip))
    (home-page "http://ocsigen.org/ocsigenserver/")
    (synopsis "A full-featured and extensible Web server")
    (description
     "Ocsigen Server is a Web Server that can be used either as a library for OCaml or
as an executable (taking its configuration from a file).  It has a very powerful
extension mechanism that makes it very easy to plug your own OCaml modules for
generating pages.  Many extensions are already implemented, like a reverse
proxy, content compression, access control, authentication, etc.")
    (license license:lgpl2.1)))

(define-public ocaml-lwt-ppx
  (package
    (name "ocaml-lwt-ppx")
    (version "5.8.0")
    (source
     (origin
       (method url-fetch)
       (uri "https://github.com/ocsigen/lwt/archive/refs/tags/5.8.0.tar.gz")
       (sha256
        (base32 "17dzjiy1smv2791399j6gn2jxa4mkps2vrss231pp9m10lxfkdyi"))))
    (build-system dune-build-system)
    (arguments
     (list #:package "lwt_ppx"
           #:tests? #f)) ;; FIXME oh-uh?
    (propagated-inputs (list ocaml-ppxlib ocaml-lwt))
    (native-inputs (list ocaml-cppo))
    (properties `((upstream-name . "lwt_ppx")))
    (home-page "https://github.com/ocsigen/lwt")
    (synopsis
     "PPX syntax for Lwt, providing something similar to async/await from JavaScript")
    (description #f)
    (license license:expat)))

(define-public ocaml-reactiveData
  (package
    (name "ocaml-reactiveData")
    (version "0.3.0")
    (source
     (origin
       (method url-fetch)
       (uri "https://github.com/ocsigen/reactiveData/archive/0.3.tar.gz")
       (sha256
        (base32 "1xjbzjpihmyi1d324xz1kp1ph38vmik1gdzvznq096w3199gvri9"))))
    (build-system dune-build-system)
    (propagated-inputs (list ocaml-react))
    (home-page "https://github.com/ocsigen/reactiveData")
    (synopsis "Declarative events and signals for OCaml")
    (description
     "React is an OCaml module for functional reactive programming (FRP).  It provides
support to program with time varying values : declarative events and signals.
React doesn't define any primitive event or signal, it lets the client chooses
the concrete timeline.")
    (license license:lgpl3+)))

(define-public ocaml-js-of-ocaml-tyxml
  (package
    (name "ocaml-js-of-ocaml-tyxml")
    (version "5.9.1")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/ocsigen/js_of_ocaml/releases/download/5.9.1/js_of_ocaml-5.9.1.tbz")
       (sha256
        (base32 "01vk3kpa3chn6l5hs8hg8k5knhahxpi3aby8ajd9r3hxhxh5rjb8"))))
    (build-system dune-build-system)
    (arguments
     (list #:package "js_of_ocaml-tyxml"
           ;; #:dune dune-bootstrap-17
           #:tests? #f ;; FIXME
           ))
    (propagated-inputs (list ocaml-js-of-ocaml
                             ocaml-js-of-ocaml-ppx
                             ocaml-react
                             ocaml-reactiveData
                             ocaml-tyxml
                             ocaml-odoc
                             ocaml-uutf))
    (native-inputs (list ocaml-num ocaml-ppx-expect ocaml-ppxlib ocaml-re))
    (properties `((upstream-name . "js_of_ocaml-tyxml")))
    (home-page "https://ocsigen.org/js_of_ocaml/latest/manual/overview")
    (synopsis "Compiler from OCaml bytecode to JavaScript")
    (description
     "Js_of_ocaml is a compiler from OCaml bytecode to @code{JavaScript}.  It makes it
possible to run pure OCaml programs in @code{JavaScript} environment like
browsers and Node.js.")
    (license (list license:gpl2+ license:lgpl2.1+))))

(define-public ocaml-js-of-ocaml-ppx-deriving-json
  (package
    (name "ocaml-js-of-ocaml-ppx-deriving-json")
    (version "5.9.1")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/ocsigen/js_of_ocaml/releases/download/5.9.1/js_of_ocaml-5.9.1.tbz")
       (sha256
        (base32 "01vk3kpa3chn6l5hs8hg8k5knhahxpi3aby8ajd9r3hxhxh5rjb8"))))
    (build-system dune-build-system)
    (arguments
     (list #:package "js_of_ocaml-ppx_deriving_json"
           ;; #:dune dune-bootstrap-17
           #:tests? #f ;; FIXME
           ))
    (propagated-inputs (list ocaml-js-of-ocaml ocaml-ppxlib ocaml-odoc))
    (native-inputs (list ocaml-num ocaml-ppx-expect ocaml-re))
    (properties `((upstream-name . "js_of_ocaml-ppx_deriving_json")))
    (home-page "https://ocsigen.org/js_of_ocaml/latest/manual/overview")
    (synopsis "Compiler from OCaml bytecode to JavaScript")
    (description
     "Js_of_ocaml is a compiler from OCaml bytecode to @code{JavaScript}.  It makes it
possible to run pure OCaml programs in @code{JavaScript} environment like
browsers and Node.js.")
    (license (list license:gpl2+ license:lgpl2.1+))))

(define-public ocaml-js-of-ocaml-ocamlbuild
  (package
    (name "ocaml-js-of-ocaml-ocamlbuild")
    (version "5.0")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/ocsigen/js_of_ocaml-ocamlbuild/releases/download/5.0/js_of_ocaml-ocamlbuild-5.0.tbz")
       (sha256
        (base32 "0yy0l6qfn76ak2hy6h7jw3drszpi3wn8lymp7qmcnyz23jzvqnda"))))
    (build-system dune-build-system)
    (arguments ;; not in version 6:
     (list #:package "js_of_ocaml-ocamlbuild"
           #:tests? #f ;; FIXME
           ))
    (propagated-inputs (list ocamlbuild ocaml-odoc))
    (properties `((upstream-name . "js_of_ocaml-ocamlbuild")))
    (home-page "https://github.com/ocsigen/js_of_ocaml-ocamlbuild")
    (synopsis
     "An ocamlbuild plugin to compile to JavaScript using js_of_ocaml")
    (description
     "An ocamlbuild plugin to compile to @code{JavaScript} using js_of_ocaml.")
    (license (list license:lgpl2.1+))))

(define-public ocaml-js-of-ocaml-ppx
  (package
    (name "ocaml-js-of-ocaml-ppx")
    (version "5.9.1")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/ocsigen/js_of_ocaml/releases/download/5.9.1/js_of_ocaml-5.9.1.tbz")
       (sha256
        (base32 "01vk3kpa3chn6l5hs8hg8k5knhahxpi3aby8ajd9r3hxhxh5rjb8"))))
    (build-system dune-build-system)
    (arguments
     (list #:package "js_of_ocaml-ppx"
           ;; #:dune dune-bootstrap-17
           #:tests? #f ;; FIXME
           ))
    (propagated-inputs (list ocaml-js-of-ocaml ocaml-ppxlib ocaml-odoc))
    (native-inputs (list ocaml-num ocaml-ppx-expect ocaml-re))
    (properties `((upstream-name . "js_of_ocaml-ppx")))
    (home-page "https://ocsigen.org/js_of_ocaml/latest/manual/overview")
    (synopsis "Compiler from OCaml bytecode to JavaScript")
    (description
     "Js_of_ocaml is a compiler from OCaml bytecode to @code{JavaScript}.  It makes it
possible to run pure OCaml programs in @code{JavaScript} environment like
browsers and Node.js.")
    (license (list license:gpl2+ license:lgpl2.1+))))

(define-public ocaml-js-of-ocaml-lwt
  (package
    (name "ocaml-js-of-ocaml-lwt")
    (version "5.9.1")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/ocsigen/js_of_ocaml/releases/download/5.9.1/js_of_ocaml-5.9.1.tbz")
       (sha256
        (base32 "01vk3kpa3chn6l5hs8hg8k5knhahxpi3aby8ajd9r3hxhxh5rjb8"))))
    (build-system dune-build-system)
    (arguments
     (list #:package "js_of_ocaml-lwt"
           ;; #:dune dune-bootstrap-17
           #:tests? #f ;; FIXME
           ))
    (propagated-inputs (list ocaml-js-of-ocaml ocaml-js-of-ocaml-ppx ocaml-lwt
                             ocaml-lwt-log ocaml-odoc))
    (native-inputs (list ocaml-num ocaml-ppx-expect ocaml-ppxlib ocaml-re))
    (properties `((upstream-name . "js_of_ocaml-lwt")))
    (home-page "https://ocsigen.org/js_of_ocaml/latest/manual/overview")
    (synopsis "Compiler from OCaml bytecode to JavaScript")
    (description
     "Js_of_ocaml is a compiler from OCaml bytecode to @code{JavaScript}.  It makes it
possible to run pure OCaml programs in @code{JavaScript} environment like
browsers and Node.js.")
    (license (list license:gpl2+ license:lgpl2.1+))))

(define-public ocaml-js-of-ocaml
  (package
    (name "ocaml-js-of-ocaml")
    (version "5.9.1")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/ocsigen/js_of_ocaml/releases/download/5.9.1/js_of_ocaml-5.9.1.tbz")
       (sha256
        (base32 "01vk3kpa3chn6l5hs8hg8k5knhahxpi3aby8ajd9r3hxhxh5rjb8"))))
    (build-system dune-build-system)
    (arguments
     (list #:package "js_of_ocaml"
           ;; #:dune dune-bootstrap-17
           #:tests? #f ;; FIXME
           ))
    (propagated-inputs (list ocaml-js-of-ocaml-compiler ocaml-ppxlib
                             ocaml-odoc))
    (native-inputs (list ocaml-num ocaml-ppx-expect ocaml-re))
    (properties `((upstream-name . "js_of_ocaml")))
    (home-page "https://ocsigen.org/js_of_ocaml/latest/manual/overview")
    (synopsis "Compiler from OCaml bytecode to JavaScript")
    (description
     "Js_of_ocaml is a compiler from OCaml bytecode to @code{JavaScript}.  It makes it
possible to run pure OCaml programs in @code{JavaScript} environment like
browsers and Node.js.")
    (license (list license:gpl2+ license:lgpl2.1+))))

(define-public ocaml-menhirSdk
  (package
    (name "ocaml-menhirSdk")
    (version "20240715")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://gitlab.inria.fr/fpottier/menhir/-/archive/20240715/archive.tar.gz")
       (sha256
        (base32 "0c60kby2b1zmr0ypqaclakhk3kk4km4qvw7blynzmjxam928cj7g"))))
    (build-system dune-build-system)
    (home-page "http://gitlab.inria.fr/fpottier/menhir")
    (synopsis "Compile-time library for auxiliary tools related to Menhir")
    (description #f)
    (license license:lgpl2.0)))

(define-public ocaml-menhirLib
  (package
    (name "ocaml-menhirLib")
    (version "20240715")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://gitlab.inria.fr/fpottier/menhir/-/archive/20240715/archive.tar.gz")
       (sha256
        (base32 "0c60kby2b1zmr0ypqaclakhk3kk4km4qvw7blynzmjxam928cj7g"))))
    (build-system dune-build-system)
    (home-page "http://gitlab.inria.fr/fpottier/menhir")
    (synopsis "Runtime support library for parsers generated by Menhir")
    (description #f)
    (license license:lgpl2.0)))

(define-public ocaml-sedlex
  (package
    (name "ocaml-sedlex")
    (version "3.3")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/ocaml-community/sedlex/archive/refs/tags/v3.3.tar.gz")
       (sha256
        (base32 "18w8gjjbvzn9ir5c3qzvnj2c7w3rbr3j1hs8h39q865dj0vh2mmh"))))
    (build-system dune-build-system)
    (arguments
     (list #:package "sedlex"
           #:phases
           #~(modify-phases %standard-phases
               (add-before 'build 'copy-resources
                 ;; These three files are needed by src/generator/data/dune,
                 ;; but would be downloaded using curl at build time.
                 (lambda* (#:key inputs #:allow-other-keys)
                   (with-directory-excursion "src/generator/data"
                     ;; Newer versions of dune emit an error if files it wants to
                     ;; build already exist. Delete the dune file so dune doesn't
                     ;; complain.
                     (delete-file "dune")
                     (for-each
                      (lambda (file)
                        (copy-file (search-input-file inputs file)
                                   (basename file)))
                      '("share/ucd/extracted/DerivedGeneralCategory.txt"
                        "share/ucd/DerivedCoreProperties.txt"
                        "share/ucd/PropList.txt")))))
               (add-before 'build 'chmod
                 (lambda _
                   (for-each (lambda (file) (chmod file #o644)) (find-files "." ".*")))))))
    (native-inputs (list ocaml-ppx-expect))
    (propagated-inputs
     (list ocaml-gen ocaml-ppxlib ocaml-uchar))
    (inputs
     (list ucd))
    (home-page "https://www.cduce.org/download.html#side")
    (synopsis "Lexer generator for Unicode and OCaml")
    (description "Lexer generator for Unicode and OCaml.")
    (license license:expat)))

(define-public ocaml-js-of-ocaml-compiler
  (package
    (name "ocaml-js-of-ocaml-compiler")
    (version "5.9.1")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/ocsigen/js_of_ocaml/releases/download/5.9.1/js_of_ocaml-5.9.1.tbz")
       (sha256
        (base32 "01vk3kpa3chn6l5hs8hg8k5knhahxpi3aby8ajd9r3hxhxh5rjb8"))))
    (build-system dune-build-system)
    (arguments
     (list #:package "js_of_ocaml-compiler"
           ;; #:dune dune-bootstrap-17
           #:tests? #f ;; FIXME
           ));; dune-bootstrap-17 dune-configurator-17
    (propagated-inputs (list ocaml-ppxlib
                             ocaml-cmdliner
                             ocaml-sedlex
                             ocaml-menhir
                             ocaml-menhirLib
                             ocaml-menhirSdk
                             ocaml-yojson
                             ocaml-odoc))
    (native-inputs (list ocaml-num ocaml-ppx-expect ocaml-re ocaml-qcheck))
    (properties `((upstream-name . "js_of_ocaml-compiler")))
    (home-page "https://ocsigen.org/js_of_ocaml/latest/manual/overview")
    (synopsis "Compiler from OCaml bytecode to JavaScript")
    (description
     "Js_of_ocaml is a compiler from OCaml bytecode to @code{JavaScript}.  It makes it
possible to run pure OCaml programs in @code{JavaScript} environment like
browsers and Node.js.")
    (license (list license:gpl2+ license:lgpl2.1+))))

(define-public ocaml-eliom
  (package
    (name "ocaml-eliom")
    (version "11.1.1")
    (source
     (origin
       (method url-fetch)
       (uri "https://github.com/ocsigen/eliom/archive/refs/tags/11.1.1.tar.gz")
       (sha256
        (base32 "0kxjxih4madgmgdj4a0i0219i191583vlyzlpgndn3k7l6nsqshs"))))
    (build-system dune-build-system)
    (arguments
     (list #:package "eliom"
           ;; #:dune dune-bootstrap-17
           ))
    (propagated-inputs (list ocaml-ppx-deriving
                             ocaml-ppxlib
                             ocaml-js-of-ocaml-compiler
                             ocaml-js-of-ocaml
                             ocaml-js-of-ocaml-lwt
                             ocaml-js-of-ocaml-ppx
                             ocaml-js-of-ocaml-ppx-deriving-json
                             ocaml-js-of-ocaml-tyxml
                             ocaml-lwt-log
                             ocaml-lwt-ppx
                             ocaml-tyxml
                             ocaml-ocsigenserver
                             ocaml-ipaddr
                             ocaml-reactiveData
                             ocaml-ocsipersist
                             ocaml-ppx-optcomp
                             ocaml-xml-light
                             ocaml-odoc))
    (native-inputs (list ocaml-js-of-ocaml-ocamlbuild))
    (home-page "https://ocsigen.org/eliom/")
    (synopsis "Advanced client/server Web and mobile framework")
    (description
     "Eliom is a framework for implementing Web sites and client/server Web and mobile
applications.  It uses advanced concepts to simplify the implementation of
common behaviors (e.g. scoped sessions, continuation based Web programming ...).
 It uses advanced static typing features of OCaml to check many properties of
the Web application at compile-time (html, page parameters ...).  Eliom allows
implementing the whole application as a single program that includes both the
client and the server code.  For example, you can implement event handlers
(onclick ...) directly in OCaml, and you can call a server-side OCaml function
from the client.  Pages are generated either on the server or the client.  These
client-side features remain compatible with traditional Web programming (links,
forms, URLs, bookmarks, sessions ...).  It is possible to generate mobile
applications for Android and @code{iOS} with the exact same code as your Web
application.  The client-side code is compiled to JS using Ocsigen Js_of_ocaml
or to Wasm using Wasm_of_ocaml.")
    (license license:lgpl2.1)))

(define-public ocaml-ocsigen-i18n
  (package
    (name "ocaml-ocsigen-i18n")
    (version "4.0.0")
    (source
     (origin
       (method url-fetch)
       (uri "https://github.com/besport/ocsigen-i18n/archive/4.0.0.tar.gz")
       (sha256
        (base32 "12vbqaz0zxwkk1la0w9i25w86749w7896ris84blwia575yc9x2p"))))
    (build-system dune-build-system)
    (propagated-inputs (list ocaml-ppxlib))
    (home-page "https://github.com/besport/ocsigen-i18n")
    (synopsis "I18n made easy for web sites written with eliom")
    (description
     "This package provides executables: ocsigen-i18n-generator for generating an
eliom file from a file containing tab-separated values; ocsigen-i18n-rewriter
for implementing a PPX syntax for referencing entries in the generated eliom
file.")
    (license license:lgpl2.1+)))

(define-public ocaml-safepass
  (package
    (name "ocaml-safepass")
    (version "3.1")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/darioteixeira/ocaml-safepass/archive/v3.1.tar.gz")
       (sha256
        (base32 "04ahndliia0cd291b9dp68a7zzjxby0gx249yagfmzhjv9880h0k"))))
    (build-system dune-build-system)
    (home-page "https://github.com/darioteixeira/ocaml-safepass")
    (synopsis "Facilities for the safe storage of user passwords")
    (description #f)
    (license license:lgpl2.1)))

(define-public ocaml-pgocaml
  (package
    (name "ocaml-pgocaml")
    (version "4.4.0")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/darioteixeira/pgocaml/archive/refs/tags/v4.4.0.tar.gz")
       (sha256
        (base32 "0cg2n5wp391d51pprd2piz29dvgfhs3yrbk80w9fwb3xsf5vmahg"))))
    (build-system dune-build-system)
    (arguments `(#:tests? #f)) ;; FIXME needs running pg db.
    (native-inputs (list ocaml-ounit))
    (propagated-inputs (list ocaml-calendar
                             ocaml-camlp-streams
                             ocaml-csv
                             ocaml-hex
                             ocaml-ppx-optcomp
                             ocaml-ppx-sexp-conv
                             ocaml-ppx-deriving
                             ocaml-re
                             ocaml-rresult
                             ocaml-sexplib))
    (home-page "https://github.com/darioteixeira/pgocaml")
    (synopsis "Native OCaml interface to PostgreSQL databases")
    (description
     "PGOCaml provides an interface to @code{PostgreSQL} databases for OCaml
applications.  Note that it speaks the @code{PostgreSQL} wire protocol directly,
and therefore does not need to create bindings to the @code{PostgreSQL} libpq C
library.  The PPX syntax extension is now packaged separately as pgocaml_ppx'.
You will want to take a look at it if you're considering using PGOCaml.")
    (license license:lgpl2.0)))

(define-public ocaml-pgocaml-ppx
  (package
    (name "ocaml-pgocaml-ppx")
    (version "4.4.0")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/darioteixeira/pgocaml/archive/refs/tags/v4.4.0.tar.gz")
       (sha256
        (base32 "0cg2n5wp391d51pprd2piz29dvgfhs3yrbk80w9fwb3xsf5vmahg"))))
    (build-system dune-build-system)
    (arguments `(#:tests? #f)) ;; FIXME needs running pg db.
    (native-inputs (list ocaml-ounit))
    (propagated-inputs (list ocaml-pgocaml ocaml-ppxlib ocaml-ppx-optcomp))
    (properties `((upstream-name . "pgocaml_ppx")))
    (home-page "https://github.com/darioteixeira/pgocaml")
    (synopsis "PPX extension for PGOCaml")
    (description
     "PGOCaml provides an interface to @code{PostgreSQL} databases for OCaml
applications.  This PPX syntax extension enables one to directly embed SQL
statements inside the OCaml code.  The extension uses the describe feature of
@code{PostgreSQL} to obtain type information about the database.  This allows
PGOCaml to check at compile-time if the program is indeed consistent with the
database structure.")
    (license license:lgpl2.0)))

(define-public ocaml-ocsigen-start
  (package
    (name "ocaml-ocsigen-start")
    (version "7.1.0")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://github.com/ocsigen/ocsigen-start/archive/refs/tags/7.1.0.tar.gz")
       (sha256
        (base32 "1jibnf5zkzrxzladgyp92cqbkhqb7m0kzw38n0rkllpg8chwyyk5"))))
    (build-system ocaml-build-system)
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'prepare-install 'mkdir
            (lambda* (#:key outputs #:allow-other-keys)
              ;; FIXME upgrade.sql is generated by us if we have a running pg db 💀
              (let* ((out (assoc-ref outputs "out"))
                     (dst (string-append out "/lib/ocaml/site-lib/eliom/templates")))
                ;; ocsigen-toolkit css dir:
                ;; can't hardcode #$ocaml-ocsigen-toolkit path because this should work
                ;; on none guix machines. also, wouldn't survive update + gc.
                (substitute* "template.distillery/Makefile.options"
                  (("^SHAREDIR              := .*")
                   "SHAREDIR := $(shell ocamlfind query ocsigen-toolkit | sed -re 's:^(.*)/lib/.*:\\1/share:')"))
                ;; install script destination dir:
                (mkdir-p dst)
                (substitute* "scripts/install.sh"
                  (("DEST0=\\$DESTDIR/\\$\\(eliom-distillery -dir\\)")
                   (string-append "DEST0=" dst))))
              #t))
          (delete 'configure))))
    (propagated-inputs (list ocaml-pgocaml
                             ocaml-pgocaml-ppx
                             ocaml-safepass
                             ocaml-ocsigen-i18n
                             ocaml-eliom
                             ocaml-ocsigen-toolkit
                             ocaml-ocsigen-ppx-rpc
                             ocaml-ocsigen-i18n
                             ocaml-yojson
                             ocaml-resource-pooling
                             ocaml-cohttp-lwt-unix
                             ocaml-js-of-ocaml
                             ocaml-re))
    (home-page "https://ocsigen.org/ocsigen-start/")
    (synopsis
     "Higher-level library for developing Web and mobile applications with users, registration, notifications, etc")
    (description
     "Ocsigen Start is a set of higher-level libraries for building client-server Web
and mobile applications with Ocsigen (Js_of_ocaml and Eliom).  It provides
modules for user management (session management, registration, activation keys,
...), managing groups of users, displaying tips, and easily sending
notifications to the users.  Ocsigen Start comes with an eliom-distillery
template for an app with a database, user management, and session management.
This template is intended to serve as a basis for quickly building the Minimum
Viable Product for Web and mobile applications with users.  The goal is to
enable the programmer to concentrate on the core of the app, and not on user
management.")
    (license license:lgpl2.1)))

(define sane-glibc-locales
  (make-glibc-utf8-locales
   glibc
   #:locales (list "en_GB" "fr_FR" "en_US")
   #:name "sane-utf8-locales"))

(define vcs-file?
  ;; Return true if the given file is under version control.
  (or (git-predicate (dirname (dirname (current-source-directory))))
      (const #t)))

(define-public maxipassat
  (package
    (name "maxipassat")
    (version "0.1")
    (source (local-file "../.." "maxipassat-checkout"
                        #:recursive? #t
                        #:select? vcs-file?))
    (build-system ocaml-build-system)
    (inputs
     (list
      ;; locales: needed to use a pgdb config'd with non default locales:
      sane-glibc-locales
      ;; Makefile deps:
      which
      ;; web tools:
      postgresql
      node
      sassc
      ;; ocaml tools:
      dune
      ;; dev comfort:
      bash
      ))
    (propagated-inputs
     (append (list
              ocaml-re
              ocaml-ocsigen-start
              ocaml-ocsipersist
              ocaml-pgocaml
              ocaml-ocsipersist-pgsql
              ocaml-ocsipersist-pgsql-config
              ocaml-eliom)))
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          ;; ⚠️ danger! danger! high voltage! ⚡
          ;; this is very much a work in progress.
          ;; 1/ this skips css generation, it is your job to commit changes to generated
          ;;    file: static/defaultcss/maxi_passat.css
          ;; 2/ if you are using this as a template, you'll need to adapt db-build-init
          ;;    in Makefile.db. or maybe I should fix my schema and use this instead:
          ;;    (invoke "make" "db-init" "db-create" "db-schema")
          ;; 3/ I changed the following compared to the eliom-distillery template:
          ;;    - _static_config_.eliom.in: js & css location discovery
          ;;    - _main.eliom: Os_tip ref!?
          ;;    - _main.eliom: reads env vars for some settings.
          ;;    - _main.eliom: static dir location discovery
          ;;    - dune: added js_of_ocaml to libs & ppx_deriving.std to pps
          ;;    - dune.config: -warn-error -A
          ;;    - Makefile.os: install.exe target: added dune build @install
          ;;    - Makefile.options: SHAREDIR is set with ocamlfind rather than opam
          (replace 'configure
            (lambda* (#:key outputs #:allow-other-keys)
              (substitute* "Makefile"
                (("include Makefile.style")
                 "css: $(CSS_DEST)
$(CSS_DEST): $(LOCAL_CSS)
	mkdir -p \"`dirname $(CSS_DEST)`\"
	HASH=`cat $< | md5sum | cut -d ' ' -f 1` && \
	cp $< $(CSS_PREFIX)_$$HASH.css && \
	ln -sf $(PROJECT_NAME)_$$HASH.css $@"))
              #t))
          (add-before 'build 'db-start
            (lambda _
              (invoke "make" "db-build-init")
              #t))
          (replace 'build
            (lambda* (#:key outputs #:allow-other-keys)
              (invoke "make"
                      (string-append "PREFIX=" (assoc-ref outputs "out") "/")
                      "DB_USER=wonko"
                      "css" "static.byte")
              #t))
          (add-after 'build 'db-stop
            (lambda _
              (invoke "make" "db-stop")
              #t))
          (replace 'install
            (lambda* (#:key outputs #:allow-other-keys)
              (let ((out (assoc-ref outputs "out")))
                (mkdir-p (string-append out "/var/www/maxi_passat/css"))
                (invoke "make"
                        (string-append "PREFIX=" out "/")
                        "install.exe"))
              #t)))))
    (synopsis "maxi passat")
    (description "maxi passat")
    (home-page "http://127.0.0.1/")
    (license license:lgpl3+)))

maxipassat
