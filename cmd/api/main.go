package main

import (
	"log"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/SnakeGuitar/Ninco-Go/internal/api/handler"
	"github.com/SnakeGuitar/Ninco-Go/internal/platform/db"
)

func main() {
	// 1. Setup Database Configuration from Environment
	cfg := db.Config{
		User:            os.Getenv("DB_USER"),
		Password:        os.Getenv("DB_PASSWORD"),
		Host:            os.Getenv("DB_HOST"),
		Port:            os.Getenv("DB_PORT"),
		Database:        os.Getenv("DB_NAME"),
		MaxIdleConns:    10,
		MaxOpenConns:    100,
		ConnMaxLifetime: time.Hour,
	}

	// 2. Initialize Database Connection
	database, err := db.CreateConnection(cfg)
	if err != nil {
		log.Printf("Warning: Could not connect to database: %v", err)
		log.Println("The API will run, but database features will fail.")
	} else {
		defer database.Close()
		log.Println("Database connection established successfully")
	}

	// 3. Initialize Gin Router
	r := gin.Default()

	// 4. Define Routes
	api := r.Group("/api/v1")
	{
		api.GET("/health", handler.HealthCheck)
		
		// Future routes will go here:
		// api.POST("/auth/login", handler.Login)
		// api.GET("/stores", handler.GetStores)
	}

	// 5. Start Server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server starting on port %s...", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Critical error: Could not start server: %v", err)
	}
}
