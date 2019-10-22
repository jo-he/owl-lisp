
(define-library (owl function)

   (export
      bytecode?
      function?
      procedure?)

   (import
      (owl core)
      (only (owl syscall) interact))

   (begin

      (define (bytecode? x)
         (eq? type-bytecode (type x)))

      ;; raw bytecode vector, 1-level (proc) or 2-level (clos) function
      (define (function? x)
         (or
            (bytecode? x)
            (eq? (type x) type-proc)
            (eq? (type x) type-clos)))

      ;; something executable? being a function or a finite function
      (define procedure? function?)
))
