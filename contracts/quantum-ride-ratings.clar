;; Rating system contract
(define-map RideRatings uint 
  {
    rider-rating: (optional uint),
    driver-rating: (optional uint)
  }
)

(define-public (rate-ride (ride-id uint) (rating uint) (is-driver bool))
  (let (
    (ride (unwrap! (contract-call? .quantum-ride get-ride ride-id) err-ride-not-found))
  )
    (asserts! (<= rating u5) (err u106))
    (asserts! (is-eq (get status ride) "COMPLETED") err-invalid-state)
    (ok (map-set RideRatings ride-id 
      (if is-driver
        { rider-rating: (some rating), driver-rating: none }
        { rider-rating: none, driver-rating: (some rating) }
      )
    ))
  )
)
