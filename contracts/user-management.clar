;; Youth Activity System - User Management Contract
;; Handles user registration, roles, and profiles

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-USER-EXISTS (err u101))
(define-constant ERR-USER-NOT-FOUND (err u102))
(define-constant ERR-INVALID-ROLE (err u103))
(define-constant ERR-INVALID-INPUT (err u104))

;; Data Variables
(define-data-var next-user-id uint u1)

;; User roles
(define-constant ROLE-STUDENT u1)
(define-constant ROLE-INSTRUCTOR u2)
(define-constant ROLE-PARENT u3)
(define-constant ROLE-ADMIN u4)

;; Data Maps
(define-map users
  { user-id: uint }
  {
    principal: principal,
    role: uint,
    name: (string-ascii 50),
    email: (string-ascii 100),
    phone: (string-ascii 20),
    active: bool,
    created-at: uint
  }
)

(define-map user-principals
  { principal: principal }
  { user-id: uint }
)

(define-map parent-children
  { parent-id: uint, child-id: uint }
  { approved: bool }
)

;; Private Functions
(define-private (is-valid-role (role uint))
  (or
    (is-eq role ROLE-STUDENT)
    (or
      (is-eq role ROLE-INSTRUCTOR)
      (or
        (is-eq role ROLE-PARENT)
        (is-eq role ROLE-ADMIN)
      )
    )
  )
)

(define-private (is-valid-string (str (string-ascii 100)))
  (> (len str) u0)
)

;; Public Functions

;; Register a new user
(define-public (register-user
  (role uint)
  (name (string-ascii 50))
  (email (string-ascii 100))
  (phone (string-ascii 20))
)
  (let
    (
      (user-id (var-get next-user-id))
      (caller tx-sender)
    )
    ;; Validate inputs
    (asserts! (is-valid-role role) ERR-INVALID-ROLE)
    (asserts! (is-valid-string name) ERR-INVALID-INPUT)
    (asserts! (is-valid-string email) ERR-INVALID-INPUT)
    (asserts! (is-none (map-get? user-principals { principal: caller })) ERR-USER-EXISTS)

    ;; Create user record
    (map-set users
      { user-id: user-id }
      {
        principal: caller,
        role: role,
        name: name,
        email: email,
        phone: phone,
        active: true,
        created-at: block-height
      }
    )

    ;; Map principal to user-id
    (map-set user-principals
      { principal: caller }
      { user-id: user-id }
    )

    ;; Increment next user ID
    (var-set next-user-id (+ user-id u1))

    (ok user-id)
  )
)

;; Update user profile
(define-public (update-profile
  (name (string-ascii 50))
  (email (string-ascii 100))
  (phone (string-ascii 20))
)
  (let
    (
      (caller tx-sender)
      (user-data (unwrap! (map-get? user-principals { principal: caller }) ERR-USER-NOT-FOUND))
      (user-id (get user-id user-data))
      (current-user (unwrap! (map-get? users { user-id: user-id }) ERR-USER-NOT-FOUND))
    )
    ;; Validate inputs
    (asserts! (is-valid-string name) ERR-INVALID-INPUT)
    (asserts! (is-valid-string email) ERR-INVALID-INPUT)

    ;; Update user record
    (map-set users
      { user-id: user-id }
      (merge current-user {
        name: name,
        email: email,
        phone: phone
      })
    )

    (ok true)
  )
)

;; Link parent to child (requires both parties' consent)
(define-public (link-parent-child (child-principal principal))
  (let
    (
      (parent-data (unwrap! (map-get? user-principals { principal: tx-sender }) ERR-USER-NOT-FOUND))
      (child-data (unwrap! (map-get? user-principals { principal: child-principal }) ERR-USER-NOT-FOUND))
      (parent-id (get user-id parent-data))
      (child-id (get user-id child-data))
      (parent-user (unwrap! (map-get? users { user-id: parent-id }) ERR-USER-NOT-FOUND))
      (child-user (unwrap! (map-get? users { user-id: child-id }) ERR-USER-NOT-FOUND))
    )
    ;; Validate roles
    (asserts! (is-eq (get role parent-user) ROLE-PARENT) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get role child-user) ROLE-STUDENT) ERR-NOT-AUTHORIZED)

    ;; Create parent-child link
    (map-set parent-children
      { parent-id: parent-id, child-id: child-id }
      { approved: true }
    )

    (ok true)
  )
)

;; Deactivate user (admin only)
(define-public (deactivate-user (user-principal principal))
  (let
    (
      (admin-data (unwrap! (map-get? user-principals { principal: tx-sender }) ERR-USER-NOT-FOUND))
      (admin-id (get user-id admin-data))
      (admin-user (unwrap! (map-get? users { user-id: admin-id }) ERR-USER-NOT-FOUND))
      (target-data (unwrap! (map-get? user-principals { principal: user-principal }) ERR-USER-NOT-FOUND))
      (target-id (get user-id target-data))
      (target-user (unwrap! (map-get? users { user-id: target-id }) ERR-USER-NOT-FOUND))
    )
    ;; Only admins can deactivate users
    (asserts! (is-eq (get role admin-user) ROLE-ADMIN) ERR-NOT-AUTHORIZED)

    ;; Update user status
    (map-set users
      { user-id: target-id }
      (merge target-user { active: false })
    )

    (ok true)
  )
)

;; Read-only Functions

;; Get user by principal
(define-read-only (get-user (user-principal principal))
  (match (map-get? user-principals { principal: user-principal })
    user-data
      (map-get? users { user-id: (get user-id user-data) })
    none
  )
)

;; Get user by ID
(define-read-only (get-user-by-id (user-id uint))
  (map-get? users { user-id: user-id })
)

;; Check if user has role
(define-read-only (has-role (user-principal principal) (required-role uint))
  (match (get-user user-principal)
    user-data
      (and
        (is-eq (get role user-data) required-role)
        (get active user-data)
      )
    false
  )
)

;; Check if parent-child relationship exists
(define-read-only (is-parent-of (parent-principal principal) (child-principal principal))
  (match (map-get? user-principals { principal: parent-principal })
    parent-data
      (match (map-get? user-principals { principal: child-principal })
        child-data
          (is-some (map-get? parent-children
            {
              parent-id: (get user-id parent-data),
              child-id: (get user-id child-data)
            }
          ))
        false
      )
    false
  )
)

;; Get total user count
(define-read-only (get-user-count)
  (- (var-get next-user-id) u1)
)

;; Check if user is active
(define-read-only (is-user-active (user-principal principal))
  (match (get-user user-principal)
    user-data (get active user-data)
    false
  )
)
