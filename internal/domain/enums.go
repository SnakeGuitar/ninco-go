package domain

// Role represents the account role
type Role string

const (
	RoleAdmin   Role = "ADMIN"
	RoleCashier Role = "CASHIER"
)

// State represents the entity state
type State string

const (
	StateActive   State = "ACTIVE"
	StateInactive State = "INACTIVE"
)

// Action represents an audit action (if needed later)
type Action string

const (
	ActionCreate Action = "CREATE"
	ActionUpdate Action = "UPDATE"
	ActionDelete Action = "DELETE"
)
