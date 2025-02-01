;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-registered (err u100))
(define-constant err-already-registered (err u101))
(define-constant err-ride-not-found (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-state (err u104))

;; Data Variables
(define-data-var min-fare uint u500)
(define-data-var platform-fee uint u50)

;; Data Maps
(define-map Drivers principal 
  {
    registered: bool,
    rating: uint,
    total-rides: uint,
    active: bool
  }
)

(define-map Rides uint 
  {
    rider: principal,
    driver: (optional principal),
    pickup: (string-ascii 100),
    dropoff: (string-ascii 100),
    fare: uint,
    status: (string-ascii 20),
    timestamp: uint
  }
)

;; Counter for ride IDs
(define-data-var ride-counter uint u0)

;; Public Functions
(define-public (register-driver)
  (let ((driver tx-sender))
    (asserts! (is-none (map-get? Drivers driver)) err-already-registered)
    (ok (map-set Drivers driver {
      registered: true,
      rating: u0,
      total-rides: u0,
      active: true
    }))
  )
)

(define-public (request-ride (pickup (string-ascii 100)) (dropoff (string-ascii 100)) (fare uint))
  (let ((ride-id (+ (var-get ride-counter) u1)))
    (asserts! (>= fare (var-get min-fare)) (err u105))
    (try! (stx-transfer? fare tx-sender (as-contract tx-sender)))
    (var-set ride-counter ride-id)
    (ok (map-set Rides ride-id {
      rider: tx-sender,
      driver: none,
      pickup: pickup,
      dropoff: dropoff,
      fare: fare,
      status: "REQUESTED",
      timestamp: block-height
    }))
  )
)

(define-public (accept-ride (ride-id uint))
  (let (
    (driver tx-sender)
    (ride (unwrap! (map-get? Rides ride-id) err-ride-not-found))
  )
    (asserts! (is-some (map-get? Drivers driver)) err-not-registered)
    (asserts! (is-none (get driver ride)) err-invalid-state)
    (ok (map-set Rides ride-id (merge ride {
      driver: (some driver),
      status: "ACCEPTED"
    })))
  )
)

(define-public (complete-ride (ride-id uint))
  (let (
    (ride (unwrap! (map-get? Rides ride-id) err-ride-not-found))
    (driver (unwrap! (get driver ride) err-unauthorized))
  )
    (asserts! (is-eq driver tx-sender) err-unauthorized)
    (try! (as-contract (stx-transfer? (get fare ride) (as-contract tx-sender) driver)))
    (ok (map-set Rides ride-id (merge ride { status: "COMPLETED" })))
  )
)

;; Read-only functions
(define-read-only (get-ride (ride-id uint))
  (map-get? Rides ride-id)
)

(define-read-only (get-driver (address principal))
  (map-get? Drivers address)
)
