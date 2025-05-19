(define-module (guix-numpex packages base)
  #:use-module (gnu packages base)
  #:use-module (guix packages))

(define-public hello-numpex
  (package/inherit hello
    (name "hello-numpex")))
