(use-trait commission-trait 'SP3D6PV2ACBPEKYJTCMH7HEN02KP87QSP8KTEH335.commission-trait.commission)
(use-trait nft-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait) ;; 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9

(define-private (transfer-nft (token-contract <nft-trait>) (token-id uint) (sender principal) (recipient principal))
  (contract-call? token-contract transfer token-id sender recipient)
)

(define-constant ERR_ZERO (err u400))
(define-constant ERR_NOT_FOUND (err u401))
(define-data-var BNSONE principal 'SM18RN48GX7E3ED23M03BY4QD8EA2DG2R4VX4CDYJ) ;; BNS One commission address
(define-data-var TREASURY principal 'SM18RN48GX7E3ED23M03BY4QD8EA2DG2R4VX4CDYJ)

(define-data-var NAME (buff 48) 0x)
(define-data-var NAMESPACE (buff 20) 0x)

(define-public (buy-name-and-renew (price uint) (id uint) (commission <commission-trait>) (renew-fee uint) (names (list 100 {name: (buff 48), namespace: (buff 20)})))
    (let (
        (vault (as-contract tx-sender))
        (market-fee (/ (* price u300) u10000))
    )
    (if (is-bns-one commission)
        true
        (try! (stx-transfer? market-fee contract-caller (var-get TREASURY)) )
    )
    (try! (stx-transfer? (+ price renew-fee) contract-caller vault ))
    (try! (buy-name price id commission))
    (try! (fold check-err (map renew-name names) (ok true)))
    (print {a: "buy and renew with bns one", id: id, taker: contract-caller, renewals: (len names), funds: (stx-get-balance vault)})
    (transfer-nft 'SP2QEZ06AGJ3RKJPBV14SY1V5BBFNAW33D96YPGZF.BNS-V2 id vault contract-caller)
    )
)

(define-private (renew-name (bns {namespace: (buff 20), name: (buff 48)})) 
  (begin
    (renew-name-single (get namespace bns) (get name bns))
  )
)

(define-private (renew-name-single (namespace (buff 20)) (name (buff 48))) 
  (begin
    (try! (as-contract (contract-call? 'SP2QEZ06AGJ3RKJPBV14SY1V5BBFNAW33D96YPGZF.BNS-V2 name-renewal namespace name)))
    (print {name: name, namespace: namespace})
    (ok true)
  )
)

(define-private (buy-name (price uint)  (id uint) (commission <commission-trait>))
  (begin
    (asserts! (and (> price u0) (> id u0))  ERR_ZERO)
    (as-contract ( contract-call? 'SP2QEZ06AGJ3RKJPBV14SY1V5BBFNAW33D96YPGZF.BNS-V2 buy-in-ustx id commission ))
))

;; helper to check commission
(define-private (is-bns-one (comm-trait <commission-trait>))
  (let ((d (unwrap-panic (principal-destruct? (contract-of comm-trait))))
        (p (unwrap-panic (principal-construct? (get version d) (get hash-bytes d))))
  )
  (is-eq p (var-get BNSONE))  
  )
)

(define-private (check-err (result (response bool uint)) (prior (response bool uint)))
  (match prior ok-value result err-value (err err-value))
)