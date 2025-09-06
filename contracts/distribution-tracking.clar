;; Distribution Tracking Contract
;; Manages pharmaceutical supply chain distribution and chain of custody

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-BATCH-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-RECIPIENT (err u103))
(define-constant ERR-INVALID-QUANTITY (err u104))
(define-constant ERR-BATCH-ALREADY-EXISTS (err u105))
(define-constant ERR-INVALID-BATCH-ID (err u106))
(define-constant ERR-TRANSFER-NOT-ALLOWED (err u107))

;; Contract owner
(define-constant CONTRACT-OWNER tx-sender)

;; Data structures for participant registry
(define-map registered-distributors principal bool)
(define-map registered-wholesalers principal bool)
(define-map registered-pharmacies principal bool)

;; Batch information with comprehensive tracking
(define-map batch-records
  { batch-id: (string-ascii 50) }
  {
    current-custodian: principal,
    origin-distributor: principal,
    product-name: (string-ascii 100),
    manufacturer: principal,
    quantity: uint,
    expiry-date: (string-ascii 20),
    created-at: uint,
    status: (string-ascii 20),
    verified: bool
  }
)

;; Chain of custody tracking with detailed transfer history
(define-map custody-history
  { batch-id: (string-ascii 50) }
  {
    transfers: (list 20 {
      from-custodian: principal,
      to-custodian: principal,
      transfer-timestamp: uint,
      transfer-type: (string-ascii 30),
      notes: (string-ascii 200)
    }),
    total-transfers: uint,
    last-update: uint
  }
)

;; Batch statistics for analytics
(define-map batch-analytics
  { batch-id: (string-ascii 50) }
  {
    days-in-transit: uint,
    total-handlers: uint,
    compliance-score: uint,
    final-destination: (optional principal)
  }
)

;; Administrative functions for participant registration
(define-public (register-distributor)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-none (map-get? registered-distributors tx-sender)) ERR-ALREADY-EXISTS)
    (map-set registered-distributors tx-sender true)
    (print { event: "distributor-registered", principal: tx-sender, timestamp: block-height })
    (ok true)
  )
)

(define-public (register-wholesaler (wholesaler principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-none (map-get? registered-wholesalers wholesaler)) ERR-ALREADY-EXISTS)
    (map-set registered-wholesalers wholesaler true)
    (print { event: "wholesaler-registered", principal: wholesaler, timestamp: block-height })
    (ok true)
  )
)

(define-public (register-pharmacy (pharmacy principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-none (map-get? registered-pharmacies pharmacy)) ERR-ALREADY-EXISTS)
    (map-set registered-pharmacies pharmacy true)
    (print { event: "pharmacy-registered", principal: pharmacy, timestamp: block-height })
    (ok true)
  )
)

;; Core shipment creation and management
(define-public (create-shipment
  (batch-id (string-ascii 50))
  (quantity uint)
  (product-name (string-ascii 100))
  (manufacturer principal)
  (expiry-date (string-ascii 20))
  (initial-recipient principal)
)
  (let (
    (sender-is-distributor (default-to false (map-get? registered-distributors tx-sender)))
  )
    (asserts! sender-is-distributor ERR-NOT-AUTHORIZED)
    (asserts! (> quantity u0) ERR-INVALID-QUANTITY)
    (asserts! (> (len batch-id) u0) ERR-INVALID-BATCH-ID)
    (asserts! (is-none (map-get? batch-records { batch-id: batch-id })) ERR-BATCH-ALREADY-EXISTS)
    
    ;; Create batch record
    (map-set batch-records { batch-id: batch-id }
      {
        current-custodian: initial-recipient,
        origin-distributor: tx-sender,
        product-name: product-name,
        manufacturer: manufacturer,
        quantity: quantity,
        expiry-date: expiry-date,
        created-at: block-height,
        status: "in-transit",
        verified: false
      }
    )
    
    ;; Initialize custody history
    (map-set custody-history { batch-id: batch-id }
      {
        transfers: (list {
          from-custodian: tx-sender,
          to-custodian: initial-recipient,
          transfer-timestamp: block-height,
          transfer-type: "initial-distribution",
          notes: "Initial shipment created"
        }),
        total-transfers: u1,
        last-update: block-height
      }
    )
    
    ;; Initialize analytics
    (map-set batch-analytics { batch-id: batch-id }
      {
        days-in-transit: u0,
        total-handlers: u1,
        compliance-score: u100,
        final-destination: none
      }
    )
    
    (print {
      event: "shipment-created",
      batch-id: batch-id,
      from: tx-sender,
      to: initial-recipient,
      quantity: quantity,
      timestamp: block-height
    })
    (ok true)
  )
)

;; Transfer custody between authorized parties
(define-public (transfer-custody
  (batch-id (string-ascii 50))
  (new-custodian principal)
  (transfer-notes (string-ascii 200))
)
  (let (
    (batch-data (unwrap! (map-get? batch-records { batch-id: batch-id }) ERR-BATCH-NOT-FOUND))
    (current-custodian (get current-custodian batch-data))
    (history-data (unwrap! (map-get? custody-history { batch-id: batch-id }) ERR-BATCH-NOT-FOUND))
    (analytics-data (unwrap! (map-get? batch-analytics { batch-id: batch-id }) ERR-BATCH-NOT-FOUND))
    (current-transfers (get transfers history-data))
    (is-authorized (is-eq tx-sender current-custodian))
    (recipient-authorized (or 
      (default-to false (map-get? registered-wholesalers new-custodian))
      (default-to false (map-get? registered-pharmacies new-custodian))
    ))
  )
    (asserts! is-authorized ERR-NOT-AUTHORIZED)
    (asserts! recipient-authorized ERR-INVALID-RECIPIENT)
    (asserts! (not (is-eq current-custodian new-custodian)) ERR-TRANSFER-NOT-ALLOWED)
    
    ;; Update batch record
    (map-set batch-records { batch-id: batch-id }
      (merge batch-data { current-custodian: new-custodian })
    )
    
    ;; Update custody history
    (map-set custody-history { batch-id: batch-id }
      {
        transfers: (unwrap-panic (as-max-len?
          (append current-transfers {
            from-custodian: current-custodian,
            to-custodian: new-custodian,
            transfer-timestamp: block-height,
            transfer-type: "custody-transfer",
            notes: transfer-notes
          })
          u20
        )),
        total-transfers: (+ (get total-transfers history-data) u1),
        last-update: block-height
      }
    )
    
    ;; Update analytics
    (map-set batch-analytics { batch-id: batch-id }
      (merge analytics-data {
        days-in-transit: (- block-height (get created-at batch-data)),
        total-handlers: (+ (get total-handlers analytics-data) u1)
      })
    )
    
    (print {
      event: "custody-transferred",
      batch-id: batch-id,
      from: current-custodian,
      to: new-custodian,
      timestamp: block-height
    })
    (ok true)
  )
)

;; Mark batch as verified for compliance
(define-public (mark-batch-verified (batch-id (string-ascii 50)))
  (let (
    (batch-data (unwrap! (map-get? batch-records { batch-id: batch-id }) ERR-BATCH-NOT-FOUND))
    (current-custodian (get current-custodian batch-data))
    (is-pharmacy (default-to false (map-get? registered-pharmacies tx-sender)))
    (is-authorized (or (is-eq tx-sender CONTRACT-OWNER) is-pharmacy))
  )
    (asserts! is-authorized ERR-NOT-AUTHORIZED)
    (map-set batch-records { batch-id: batch-id }
      (merge batch-data { verified: true, status: "verified" })
    )
    (print { event: "batch-verified", batch-id: batch-id, verifier: tx-sender })
    (ok true)
  )
)

;; Read-only functions for querying batch information
(define-read-only (get-batch-info (batch-id (string-ascii 50)))
  (map-get? batch-records { batch-id: batch-id })
)

(define-read-only (get-current-custodian (batch-id (string-ascii 50)))
  (match (map-get? batch-records { batch-id: batch-id })
    batch-data (ok (get current-custodian batch-data))
    ERR-BATCH-NOT-FOUND
  )
)

(define-read-only (get-custody-chain (batch-id (string-ascii 50)))
  (map-get? custody-history { batch-id: batch-id })
)

(define-read-only (get-batch-stats (batch-id (string-ascii 50)))
  (map-get? batch-analytics { batch-id: batch-id })
)

(define-read-only (is-distributor-registered (distributor principal))
  (default-to false (map-get? registered-distributors distributor))
)

(define-read-only (is-wholesaler-registered (wholesaler principal))
  (default-to false (map-get? registered-wholesalers wholesaler))
)

(define-read-only (is-pharmacy-registered (pharmacy principal))
  (default-to false (map-get? registered-pharmacies pharmacy))
)

(define-read-only (get-batch-verification-status (batch-id (string-ascii 50)))
  (match (map-get? batch-records { batch-id: batch-id })
    batch-data (ok (get verified batch-data))
    ERR-BATCH-NOT-FOUND
  )
)

(define-read-only (get-transfer-count (batch-id (string-ascii 50)))
  (match (map-get? custody-history { batch-id: batch-id })
    history-data (ok (get total-transfers history-data))
    ERR-BATCH-NOT-FOUND
  )
)


;; title: distribution-tracking
;; version:
;; summary:
;; description:

;; traits
;;

;; token definitions
;;

;; constants
;;

;; data vars
;;

;; data maps
;;

;; public functions
;;

;; read only functions
;;

;; private functions
;;

