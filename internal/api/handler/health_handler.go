package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// HealthCheck returns the status of the API
func HealthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Ninco Go API is running",
		"version": "1.0.0",
	})
}
