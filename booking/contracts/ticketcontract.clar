;; EventTicketing Smart Contract - v3.0.0
;; Complete implementation with authorization system

(define-trait event-ticketing-trait
  (
    (issue-ticket (uint uint) (response bool uint))
    (update-ticket-status (uint uint) (response bool uint))
    (get-ticket-history (uint) (response (list 10 {status: uint, timestamp: uint}) uint))
    (add-authorization (uint uint principal) (response bool uint))
    (verify-authorization (uint uint) (response bool uint))
  )
)

;; Define ticket status constants
(define-constant TICKET_STATUS_CREATED u1)
(define-constant TICKET_STATUS_RESERVED u2)
(define-constant TICKET_STATUS_ACTIVATED u3)
(define-constant TICKET_STATUS_USED u4)

;; Define authorization type constants
(define-constant AUTH_TYPE_VIP u1)
(define-constant AUTH_TYPE_BACKSTAGE u2)
(define-constant AUTH_TYPE_PREMIUM u3)
(define-constant AUTH_TYPE_SPECIAL_ACCESS u4)

;; Error constants
(define-constant ERR_UNAUTHORIZED (err u1))
(define-constant ERR_INVALID_TICKET (err u2))
(define-constant ERR_STATUS_UPDATE_FAILED (err u3))
(define-constant ERR_INVALID_STATUS (err u4))
(define-constant ERR_INVALID_AUTHORIZATION (err u5))
(define-constant ERR_AUTHORIZATION_EXISTS (err u6))

;; Contract owner
(define-data-var contract-owner principal tx-sender)

;; Current timestamp counter
(define-data-var timestamp-counter uint u0)

;; Ticket tracking map
(define-map ticket-details 
  {ticket-id: uint} 
  {
    owner: principal,
    current-status: uint,
    history: (list 10 {status: uint, timestamp: uint})
  }
)

;; Authorization tracking map
(define-map ticket-authorizations
  {ticket-id: uint, auth-type: uint}
  {
    issuer: principal,
    timestamp: uint,
    valid: bool
  }
)

;; Approved venue authorities
(define-map venue-authorities
  {authority: principal, auth-type: uint}
  {approved: bool}
)

;; Get current timestamp and increment counter
(define-private (get-current-timestamp)
  (begin
    (var-set timestamp-counter (+ (var-get timestamp-counter) u1))
    (var-get timestamp-counter)
  )
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

;; Validate authorization type
(define-private (is-valid-authorization-type (auth-type uint))
  (or
    (is-eq auth-type AUTH_TYPE_VIP)
    (is-eq auth-type AUTH_TYPE_BACKSTAGE)
    (is-eq auth-type AUTH_TYPE_PREMIUM)
    (is-eq auth-type AUTH_TYPE_SPECIAL_ACCESS)
  )
)

;; Validate ticket ID
(define-private (is-valid-ticket-id (ticket-id uint))
  (and (> ticket-id u0) (<= ticket-id u1000000))
)

;; Check if sender is approved venue authority
(define-private (is-venue-authority (authority principal) (auth-type uint))
  (default-to 
    false
    (get approved (map-get? venue-authorities {authority: authority, auth-type: auth-type}))
  )
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
        current-status: initial-status,
        history: (list {status: initial-status, timestamp: (get-current-timestamp)})
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
          current-status: new-status,
          history: (unwrap-panic 
            (as-max-len? 
              (append (get history ticket) {status: new-status, timestamp: (get-current-timestamp)}) 
              u10
            )
          )
        }
      )
    )
    (ok true)
  )
)

;; Validate authority principal
(define-private (is-valid-authority (authority principal))
  (and 
    (not (is-eq authority (var-get contract-owner)))  ;; Authority can't be contract owner
    (not (is-eq authority tx-sender))                 ;; Authority can't be the sender
    (not (is-eq authority 'SP000000000000000000002Q6VF78))  ;; Not zero address
  )
)

;; Add venue authority with additional validation
(define-public (add-venue-authority (authority principal) (auth-type uint))
  (begin
    (asserts! (is-contract-owner tx-sender) ERR_UNAUTHORIZED)
    (asserts! (is-valid-authorization-type auth-type) ERR_INVALID_AUTHORIZATION)
    (asserts! (is-valid-authority authority) ERR_UNAUTHORIZED)
    
    ;; After validation, we can safely use the authority
    (map-set venue-authorities
      {authority: authority, auth-type: auth-type}
      {approved: true}
    )
    (ok true)
  )
)

;; Add authorization to ticket
(define-public (add-authorization (ticket-id uint) (auth-type uint))
  (begin
    (asserts! (is-valid-ticket-id ticket-id) ERR_INVALID_TICKET)
    (asserts! (is-valid-authorization-type auth-type) ERR_INVALID_AUTHORIZATION)
    (asserts! (is-venue-authority tx-sender auth-type) ERR_UNAUTHORIZED)
    
    (asserts! 
      (is-none 
        (map-get? ticket-authorizations {ticket-id: ticket-id, auth-type: auth-type})
      )
      ERR_AUTHORIZATION_EXISTS
    )
    
    (let
      ((validated-ticket-id ticket-id)
       (validated-auth-type auth-type))
      (map-set ticket-authorizations
        {ticket-id: validated-ticket-id, auth-type: validated-auth-type}
        {
          issuer: tx-sender,
          timestamp: (get-current-timestamp),
          valid: true
        }
      )
      (ok true)
    )
  )
)

;; Verify ticket authorization
(define-read-only (verify-authorization (ticket-id uint) (auth-type uint))
  (let
    (
      (authorization (unwrap! 
        (map-get? ticket-authorizations {ticket-id: ticket-id, auth-type: auth-type})
        ERR_INVALID_AUTHORIZATION
      ))
    )
    (ok (get valid authorization))
  )
)

;; Revoke authorization
(define-public (revoke-authorization (ticket-id uint) (auth-type uint))
  (begin
    (asserts! (is-valid-ticket-id ticket-id) ERR_INVALID_TICKET)
    (asserts! (is-valid-authorization-type auth-type) ERR_INVALID_AUTHORIZATION)
    
    (let
      (
        (authorization (unwrap! 
          (map-get? ticket-authorizations {ticket-id: ticket-id, auth-type: auth-type})
          ERR_INVALID_AUTHORIZATION
        ))
        (validated-ticket-id ticket-id)
        (validated-auth-type auth-type)
      )
      (asserts! 
        (or
          (is-contract-owner tx-sender)
          (is-eq (get issuer authorization) tx-sender)
        )
        ERR_UNAUTHORIZED
      )
      
      (map-set ticket-authorizations
        {ticket-id: validated-ticket-id, auth-type: validated-auth-type}
        (merge authorization {valid: false})
      )
      (ok true)
    )
  )
)

;; Get ticket history
(define-read-only (get-ticket-history (ticket-id uint))
  (let 
    (
      (ticket (unwrap! (map-get? ticket-details {ticket-id: ticket-id}) ERR_INVALID_TICKET))
    )
    (ok (get history ticket))
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

;; Get authorization details
(define-read-only (get-authorization-details (ticket-id uint) (auth-type uint))
  (ok (map-get? ticket-authorizations {ticket-id: ticket-id, auth-type: auth-type}))
)