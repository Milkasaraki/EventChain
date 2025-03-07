;; EventTicketing Smart Contract - v1.0.0
;; Basic implementation of event ticket tracking

(define-trait event-ticketing-trait
  (
    (issue-ticket (uint uint) (response bool uint))
    (update-ticket-status (uint uint) (response bool uint))
    (get-ticket-status (uint) (response uint uint))
  )
)

;; Define ticket status constants
(define-constant TICKET_STATUS_CREATED u1)
(define-constant TICKET_STATUS_RESERVED u2)
(define-constant TICKET_STATUS_ACTIVATED u3)
(define-constant TICKET_STATUS_USED u4)

;; Error constants
(define-constant ERR_UNAUTHORIZED (err u1))
(define-constant ERR_INVALID_TICKET (err u2))
(define-constant ERR_STATUS_UPDATE_FAILED (err u3))
(define-constant ERR_INVALID_STATUS (err u4))

;; Contract owner
(define-data-var contract-owner principal tx-sender)

;; Ticket tracking map
(define-map ticket-details 
  {ticket-id: uint} 
  {
    owner: principal,
    current-status: uint
  }
)

;; Only contract owner can perform certain actions
(define-read-only (is-contract-owner (sender principal))
  (is-eq sender (var-get contract-owner))
)

;; Validate status
(define-private (is-valid-status (status uint))
  (or 
    (is-eq status TICKET_STATUS_CREATED)
    (is-eq status TICKET_STATUS_RESERVED)
    (is-eq status TICKET_STATUS_ACTIVATED)
    (is-eq status TICKET_STATUS_USED)
  )
)

;; Validate ticket ID
(define-private (is-valid-ticket-id (ticket-id uint))
  (and (> ticket-id u0) (<= ticket-id u1000000))
)

;; Issue a new ticket
(define-public (issue-ticket (ticket-id uint) (initial-status uint))
  (begin
    (asserts! (is-valid-ticket-id ticket-id) ERR_INVALID_TICKET)
    (asserts! (is-valid-status initial-status) ERR_INVALID_STATUS)
    (asserts! (or (is-contract-owner tx-sender) (is-eq initial-status TICKET_STATUS_CREATED)) ERR_UNAUTHORIZED)
    
    (map-set ticket-details 
      {ticket-id: ticket-id}
      {
        owner: tx-sender,
        current-status: initial-status
      }
    )
    (ok true)
  )
)

;; Update ticket status
(define-public (update-ticket-status (ticket-id uint) (new-status uint))
  (let 
    (
      (ticket (unwrap! (map-get? ticket-details {ticket-id: ticket-id}) ERR_INVALID_TICKET))
    )
    (asserts! (is-valid-ticket-id ticket-id) ERR_INVALID_TICKET)
    (asserts! (is-valid-status new-status) ERR_INVALID_STATUS)
    (asserts! 
      (or 
        (is-contract-owner tx-sender)
        (is-eq (get owner ticket) tx-sender)
      ) 
      ERR_UNAUTHORIZED
    )
    
    (map-set ticket-details 
      {ticket-id: ticket-id}
      (merge ticket 
        {
          current-status: new-status
        }
      )
    )
    (ok true)
  )
)

;; Get current ticket status
(define-read-only (get-ticket-status (ticket-id uint))
  (let 
    (
      (ticket (unwrap! (map-get? ticket-details {ticket-id: ticket-id}) ERR_INVALID_TICKET))
    )
    (ok (get current-status ticket))
  )
)
