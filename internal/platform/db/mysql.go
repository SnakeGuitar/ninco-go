package db

import (
	"database/sql"
	"fmt"
	"time"

	_ "github.com/go-sql-driver/mysql"
)

// Config holds the database connection settings.
type Config struct {
	User            string
	Password        string
	Host            string
	Port            string
	Database        string
	MaxIdleConns    int
	MaxOpenConns    int
	ConnMaxLifetime time.Duration
}

// CreateConnection creates a new connection to the database
func CreateConnection(cfg Config) (*sql.DB, error) {
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		cfg.User, cfg.Password, cfg.Host, cfg.Port, cfg.Database)

	db, err := sql.Open("mysql", dsn)
	if err != nil {
		return nil, fmt.Errorf("Error opening connection: %w", err)
	}

	SetConfiguration(db, cfg)
	if err := Ping(db); err != nil {
		db.Close()
		return nil, err
	}

	return db, nil
}

// CloseConnection closes the database connection.
func CloseConnection(db *sql.DB) error {
	return db.Close()
}

// Ping checks if the database is reachable.
func Ping(db *sql.DB) error {
	if err := db.Ping(); err != nil {
		return fmt.Errorf("error pinging database: %w", err)
	}
	return nil
}

// SetConfiguration applies the pool settings to the database connection.
func SetConfiguration(db *sql.DB, cfg Config) {
	db.SetMaxIdleConns(cfg.MaxIdleConns)
	db.SetMaxOpenConns(cfg.MaxOpenConns)
	db.SetConnMaxLifetime(cfg.ConnMaxLifetime)
}
