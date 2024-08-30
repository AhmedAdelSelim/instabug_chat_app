package main

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	_ "github.com/go-sql-driver/mysql"
	"github.com/streadway/amqp"
)

var db *sql.DB
var rabbitMQChannel *amqp.Channel

func main() {
    var err error
    db, err = sql.Open("mysql", "root:password@tcp(db:3306)/chat_system")
    if err != nil {
        log.Fatal(err)
    }
    defer db.Close()

    // Setup RabbitMQ
    conn, err := amqp.Dial("amqp://guest:guest@rabbitmq:5672/")
    if err != nil {
        log.Fatal(err)
    }
    defer conn.Close()

    rabbitMQChannel, err = conn.Channel()
    if err != nil {
        log.Fatal(err)
    }
    defer rabbitMQChannel.Close()

    r := gin.Default()

    r.POST("/applications/:token/chats", createChat)
    r.POST("/applications/:token/chats/:chat_number/messages", createMessage)

    r.Run(":8080")
}

func createChat(c *gin.Context) {
    token := c.Param("token")

    var appID int
    err := db.QueryRow("SELECT id FROM applications WHERE token = ?", token).Scan(&appID)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "Application not found"})
        return
    }

    var chatNumber int
    err = db.QueryRow("SELECT COALESCE(MAX(number), 0) + 1 FROM chats WHERE application_id = ?", appID).Scan(&chatNumber)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Error creating chat"})
        return
    }

    _, err = db.Exec("INSERT INTO chats (application_id, number) VALUES (?, ?)", appID, chatNumber)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Error creating chat"})
        return
    }

    // Publish to RabbitMQ
    err = publishChatCountUpdate(appID)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Error queueing chat count update"})
        return
    }

    c.JSON(http.StatusCreated, gin.H{"chat_number": chatNumber})
}

func createMessage(c *gin.Context) {
    token := c.Param("token")
    chatNumber, _ := strconv.Atoi(c.Param("chat_number"))

    var chatID int
    err := db.QueryRow(`
        SELECT c.id FROM chats c
        JOIN applications a ON c.application_id = a.id
        WHERE a.token = ? AND c.number = ?`, token, chatNumber).Scan(&chatID)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "Chat not found"})
        return
    }

    var messageNumber int
    err = db.QueryRow("SELECT COALESCE(MAX(number), 0) + 1 FROM messages WHERE chat_id = ?", chatID).Scan(&messageNumber)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Error creating message"})
        return
    }

    var input struct {
        Body string `json:"body"`
    }
    if err := c.BindJSON(&input); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
        return
    }

    _, err = db.Exec("INSERT INTO messages (chat_id, number, body) VALUES (?, ?, ?)", chatID, messageNumber, input.Body)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Error creating message"})
        return
    }

    // Publish to RabbitMQ
    err = publishMessageCountUpdate(chatID)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Error queueing message count update"})
        return
    }

    c.JSON(http.StatusCreated, gin.H{"message_number": messageNumber})
}

func publishChatCountUpdate(applicationID int) error {
    return rabbitMQChannel.Publish(
        "",
        "chat_count",
        false,
        false,
        amqp.Publishing{
            ContentType: "text/plain",
            Body:        []byte(fmt.Sprintf("%d", applicationID)),
        })
}

func publishMessageCountUpdate(chatID int) error {
    return rabbitMQChannel.Publish(
        "",
        "message_count",
        false,
        false,
        amqp.Publishing{
            ContentType: "text/plain",
            Body:        []byte(fmt.Sprintf("%d", chatID)),
        })
}
