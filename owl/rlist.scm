(define-library (owl rlist)
   (import
      (owl core)
      (owl proof)

      ;; alternative implementations
      (owl lcd rlist) ;; fairly fast, can hold any data, fixnum offset
      ;(owl rlist old)      ;; fairly fast, can hold non-rlist-node -data, bignum offsets
      ;(owl rlist linear)   ;; reference library using regular lists. can bootstrap ol, barely
      )

   (export
      rnull
      rcons
      rget
      rcar
      rcdr
      rset
      rlen
      rlist
      rfold
      rfoldr
      riter
      riterr
      rmap
      rnull?
      rpair?
      list->rlist
      rlist->list)

   (begin

      ;; the functionality comes from the imported library
      ;; here we just nail down some semantics using (owl proof)

      (example

         (rcar (rcons 11 rnull)) = 11

         (rget rnull 100 'no) = 'no

         (rget (rlist 11 22 33) 2 'no) = 33

         (rget (list->rlist '(11 22 33)) 9 'no) = 'no

         (rnull? (rcdr (rcons 11 rnull))) = #t

         (rlen (rcons 11 rnull)) = 1

         (rlist->list (rlist 11 22 33)) = '(11 22 33)

)))
