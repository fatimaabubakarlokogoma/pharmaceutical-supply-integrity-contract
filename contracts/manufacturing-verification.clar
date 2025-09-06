;; Manufacturing Verification Contract
;; Manages pharmaceutical manufacturing verification and quality control

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-BATCH-NOT-FOUND (err u201))
(define-constant ERR-ALREADY-EXISTS (err u202))
(define-constant ERR-INVALID-BATCH-ID (err u203))
(define-constant ERR-INVALID-QUANTITY (err u204))
(define-constant ERR-BATCH-ALREADY-EXISTS (err u205))
(define-constant ERR-NOT-REGISTERED (err u206))
(define-constant ERR-INVALID-SCORE (err u207))
(define-constant ERR-QC-ALREADY-RECORDED (err u208))

;; Contract owner
(define-constant CONTRACT-OWNER tx-sender)

;; Participant registries
(define-map registered-manufacturers principal bool)
(define-map registered-auditors principal bool)

;; Manufacturer profiles with comprehensive information
(define-map manufacturer-profiles
  principal
  {
    company-name: (string-ascii 100),
    license-number: (string-ascii 50),
    registration-date: uint,
    gmp-certified: bool,
    active-status: bool
  }
)

;; Production batch records with detailed manufacturing data
(define-map production-records
  { batch-id: (string-ascii 50) }
  {
    drug-id: (string-ascii 50),
    manufacturer: principal,
    manufacturing-date: (string-ascii 20),
    lot-number: (string-ascii 30),
    expiry-date: (string-ascii 20),
    quantity-produced: uint,
    gmp-certificate-hash: (buff 32),
    production-facility: (string-ascii 100),
    batch-status: (string-ascii 20),
    created-at: uint
  }
)

;; Quality control records with auditor verification
(define-map qc-records
  { batch-id: (string-ascii 50), auditor: principal }
  {
    audit-date: uint,
    quality-passed: bool,
    audit-notes: (string-ascii 500),
    test-results: (string-ascii 300),
    compliance-score: uint,
    auditor-signature: (buff 64)
  }
)

;; Quality history tracking for comprehensive audit trails
(define-map quality-history
  { batch-id: (string-ascii 50) }
  {
    qc-audits: (list 10 {
      auditor: principal,
      audit-date: uint,
      quality-passed: bool,
      compliance-score: uint
    }),
    total-audits: uint,
    average-compliance-score: uint,
    final-certification: bool,
    certification-date: (optional uint)
  }
)

;; Manufacturing statistics for performance tracking
(define-map manufacturing-stats
  principal
  {
    total-batches-produced: uint,
    total-quantity-produced: uint,
    average-quality-score: uint,
    last-inspection-date: uint,
    compliance-rating: (string-ascii 20)
  }
)

;; Administrative functions for participant registration
(define-public (register-manufacturer
  (manufacturer principal)
  (company-name (string-ascii 100))
  (license-number (string-ascii 50))
)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-none (map-get? registered-manufacturers manufacturer)) ERR-ALREADY-EXISTS)
    
    (map-set registered-manufacturers manufacturer true)
    (map-set manufacturer-profiles manufacturer {
      company-name: company-name,
      license-number: license-number,
      registration-date: block-height,
      gmp-certified: false,
      active-status: true
    })
    
    ;; Initialize manufacturing statistics
    (map-set manufacturing-stats manufacturer {
      total-batches-produced: u0,
      total-quantity-produced: u0,
      average-quality-score: u0,
      last-inspection-date: u0,
      compliance-rating: "pending"
    })
    
    (print {
      event: "manufacturer-registered",
      manufacturer: manufacturer,
      company-name: company-name,
      timestamp: block-height
    })
    (ok true)
  )
)

(define-public (register-auditor (auditor principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-none (map-get? registered-auditors auditor)) ERR-ALREADY-EXISTS)
    
    (map-set registered-auditors auditor true)
    (print { event: "auditor-registered", auditor: auditor, timestamp: block-height })
    (ok true)
  )
)

;; Core manufacturing batch recording function
(define-public (record-production-batch
  (batch-id (string-ascii 50))
  (drug-id (string-ascii 50))
  (manufacturing-date (string-ascii 20))
  (lot-number (string-ascii 30))
  (expiry-date (string-ascii 20))
  (quantity-produced uint)
  (gmp-certificate-hash (buff 32))
  (production-facility (string-ascii 100))
)
  (let (
    (is-registered (default-to false (map-get? registered-manufacturers tx-sender)))
    (stats-data (default-to 
      { total-batches-produced: u0, total-quantity-produced: u0, 
        average-quality-score: u0, last-inspection-date: u0, compliance-rating: "pending" }
      (map-get? manufacturing-stats tx-sender)
    ))
  )
    (asserts! is-registered ERR-NOT-AUTHORIZED)
    (asserts! (> (len batch-id) u0) ERR-INVALID-BATCH-ID)
    (asserts! (> quantity-produced u0) ERR-INVALID-QUANTITY)
    (asserts! (is-none (map-get? production-records { batch-id: batch-id })) ERR-BATCH-ALREADY-EXISTS)
    
    ;; Record production batch
    (map-set production-records { batch-id: batch-id } {
      drug-id: drug-id,
      manufacturer: tx-sender,
      manufacturing-date: manufacturing-date,
      lot-number: lot-number,
      expiry-date: expiry-date,
      quantity-produced: quantity-produced,
      gmp-certificate-hash: gmp-certificate-hash,
      production-facility: production-facility,
      batch-status: "produced",
      created-at: block-height
    })
    
    ;; Initialize quality history
    (map-set quality-history { batch-id: batch-id } {
      qc-audits: (list),
      total-audits: u0,
      average-compliance-score: u0,
      final-certification: false,
      certification-date: none
    })
    
    ;; Update manufacturing statistics
    (map-set manufacturing-stats tx-sender
      (merge stats-data {
        total-batches-produced: (+ (get total-batches-produced stats-data) u1),
        total-quantity-produced: (+ (get total-quantity-produced stats-data) quantity-produced)
      })
    )
    
    (print {
      event: "production-batch-recorded",
      batch-id: batch-id,
      manufacturer: tx-sender,
      drug-id: drug-id,
      quantity: quantity-produced,
      timestamp: block-height
    })
    (ok true)
  )
)

;; Quality control audit recording
(define-public (add-qc-record
  (batch-id (string-ascii 50))
  (quality-passed bool)
  (audit-notes (string-ascii 500))
  (test-results (string-ascii 300))
  (compliance-score uint)
  (auditor-signature (buff 64))
)
  (let (
    (is-auditor (default-to false (map-get? registered-auditors tx-sender)))
    (batch-exists (is-some (map-get? production-records { batch-id: batch-id })))
    (quality-data (unwrap! (map-get? quality-history { batch-id: batch-id }) ERR-BATCH-NOT-FOUND))
    (current-audits (get qc-audits quality-data))
    (existing-qc (map-get? qc-records { batch-id: batch-id, auditor: tx-sender }))
  )
    (asserts! is-auditor ERR-NOT-AUTHORIZED)
    (asserts! batch-exists ERR-BATCH-NOT-FOUND)
    (asserts! (<= compliance-score u100) ERR-INVALID-SCORE)
    (asserts! (is-none existing-qc) ERR-QC-ALREADY-RECORDED)
    
    ;; Record QC audit
    (map-set qc-records { batch-id: batch-id, auditor: tx-sender } {
      audit-date: block-height,
      quality-passed: quality-passed,
      audit-notes: audit-notes,
      test-results: test-results,
      compliance-score: compliance-score,
      auditor-signature: auditor-signature
    })
    
    ;; Update quality history
    (let (
      (new-audit {
        auditor: tx-sender,
        audit-date: block-height,
        quality-passed: quality-passed,
        compliance-score: compliance-score
      })
      (updated-audits (unwrap-panic (as-max-len? (append current-audits new-audit) u10)))
      (total-audits (+ (get total-audits quality-data) u1))
      (new-average (/ (+ (* (get average-compliance-score quality-data) (get total-audits quality-data)) compliance-score) total-audits))
    )
      (map-set quality-history { batch-id: batch-id } {
        qc-audits: updated-audits,
        total-audits: total-audits,
        average-compliance-score: new-average,
        final-certification: (and quality-passed (>= compliance-score u80)),
        certification-date: (get certification-date quality-data)
      })
    )
    
    (print {
      event: "qc-record-added",
      batch-id: batch-id,
      auditor: tx-sender,
      quality-passed: quality-passed,
      compliance-score: compliance-score,
      timestamp: block-height
    })
    (ok true)
  )
)

;; Batch certification function
(define-public (certify-batch (batch-id (string-ascii 50)))
  (let (
    (batch-data (unwrap! (map-get? production-records { batch-id: batch-id }) ERR-BATCH-NOT-FOUND))
    (quality-data (unwrap! (map-get? quality-history { batch-id: batch-id }) ERR-BATCH-NOT-FOUND))
    (is-authorized (or
      (is-eq tx-sender CONTRACT-OWNER)
      (default-to false (map-get? registered-auditors tx-sender))
    ))
    (meets-requirements (and 
      (>= (get average-compliance-score quality-data) u80)
      (> (get total-audits quality-data) u0)
    ))
  )
    (asserts! is-authorized ERR-NOT-AUTHORIZED)
    (asserts! meets-requirements (err u209))
    
    ;; Update batch status
    (map-set production-records { batch-id: batch-id }
      (merge batch-data { batch-status: "certified" })
    )
    
    ;; Update quality history with certification
    (map-set quality-history { batch-id: batch-id }
      (merge quality-data {
        final-certification: true,
        certification-date: (some block-height)
      })
    )
    
    (print {
      event: "batch-certified",
      batch-id: batch-id,
      certifier: tx-sender,
      compliance-score: (get average-compliance-score quality-data),
      timestamp: block-height
    })
    (ok true)
  )
)

;; Read-only functions for querying manufacturing data
(define-read-only (get-production-batch (batch-id (string-ascii 50)))
  (map-get? production-records { batch-id: batch-id })
)

(define-read-only (get-qc-record (batch-id (string-ascii 50)) (auditor principal))
  (map-get? qc-records { batch-id: batch-id, auditor: auditor })
)

(define-read-only (get-quality-history (batch-id (string-ascii 50)))
  (map-get? quality-history { batch-id: batch-id })
)

(define-read-only (is-manufacturer-registered (manufacturer principal))
  (default-to false (map-get? registered-manufacturers manufacturer))
)

(define-read-only (is-auditor-registered (auditor principal))
  (default-to false (map-get? registered-auditors auditor))
)

(define-read-only (get-manufacturer-profile (manufacturer principal))
  (map-get? manufacturer-profiles manufacturer)
)

(define-read-only (get-manufacturing-stats (manufacturer principal))
  (map-get? manufacturing-stats manufacturer)
)

(define-read-only (is-batch-certified (batch-id (string-ascii 50)))
  (match (map-get? quality-history { batch-id: batch-id })
    quality-data (ok (get final-certification quality-data))
    ERR-BATCH-NOT-FOUND
  )
)

(define-read-only (get-batch-compliance-score (batch-id (string-ascii 50)))
  (match (map-get? quality-history { batch-id: batch-id })
    quality-data (ok (get average-compliance-score quality-data))
    ERR-BATCH-NOT-FOUND
  )
)

(define-read-only (get-batch-audit-count (batch-id (string-ascii 50)))
  (match (map-get? quality-history { batch-id: batch-id })
    quality-data (ok (get total-audits quality-data))
    ERR-BATCH-NOT-FOUND
  )
)


;; title: manufacturing-verification
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

