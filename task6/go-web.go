package main

import (
	"context"
	"fmt"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
)

var ctx = context.Background()

func main() {
	rdb := redis.NewClient(&redis.Options{
		Addr:     fmt.Sprintf("%s:%s", os.Getenv("REDIS_HOST"), os.Getenv("REDIS_PORT")),
		Password: os.Getenv("REDIS_PASSWORD"),
		Username: os.Getenv("REDIS_USER"),
		DB:       0,
	})

	r := gin.Default()

	r.GET("/get", func(c *gin.Context) {
		username, err := rdb.Get(ctx, "username").Result()
		if err != nil {
			c.JSON(500, gin.H{"code": 500, "msg": err.Error()})
			return
		}

		password, err := rdb.Get(ctx, "password").Result()
		if err != nil {
			c.JSON(500, gin.H{"code": 500, "msg": err.Error()})
			return
		}

		c.JSON(200, gin.H{
			"code":     200,
			"username": username,
			"password": password,
		})
	})

	r.Run(":8080")
}
