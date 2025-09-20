;; Community Solar Farm Investment Contract
;; Enables fractional ownership of renewable energy projects

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INSUFFICIENT_FUNDS (err u101))
(define-constant ERR_INVALID_AMOUNT (err u102))
(define-constant ERR_FARM_NOT_FOUND (err u103))
(define-constant ERR_FARM_INACTIVE (err u104))
(define-constant ERR_ALREADY_INVESTED (err u105))
(define-constant ERR_NO_INVESTMENT (err u106))
(define-constant ERR_FARM_FULL (err u107))
(define-constant ERR_WITHDRAWAL_TOO_EARLY (err u108))
(define-constant ERR_INSUFFICIENT_SHARES (err u109))

;; Data Variables
(define-data-var next-farm-id uint u1)
(define-data-var total-farms uint u0)
(define-data-var platform-fee-rate uint u500) ;; 5% (500/10000)

;; Data Maps
(define-map solar-farms
    { farm-id: uint }
    {
        owner: principal,
        name: (string-ascii 64),
        location: (string-ascii 64),
        capacity-kwh: uint,
        cost-per-share: uint,
        total-shares: uint,
        shares-sold: uint,
        is-active: bool,
        created-at: uint,
        expected-roi: uint,
        project-duration: uint
    }
)

(define-map investments
    { investor: principal, farm-id: uint }
    {
        shares-owned: uint,
        investment-amount: uint,
        invested-at: uint,
        total-returns: uint
    }
)

(define-map farm-investors
    { farm-id: uint }
    { investor-count: uint }
)

(define-map user-portfolio
    { user: principal }
    { total-invested: uint, farms-count: uint }
)

;; Read-only functions
(define-read-only (get-farm-details (farm-id uint))
    (map-get? solar-farms { farm-id: farm-id })
)

(define-read-only (get-investment-details (investor principal) (farm-id uint))
    (map-get? investments { investor: investor, farm-id: farm-id })
)

(define-read-only (get-user-portfolio (user principal))
    (map-get? user-portfolio { user: user })
)

(define-read-only (get-platform-stats)
    {
        total-farms: (var-get total-farms),
        next-farm-id: (var-get next-farm-id),
        platform-fee-rate: (var-get platform-fee-rate)
    }
)

(define-read-only (calculate-investment-return (investor principal) (farm-id uint))
    (let (
        (investment (unwrap! (get-investment-details investor farm-id) (err ERR_NO_INVESTMENT)))
        (farm (unwrap! (get-farm-details farm-id) (err ERR_FARM_NOT_FOUND)))
        (base-return (* (get investment-amount investment) (get expected-roi farm)))
        (time-multiplier (- block-height (get invested-at investment)))
    )
    (ok (/ (* base-return time-multiplier) u525600)) ;; Approximate blocks per year
    )
)

(define-read-only (get-farm-availability (farm-id uint))
    (let (
        (farm (unwrap! (get-farm-details farm-id) (err ERR_FARM_NOT_FOUND)))
    )
    (ok {
        shares-available: (- (get total-shares farm) (get shares-sold farm)),
        percentage-sold: (/ (* (get shares-sold farm) u100) (get total-shares farm))
    })
    )
)

;; Private functions
(define-private (update-user-portfolio (user principal) (amount uint) (increment bool))
    (let (
        (current-portfolio (default-to { total-invested: u0, farms-count: u0 } 
                           (get-user-portfolio user)))
    )
    (map-set user-portfolio
        { user: user }
        {
            total-invested: (if increment 
                              (+ (get total-invested current-portfolio) amount)
                              (- (get total-invested current-portfolio) amount)),
            farms-count: (if increment
                           (+ (get farms-count current-portfolio) u1)
                           (get farms-count current-portfolio))
        }
    )
    )
)

;; Public functions

;; Create a new solar farm project
(define-public (create-solar-farm 
    (name (string-ascii 64))
    (location (string-ascii 64))
    (capacity-kwh uint)
    (cost-per-share uint)
    (total-shares uint)
    (expected-roi uint)
    (project-duration uint)
)
    (let (
        (farm-id (var-get next-farm-id))
    )
    (asserts! (> cost-per-share u0) ERR_INVALID_AMOUNT)
    (asserts! (> total-shares u0) ERR_INVALID_AMOUNT)
    (asserts! (> capacity-kwh u0) ERR_INVALID_AMOUNT)
    
    (map-set solar-farms
        { farm-id: farm-id }
        {
            owner: tx-sender,
            name: name,
            location: location,
            capacity-kwh: capacity-kwh,
            cost-per-share: cost-per-share,
            total-shares: total-shares,
            shares-sold: u0,
            is-active: true,
            created-at: block-height,
            expected-roi: expected-roi,
            project-duration: project-duration
        }
    )
    
    (map-set farm-investors
        { farm-id: farm-id }
        { investor-count: u0 }
    )
    
    (var-set next-farm-id (+ farm-id u1))
    (var-set total-farms (+ (var-get total-farms) u1))
    
    (ok farm-id)
    )
)

;; Invest in a solar farm
(define-public (invest-in-farm (farm-id uint) (shares uint))
    (let (
        (farm (unwrap! (get-farm-details farm-id) ERR_FARM_NOT_FOUND))
        (investment-amount (* shares (get cost-per-share farm)))
        (platform-fee (/ (* investment-amount (var-get platform-fee-rate)) u10000))
        (net-investment (- investment-amount platform-fee))
        (existing-investment (get-investment-details tx-sender farm-id))
    )
    (asserts! (get is-active farm) ERR_FARM_INACTIVE)
    (asserts! (> shares u0) ERR_INVALID_AMOUNT)
    (asserts! (<= (+ shares (get shares-sold farm)) (get total-shares farm)) ERR_FARM_FULL)
    (asserts! (is-none existing-investment) ERR_ALREADY_INVESTED)
    
    ;; Transfer STX from investor
    (try! (stx-transfer? investment-amount tx-sender (as-contract tx-sender)))
    
    ;; Transfer platform fee to contract owner
    (try! (as-contract (stx-transfer? platform-fee tx-sender CONTRACT_OWNER)))
    
    ;; Record investment
    (map-set investments
        { investor: tx-sender, farm-id: farm-id }
        {
            shares-owned: shares,
            investment-amount: net-investment,
            invested-at: block-height,
            total-returns: u0
        }
    )
    
    ;; Update farm shares sold
    (map-set solar-farms
        { farm-id: farm-id }
        (merge farm { shares-sold: (+ (get shares-sold farm) shares) })
    )
    
    ;; Update investor count
    (let (
        (current-investors (default-to { investor-count: u0 } 
                           (map-get? farm-investors { farm-id: farm-id })))
    )
    (map-set farm-investors
        { farm-id: farm-id }
        { investor-count: (+ (get investor-count current-investors) u1) }
    )
    )
    
    ;; Update user portfolio
    (update-user-portfolio tx-sender net-investment true)
    
    (ok shares)
    )
)

;; Distribute returns to investors
(define-public (distribute-returns (farm-id uint) (total-return uint))
    (let (
        (farm (unwrap! (get-farm-details farm-id) ERR_FARM_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get owner farm)) ERR_NOT_AUTHORIZED)
    (asserts! (get is-active farm) ERR_FARM_INACTIVE)
    (asserts! (> total-return u0) ERR_INVALID_AMOUNT)
    
    ;; This would need to be called separately for each investor
    ;; Implementation simplified for contract size constraints
    (ok total-return)
    )
)

;; Withdraw investment (after project duration)
(define-public (withdraw-investment (farm-id uint))
    (let (
        (farm (unwrap! (get-farm-details farm-id) ERR_FARM_NOT_FOUND))
        (investment (unwrap! (get-investment-details tx-sender farm-id) ERR_NO_INVESTMENT))
        (time-elapsed (- block-height (get created-at farm)))
    )
    (asserts! (> time-elapsed (get project-duration farm)) ERR_WITHDRAWAL_TOO_EARLY)
    
    (let (
        (withdrawal-amount (get investment-amount investment))
        (return-amount (unwrap! (calculate-investment-return tx-sender farm-id) ERR_NO_INVESTMENT))
        (total-withdrawal (+ withdrawal-amount return-amount))
    )
    
    ;; Transfer funds back to investor
    (try! (as-contract (stx-transfer? total-withdrawal tx-sender tx-sender)))
    
    ;; Remove investment record
    (map-delete investments { investor: tx-sender, farm-id: farm-id })
    
    ;; Update user portfolio
    (update-user-portfolio tx-sender withdrawal-amount false)
    
    (ok total-withdrawal)
    )
    )
)

;; Admin functions
(define-public (update-platform-fee (new-fee-rate uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (asserts! (<= new-fee-rate u1000) ERR_INVALID_AMOUNT) ;; Max 10%
        (var-set platform-fee-rate new-fee-rate)
        (ok true)
    )
)

(define-public (toggle-farm-status (farm-id uint))
    (let (
        (farm (unwrap! (get-farm-details farm-id) ERR_FARM_NOT_FOUND))
    )
    (asserts! (or (is-eq tx-sender CONTRACT_OWNER) 
                  (is-eq tx-sender (get owner farm))) ERR_NOT_AUTHORIZED)
    
    (map-set solar-farms
        { farm-id: farm-id }
        (merge farm { is-active: (not (get is-active farm)) })
    )
    
    (ok (not (get is-active farm)))
    )
)