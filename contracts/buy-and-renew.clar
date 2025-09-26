(use-trait commission-trait 'SP3D6PV2ACBPEKYJTCMH7HEN02KP87QSP8KTEH335.commission-trait.commission)
(use-trait nft-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait) ;; 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9

;; @desc SIP-09 compliant function to transfer a token
(define-private (transfer-nft (token-contract <nft-trait>) (token-id uint) (sender principal) (recipient principal))
  (contract-call? token-contract transfer token-id sender recipient)
)

;; @desc errors
(define-constant ERR_ZERO (err u400))
(define-constant ERR_NOT_FOUND (err u401))
(define-constant NOT_THE_OWNER (err u402))
(define-constant OUT_OF_RANGE (err u403))
(define-constant PAUSED (err u404))
(define-constant TOO_MANY_RENEWALS (err u405))

;; Contract variable
(define-data-var ADMIN principal tx-sender) ;; Administrator address
(define-data-var PAUSE bool false) ;; Pause the contract
(define-data-var BNSONE principal 'SM18RN48GX7E3ED23M03BY4QD8EA2DG2R4VX4CDYJ) ;; BNS One commission address
(define-data-var TREASURY principal 'SM18RN48GX7E3ED23M03BY4QD8EA2DG2R4VX4CDYJ) ;; BNS One treasury address
(define-data-var FEE uint u300) ;; Crossmarket Fee


;; Admin functions

(define-public (admin-set-admin-address (address principal))
  (begin 
    (asserts! (is-admin) NOT_THE_OWNER)
    (var-set ADMIN address)
    (ok address)
  )
)

(define-public (admin-set-pause )
  (begin 
    (asserts! (is-admin) NOT_THE_OWNER)
    (var-set PAUSE (not (var-get PAUSE)))
    (ok (if (var-get PAUSE) "Paused" "Started"))
  )
)

(define-public (admin-set-commission-address (address principal))
  (begin 
    (asserts! (is-admin) NOT_THE_OWNER)
    (var-set BNSONE address)
    (ok address)
  )
)

(define-public (admin-set-treasury-address (address principal))
  (begin 
    (asserts! (is-admin) NOT_THE_OWNER)
    (var-set TREASURY address)
    (ok address)
  )
)

(define-public (admin-set-fee (fee uint))
  (begin 
    (asserts! (is-admin) NOT_THE_OWNER)
    (asserts! (and (> fee u100) (<= fee u1000)) OUT_OF_RANGE)
    (var-set FEE fee)
    (ok fee)
  )
)

;; @desc buy a name across the marketplaces and renew it in a single tx
;; @params (price uint) price + market fee of the current listing
;; @params (id uint) token id
;; @params (commission <commission-trait>) listing commission
;; @params (renew-fee uint) total amount of renewal fees
;; @params (names (list 100 {name: (buff 48), namespace: (buff 20)})) a list containing name and namespace of the token id

(define-public (buy-name-and-renew (price uint) (id uint) (commission <commission-trait>) (renew-fee uint) (names (list 100 {name: (buff 48), namespace: (buff 20)})))
    (let (
        (vault (as-contract tx-sender))
        (market-fee (/ (* price (var-get FEE)) u10000))
    )
    (if (is-bns-one commission) ;; if not listed on BNS One we apply a cross-marketplace fee
        true
        (try! (stx-transfer? market-fee contract-caller (var-get TREASURY)) )
    )
    (try! (stx-transfer? (+ price renew-fee) contract-caller vault ))
    (try! (as-contract ( contract-call? 'SP2QEZ06AGJ3RKJPBV14SY1V5BBFNAW33D96YPGZF.BNS-V2 buy-in-ustx id commission )))
    (try! (fold check-err (map renew-name names) (ok true)))
    (print {a: "buy and renew with bns one", id: id, taker: contract-caller, renewals: (len names)})
    (transfer-nft 'SP2QEZ06AGJ3RKJPBV14SY1V5BBFNAW33D96YPGZF.BNS-V2 id vault contract-caller)
    )
)

;; @desc   buy a name across the marketplaces and renew it in a single tx. minified input
;;         Contract reads name and namespace from token id then calculate renewals fee
;;         Function create a list from name and namespace to loop the renew function
;; @params (price uint) price + market fee of the current listing
;; @params (id uint) token id
;; @params (commission <commission-trait>) listing commission
;; @params (renewals uint) the number of renewals

(define-public (buy-and-renew 
                (price uint)
                (id uint) 
                (commission <commission-trait>) 
                (renewals uint))
    (begin 
        (asserts! (and (> price u0) (> id u0)) ERR_ZERO)
        (asserts! (<= renewals u25)  TOO_MANY_RENEWALS)
        (asserts! (not (var-get PAUSE)) PAUSED)
        (let (
            (vault (as-contract tx-sender))
            (id-data (unwrap! (contract-call? 'SP2QEZ06AGJ3RKJPBV14SY1V5BBFNAW33D96YPGZF.BNS-V2 get-bns-from-id id) ERR_NOT_FOUND))
            (name (get name id-data))
            (namespace (get namespace id-data))
            (renew-fee (* renewals (unwrap-panic (unwrap-panic (contract-call? 'SP2QEZ06AGJ3RKJPBV14SY1V5BBFNAW33D96YPGZF.BNS-V2 get-name-price namespace name)))))
            (market-fee (/ (* price (var-get FEE)) u10000))
            (bns {name: name, namespace: namespace})
            (fulllist (list bns bns bns bns bns bns bns bns 
                            bns bns bns bns bns bns bns bns 
                            bns bns bns bns bns bns bns bns bns 
            )) ;; max 25 renewals
            (names (if (< renewals u25) (unwrap-panic (slice? fulllist u0 renewals)) fulllist))
        )
   
        (if (is-bns-one commission)
            true
            (try! (stx-transfer? market-fee contract-caller (var-get TREASURY)) )
        )
        (try! (stx-transfer? (+ price renew-fee) contract-caller vault ))
        (try! (as-contract ( contract-call? 'SP2QEZ06AGJ3RKJPBV14SY1V5BBFNAW33D96YPGZF.BNS-V2 buy-in-ustx id commission )))
        (if (and (is-renewable namespace) (> renewals u0))
            (try! (fold check-err (map renew-name names) (ok true)))
            true
        )
        (print {    a: (if (and (is-renewable namespace) (> renewals u0)) "buy and renew with bns one" "buy with bns one"), 
                    id: id, 
                    taker: contract-caller, 
                    renewals: (if (is-renewable namespace) renewals u0)})
        (transfer-nft 'SP2QEZ06AGJ3RKJPBV14SY1V5BBFNAW33D96YPGZF.BNS-V2 id vault contract-caller)
        )
    )
)

;; @desc   helper to loop the name-renewal function on BNS-v2
;; @params (bns {namespace: (buff 20), name: (buff 48)}) tuple with name and namespace

(define-private (renew-name (bns {namespace: (buff 20), name: (buff 48)})) 
    (as-contract (contract-call? 'SP2QEZ06AGJ3RKJPBV14SY1V5BBFNAW33D96YPGZF.BNS-V2 name-renewal (get namespace bns) (get name bns)))
)

;; @desc   helper to check commission
;; @params (commission <commission-trait>) listing commission

(define-private (is-bns-one (comm-trait <commission-trait>))
  (let ((d (unwrap-panic (principal-destruct? (contract-of comm-trait))))
        (p (unwrap-panic (principal-construct? (get version d) (get hash-bytes d))))
  )
  (is-eq p (var-get BNSONE))  
  )
)

;; @desc   helper to check if namespace is renewable
;; @params (namespace (buff 20)) namespace
(define-private (is-renewable (namespace (buff 20)))
    (or (is-eq namespace 0x627463) (is-eq namespace 0x6964) (is-eq namespace 0x6772617068697465)) ;; btc, id, graphite
)

(define-private (check-err (result (response bool uint)) (prior (response bool uint)))
  (match prior ok-value result err-value (err err-value))
)

(define-private (is-admin)
    (is-eq contract-caller (var-get ADMIN))
)