package domain

import (
	"time"
)

// Account represents a user account for authentication
type Account struct {
	ID       int    `json:"id"`
	Email    string `json:"email"`
	Password string `json:"-"` // Never export password in JSON
	Role     Role   `json:"role"`
	State    State  `json:"state"`
}

// Store represents a physical branch/store
type Store struct {
	ID      int    `json:"id"`
	Name    string `json:"name"`
	Address string `json:"address"`
	Phone   string `json:"phone"`
}

// Employee represents a person working in a store
type Employee struct {
	ID       int    `json:"id"`
	Account  *Account `json:"account,omitempty"`
	StoreID  int    `json:"store_id"`
	Name     string `json:"name"`
	Surname  string `json:"surname"`
	Phone    string `json:"phone"`
	State    State  `json:"state"`
}

// Product represents an item for sale
type Product struct {
	ID          int     `json:"id"`
	Category    string  `json:"category"` // Simplified for now
	Name        string  `json:"name"`
	Description string  `json:"description"`
	Brand       string  `json:"brand"`
	Measure     string  `json:"measure"`
	Price       float64 `json:"price"`
}

// Stock represents the quantity of a product in a specific store
type Stock struct {
	ID        int      `json:"id"`
	StoreID   int      `json:"store_id"`
	ProductID int      `json:"product_id"`
	Quantity  int      `json:"quantity"`
	Product   *Product `json:"product,omitempty"`
}

// Invoice represents a sale transaction header
type Invoice struct {
	ID         int       `json:"id"`
	StoreID    int       `json:"store_id"`
	EmployeeID int       `json:"employee_id"`
	Date       time.Time `json:"date"`
	Total      float64   `json:"total"`
	Items      []Detail  `json:"items,omitempty"`
}

// Detail represents a line item in an invoice or sale
type Detail struct {
	ID        int     `json:"id"`
	ParentID  int     `json:"parent_id"`
	ProductID int     `json:"product_id"`
	Quantity  int     `json:"quantity"`
	Price     float64 `json:"price"`
	Subtotal  float64 `json:"subtotal"`
}
