;;Automated Rental Agreement Smart Contract

;; Constants
(define-constant ERR_NOT_OWNER (err u100))
(define-constant ERR_RENTAL_ALREADY_EXISTS (err u101))
(define-constant ERR_RENTAL_NOT_FOUND (err u102))
(define-constant ERR_RENTAL_ACTIVE (err u103))
(define-constant ERR_RENTAL_ENDED (err u104))
(define-constant ERR_INSUFFICIENT_DEPOSIT (err u105))
(define-constant ERR_DEPOSIT_ALREADY_RETURNED (err u106))
(define-constant ERR_INVALID_DURATION (err u107))
(define-constant ERR_NOT_AUTHORIZED (err u108))
;; Additional Constants
(define-constant ERR_INVALID_INSURANCE (err u113))
(define-constant ERR_INSURANCE_NOT_FOUND (err u114))
(define-constant ERR_SUBLEASE_NOT_ALLOWED (err u115))
(define-constant ERR_UTILITY_NOT_FOUND (err u116))
(define-constant ERR_INSPECTION_NOT_FOUND (err u117))
(define-constant ERR_PAYMENT_PLAN_EXISTS (err u118))

;; Data Variables
(define-data-var owner principal tx-sender)
(define-data-var rental-count uint u0)
;; Additional Data Variables
(define-data-var insurance-count uint u0)
(define-data-var utility-count uint u0)
(define-data-var inspection-count uint u0)


;; Data Maps
(define-map Rentals
    uint  ;; rental ID
    {
        owner: principal,
        renter: principal,
        start-date: uint,
        end-date: uint,
        daily-rate: uint,
        deposit-amount: uint,
        deposit-returned: bool,
        status: (string-ascii 20)  ;; active, ended, cancelled
    }
)
;; Additional Data Maps
(define-map InsurancePolicies
    uint  ;; insurance ID
    {
        rental-id: uint,
        policy-number: (string-ascii 50),
        coverage-amount: uint,
        start-date: uint,
        end-date: uint,
        insurance-provider: (string-ascii 100),
        status: (string-ascii 20)  ;; active, expired, cancelled
    }
)

(define-map UtilityAccounts
    uint  ;; utility ID
    {
        rental-id: uint,
        utility-type: (string-ascii 20),  ;; water, electricity, gas, internet
        account-number: (string-ascii 50),
        provider: (string-ascii 100),
        monthly-average: uint,
        last-reading: uint,
        last-payment: uint
    }
)

(define-map PropertyInspections
    uint  ;; inspection ID
    {
        rental-id: uint,
        inspector: principal,
        inspection-date: uint,
        inspection-type: (string-ascii 50),  ;; move-in, move-out, routine, maintenance
        report: (string-ascii 1000),
        issues-found: bool,
        follow-up-required: bool,
        resolved-date: uint
    }
)

(define-map SubleaseAgreements
    uint  ;; rental ID
    {
        original-renter: principal,
        sublease-renter: principal,
        start-date: uint,
        end-date: uint,
        monthly-rate: uint,
        status: (string-ascii 20),  ;; pending, active, ended
        approved-by-owner: bool
    }
)

(define-map PaymentPlans
    uint  ;; rental ID
    {
        installments: uint,
        amount-per-installment: uint,
        payment-schedule: (list 12 uint),  ;; block heights for payments
        remaining-balance: uint,
        last-installment-paid: uint,
        status: (string-ascii 20)  ;; active, completed, defaulted
    }
)

;; Public Functions

;; Create a new rental agreement
(define-public (create-rental (renter principal)
                              (start-date uint)
                              (duration uint)
                              (daily-rate uint)
                              (deposit-amount uint))
    (let ((rental-id (+ (var-get rental-count) u1))
          (end-date (+ start-date duration)))
        (if (and 
                (is-eq tx-sender (var-get owner))
                (not (is-some (map-get? Rentals rental-id))))
            (begin
                (map-set Rentals rental-id
                    {
                        owner: tx-sender,
                        renter: renter,
                        start-date: start-date,
                        end-date: end-date,
                        daily-rate: daily-rate,
                        deposit-amount: deposit-amount,
                        deposit-returned: false,
                        status: "active"
                    })
                (var-set rental-count rental-id)
                (ok rental-id))
            ERR_RENTAL_ALREADY_EXISTS))
)

;; Extend rental agreement
(define-public (extend-rental (rental-id uint) (additional-duration uint))
    (let ((rental (unwrap! (map-get? Rentals rental-id) ERR_RENTAL_NOT_FOUND)))
        (if (and
                (is-eq tx-sender (get owner rental))
                (is-eq (get status rental) "active")
                (< block-height (get end-date rental)))
            (begin
                (let ((new-end-date (+ (get end-date rental) additional-duration)))
                    (map-set Rentals rental-id
                        (merge rental {end-date: new-end-date}))
                    (ok true)))
            (if (is-eq (get status rental) "ended")
                ERR_RENTAL_ENDED
                ERR_RENTAL_ACTIVE)))
)

;; End rental agreement
(define-public (end-rental (rental-id uint))
    (let ((rental (unwrap! (map-get? Rentals rental-id) ERR_RENTAL_NOT_FOUND)))
        (if (and
                (or (is-eq tx-sender (get owner rental)) 
                    (is-eq tx-sender (get renter rental)))
                (is-eq (get status rental) "active")
                (>= block-height (get end-date rental)))
            (begin
                (map-set Rentals rental-id
                    (merge rental {status: "ended"}))
                (ok true))
            (if (is-eq (get status rental) "ended")
                ERR_RENTAL_ENDED
                ERR_RENTAL_ACTIVE)))
)

;; Cancel rental agreement
(define-public (cancel-rental (rental-id uint))
    (let ((rental (unwrap! (map-get? Rentals rental-id) ERR_RENTAL_NOT_FOUND)))
        (if (and
                (is-eq tx-sender (get owner rental))
                (is-eq (get status rental) "active")
                (< block-height (get end-date rental)))
            (begin
                (map-set Rentals rental-id
                    (merge rental {status: "cancelled"}))
                (ok true))
            (if (is-eq (get status rental) "ended")
                ERR_RENTAL_ENDED
                ERR_RENTAL_ACTIVE)))
)

;; Return deposit
(define-public (return-deposit (rental-id uint))
    (let ((rental (unwrap! (map-get? Rentals rental-id) ERR_RENTAL_NOT_FOUND)))
        (if (and
                (is-eq tx-sender (get owner rental))
                (is-eq (get status rental) "ended")
                (not (get deposit-returned rental)))
            (begin
                (try! (as-contract (stx-transfer? 
                                    (get deposit-amount rental) 
                                    tx-sender 
                                    (get renter rental))))
                (map-set Rentals rental-id
                    (merge rental {deposit-returned: true}))
                (ok true))
            (if (get deposit-returned rental)
                ERR_DEPOSIT_ALREADY_RETURNED
                ERR_RENTAL_ACTIVE)))
)

;; Owner functions

;; Change owner
(define-public (change-owner (new-owner principal))
    (if (is-eq tx-sender (var-get owner))
        (begin
            (var-set owner new-owner)
            (ok true))
        ERR_NOT_OWNER)
)

;; View functions

;; Get rental details
(define-read-only (get-rental (rental-id uint))
    (map-get? Rentals rental-id)
)
;; Additional Public Functions

;; Add insurance policy
(define-public (add-insurance-policy
    (rental-id uint)
    (policy-number (string-ascii 50))
    (coverage-amount uint)
    (start-date uint)
    (end-date uint)
    (insurance-provider (string-ascii 100)))
    (let ((insurance-id (+ (var-get insurance-count) u1))
          (rental (unwrap! (map-get? Rentals rental-id) ERR_RENTAL_NOT_FOUND)))
        (if (is-eq tx-sender (get renter rental))
            (begin
                (map-set InsurancePolicies insurance-id
                    {
                        rental-id: rental-id,
                        policy-number: policy-number,
                        coverage-amount: coverage-amount,
                        start-date: start-date,
                        end-date: end-date,
                        insurance-provider: insurance-provider,
                        status: "active"
                    })
                (var-set insurance-count insurance-id)
                (ok insurance-id))
            ERR_NOT_AUTHORIZED))
)

