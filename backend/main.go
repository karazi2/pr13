package main

import (

	"database/sql"
    "time" // Для работы с временем
    "log"
    "net/http"
    "github.com/google/uuid"
	"github.com/gin-gonic/gin"
	_ "github.com/lib/pq"
	"github.com/lib/pq"
)


type Apartment struct {
	ID           int     `json:"id"`
	Title        string  `json:"title"`
	Address      string  `json:"address"`
	ImageLink    string  `json:"image_link"`
	Description  string  `json:"description"`
	SquareMeters int     `json:"square_meters"`
	Bedrooms     int     `json:"bedrooms"`
	Price        float64 `json:"price"`
	Favourite    bool    `json:"favourite"`
}

type CartItem struct {
    ID          int    `json:"id"`
    ApartmentID int    `json:"apartment_id"`
    UserID      string `json:"user_id"` // UUID как строка
    Quantity    int    `json:"quantity"`
    Price       float64 `json:"price"`
    Title       string  `json:"title"`
    PhotoID     *string `json:"photo_id,omitempty"` // Может быть nil
}


var db *sql.DB

func initDB() {
	var err error
	connStr := "host=localhost port=5432 user=postgres password=1111 dbname=apartments_db sslmode=disable"
	db, err = sql.Open("postgres", connStr)
	if err != nil {
		log.Fatalf("Ошибка подключения к базе данных: %v", err)
	}

	err = db.Ping()
	if err != nil {
		log.Fatalf("Не удалось подключиться к базе данных: %v", err)
	}

	log.Println("Подключение к базе данных успешно выполнено!")
}
func getOrdersHandler(c *gin.Context) {
    userID := c.Param("user_id")

    rows, err := db.Query(`
        SELECT o.id, o.total_price, o.created_at,
               json_agg(json_build_object(
                   'apartment_id', oi.apartment_id,
                   'quantity', oi.quantity,
                   'title', a.title
               )) AS items
        FROM orders o
        LEFT JOIN order_items oi ON o.id = oi.order_id
        LEFT JOIN apartments a ON oi.apartment_id = a.id
        WHERE o.user_id = $1
        GROUP BY o.id
        ORDER BY o.created_at DESC
    `, userID)
    if err != nil {
        log.Println("Ошибка выполнения SQL-запроса:", err)
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка выполнения запроса к базе данных"})
        return
    }
    defer rows.Close()

    var orders []map[string]interface{}
    for rows.Next() {
        var id int
        var totalPrice float64
        var createdAt string
        var items string

        if err := rows.Scan(&id, &totalPrice, &createdAt, &items); err != nil {
            log.Println("Ошибка обработки строки:", err)
            c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка обработки данных заказа"})
            return
        }

        orders = append(orders, map[string]interface{}{
            "id":          id,
            "total_price": totalPrice,
            "created_at":  createdAt,
            "items":       items,
        })
    }

    c.JSON(http.StatusOK, orders)
}

func createChatHandler(c *gin.Context) {
    var request struct {
        Participants []string `json:"participants"` // Участники чата
    }

    if err := c.ShouldBindJSON(&request); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Некорректный формат JSON"})
        return
    }

    chatID := uuid.New()
    query := `INSERT INTO chats (id, participants) VALUES ($1, $2)`
    _, err := db.Exec(query, chatID, pq.Array(request.Participants))

    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка создания чата"})
        return
    }

    c.JSON(http.StatusOK, gin.H{"message": "Чат создан", "chat_id": chatID})
}
func sendMessageHandler(c *gin.Context) {
	var request struct {
		ChatID   string `json:"chat_id"`
		SenderID string `json:"sender_id"`
		Message  string `json:"message"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Некорректный формат JSON"})
		return
	}

	query := `
		INSERT INTO messages (id, chat_id, sender_id, message, timestamp)
		VALUES ($1, $2, $3, $4, $5)
	`
	messageID := uuid.New().String() // Генерация нового уникального идентификатора для сообщения
	_, err := db.Exec(query, messageID, request.ChatID, request.SenderID, request.Message, time.Now().Unix())
	if err != nil {
		log.Println("Ошибка при добавлении сообщения:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка отправки сообщения"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Сообщение отправлено"})
}

func getApartmentsHandler(c *gin.Context) {
	rows, err := db.Query("SELECT id, title, address, image_link, description, square_meters, bedrooms, price, favourite FROM apartments")
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка получения данных"})
		return
	}
	defer rows.Close()

	var apartments []Apartment
	for rows.Next() {
		var a Apartment
		if err := rows.Scan(&a.ID, &a.Title, &a.Address, &a.ImageLink, &a.Description, &a.SquareMeters, &a.Bedrooms, &a.Price, &a.Favourite); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка обработки данных"})
			return
		}
		apartments = append(apartments, a)
	}

	c.JSON(http.StatusOK, apartments)
}

func createApartmentHandler(c *gin.Context) {
	var newApartment Apartment
	if err := c.ShouldBindJSON(&newApartment); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Некорректный формат JSON"})
		return
	}

	query := `
		INSERT INTO apartments (title, address, image_link, description, square_meters, bedrooms, price, favourite)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id
	`
	err := db.QueryRow(query, newApartment.Title, newApartment.Address, newApartment.ImageLink, newApartment.Description,
		newApartment.SquareMeters, newApartment.Bedrooms, newApartment.Price, newApartment.Favourite).Scan(&newApartment.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка при добавлении квартиры"})
		return
	}

	c.JSON(http.StatusOK, newApartment)
}

func getApartmentByIDHandler(c *gin.Context) {
	id := c.Param("id")

	var apartment Apartment
	query := "SELECT id, title, address, image_link, description, square_meters, bedrooms, price, favourite FROM apartments WHERE id = $1"
	err := db.QueryRow(query, id).Scan(&apartment.ID, &apartment.Title, &apartment.Address, &apartment.ImageLink, &apartment.Description, &apartment.SquareMeters, &apartment.Bedrooms, &apartment.Price, &apartment.Favourite)
	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, gin.H{"error": "Квартира не найдена"})
		return
	} else if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка при получении данных"})
		return
	}

	c.JSON(http.StatusOK, apartment)
}


func updateApartmentHandler(c *gin.Context) {
	id := c.Param("id")

	var updatedFields Apartment
	if err := c.ShouldBindJSON(&updatedFields); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Некорректный формат JSON"})
		return
	}

	query := `
		UPDATE apartments
		SET title = COALESCE(NULLIF($1, ''), title),
		    address = COALESCE(NULLIF($2, ''), address),
		    image_link = COALESCE(NULLIF($3, ''), image_link),
		    description = COALESCE(NULLIF($4, ''), description),
		    square_meters = COALESCE(NULLIF($5::int, 0), square_meters),
		    bedrooms = COALESCE(NULLIF($6::int, 0), bedrooms),
		    price = COALESCE(NULLIF($7::numeric, 0), price),
		    favourite = COALESCE($8, favourite)
		WHERE id = $9
	`
	_, err := db.Exec(query, updatedFields.Title, updatedFields.Address, updatedFields.ImageLink, updatedFields.Description,
		updatedFields.SquareMeters, updatedFields.Bedrooms, updatedFields.Price, updatedFields.Favourite, id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка при обновлении данных"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Квартира обновлена"})
}
func createOrderHandler(c *gin.Context) {
    var order struct {
        UserID string     `json:"user_id"`
        Items  []CartItem `json:"items"`
    }

    if err := c.ShouldBindJSON(&order); err != nil {
        log.Println("Ошибка привязки JSON:", err)
        c.JSON(http.StatusBadRequest, gin.H{"error": "Некорректный формат данных"})
        return
    }

    log.Printf("Создание заказа для пользователя: %s", order.UserID)

    // Рассчитываем общую стоимость
    var totalPrice float64
    for _, item := range order.Items {
        totalPrice += item.Price * float64(item.Quantity)
    }

    // Создание записи заказа
    var orderID int
    query := `INSERT INTO orders (user_id, total_price) VALUES ($1, $2) RETURNING id`
    err := db.QueryRow(query, order.UserID, totalPrice).Scan(&orderID)
    if err != nil {
        log.Println("Ошибка создания заказа:", err)
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка создания заказа"})
        return
    }

    // Добавляем элементы заказа
    for _, item := range order.Items {
        query = `INSERT INTO order_items (order_id, apartment_id, quantity) VALUES ($1, $2, $3)`
        _, err = db.Exec(query, orderID, item.ApartmentID, item.Quantity)
        if err != nil {
            log.Println("Ошибка добавления элементов заказа:", err)
            c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка добавления элементов заказа"})
            return
        }
    }

    // Очищаем корзину пользователя
    _, err = db.Exec("DELETE FROM cart WHERE user_id = $1", order.UserID)
    if err != nil {
        log.Println("Ошибка очистки корзины:", err)
    }

    c.JSON(http.StatusOK, gin.H{"message": "Заказ успешно создан", "order_id": orderID})
}

// Вспомогательная функция для получения цены квартиры
func getApartmentPrice(apartmentID int) float64 {
    var price float64
    err := db.QueryRow("SELECT price FROM apartments WHERE id = $1", apartmentID).Scan(&price)
    if err != nil {
        log.Printf("Ошибка получения цены квартиры ID=%d: %v", apartmentID, err)
        return 0.0
    }
    return price
}

func getCartHandler(c *gin.Context) {
    userID := c.Param("user_id")
    rows, err := db.Query("SELECT id, apartment_id, user_id, quantity FROM cart WHERE user_id = $1", userID)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка получения данных корзины"})
        return
    }
    defer rows.Close()

    var cartItems []CartItem
    for rows.Next() {
        var item CartItem
        if err := rows.Scan(&item.ID, &item.ApartmentID, &item.UserID, &item.Quantity); err != nil {
            c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка обработки данных корзины"})
            return
        }
        cartItems = append(cartItems, item)
    }

    c.JSON(http.StatusOK, cartItems)
}

func addToCartHandler(c *gin.Context) {
    var item CartItem

    // Привязка JSON
    if err := c.ShouldBindJSON(&item); err != nil {
        log.Println("Ошибка привязки JSON:", err)
        c.JSON(http.StatusBadRequest, gin.H{"error": "Некорректный формат JSON"})
        return
    }

    log.Printf("Полученные данные: %+v\n", item)

    // Проверка существования пользователя
    var userExists bool
    err := db.QueryRow("SELECT EXISTS(SELECT 1 FROM users WHERE id = $1)", item.UserID).Scan(&userExists)
    if err != nil {
        log.Println("Ошибка проверки пользователя:", err)
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка проверки пользователя"})
        return
    }

    // Автоматическое добавление пользователя, если его нет
    if !userExists {
        _, err := db.Exec("INSERT INTO users (id, name, email) VALUES ($1, $2, $3)",
            item.UserID, "Новый пользователь", "default@example.com")
        if err != nil {
            log.Println("Ошибка создания пользователя:", err)
            c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка создания пользователя"})
            return
        }
        log.Printf("Пользователь создан автоматически: %s\n", item.UserID)
    }

    // SQL-запрос для добавления в корзину
    query := `
        INSERT INTO cart (apartment_id, user_id, quantity)
        VALUES ($1, $2, $3)
        ON CONFLICT (apartment_id, user_id) DO UPDATE SET quantity = cart.quantity + $3
        RETURNING id, apartment_id, user_id, quantity
    `
    err = db.QueryRow(query, item.ApartmentID, item.UserID, item.Quantity).Scan(
        &item.ID, &item.ApartmentID, &item.UserID, &item.Quantity,
    )
    if err != nil {
        log.Println("Ошибка выполнения SQL-запроса:", err)
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка добавления в корзину"})
        return
    }

    c.JSON(http.StatusOK, item)
}




func removeFromCartHandler(c *gin.Context) {
	userID := c.Param("user_id")
	apartmentID := c.Param("apartment_id")

	query := "DELETE FROM cart WHERE user_id = $1 AND apartment_id = $2"
	_, err := db.Exec(query, userID, apartmentID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка удаления из корзины"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Элемент удален из корзины"})
}


func deleteApartmentHandler(c *gin.Context) {
	id := c.Param("id")

	query := "DELETE FROM apartments WHERE id = $1"
	_, err := db.Exec(query, id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка при удалении квартиры"})
		return
	}

	c.JSON(http.StatusNoContent, gin.H{"message": "Квартира удалена"})
}

func toggleFavouriteHandler(c *gin.Context) {
	id := c.Param("id")

	query := `
		UPDATE apartments
		SET favourite = NOT favourite
		WHERE id = $1
	`
	_, err := db.Exec(query, id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка обновления статуса избранного"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Статус избранного обновлен"})
}
// Функция для создания чата или получения существующего
func createOrGetChatHandler(c *gin.Context) {
	var request struct {
		Participants []string `json:"participants"` // Участники чата
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		log.Println("Ошибка привязки JSON:", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": "Некорректный формат JSON"})
		return
	}

	// ID, которые должны быть "привязаны"
	const userA = "317ea524-9e31-44ec-a075-fb2d2aff8d54"
	const userB = "a64e3a3b-dc64-40ec-bbb5-090b2abef034"

	// Логика подстановки:
	var participantA, participantB string

	if request.Participants[0] == userA {
		participantA = userA
		participantB = userB
	} else {
		participantA = request.Participants[0]
		participantB = userA
	}

	// Проверяем существующий чат
	var chatID string
	query := `SELECT id FROM chats WHERE participants @> $1 LIMIT 1`
    err := db.QueryRow(query, pq.Array([]string{participantA, participantB})).Scan(&chatID)

	if err == nil {
		// Чат уже существует
		c.JSON(http.StatusOK, gin.H{"message": "Чат найден", "chat_id": chatID})
		return
	}

	// Ошибка кроме ErrNoRows
	if err != nil && err != sql.ErrNoRows {
		log.Println("Ошибка при проверке существования чата:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка проверки чатов"})
		return
	}

	// Чат не найден - создаем новый
	chatID = uuid.New().String()
	query = `INSERT INTO chats (id, participants) VALUES ($1, $2)`
	_, err = db.Exec(query, chatID, pq.Array([]string{participantA, participantB}))
	if err != nil {
		log.Println("Ошибка при создании чата:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка создания чата"})
		return
	}

	log.Printf("Создан новый чат: %s между %s и %s", chatID, participantA, participantB)
	c.JSON(http.StatusOK, gin.H{"message": "Чат создан", "chat_id": chatID})
}

func getMessagesHandler(c *gin.Context) {
   chatID := c.Param("chat_id")
    log.Printf("Получен запрос на получение сообщений для chat_id: %s", chatID)

    if chatID == "" {
        log.Println("Ошибка: chat_id отсутствует в запросе")
        c.JSON(http.StatusBadRequest, gin.H{"error": "Missing chat_id"})
        return
    }

    // Проверяем наличие сообщений
    log.Println("Выполняем SQL-запрос для получения сообщений")
    rows, err := db.Query("SELECT sender_id, message, created_at FROM messages WHERE chat_id = $1 ORDER BY created_at", chatID)
    if err != nil {
        log.Printf("Ошибка при выполнении SQL-запроса: %v", err)
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Error querying messages"})
        return
    }
    defer rows.Close()

    var messages []map[string]interface{}
    for rows.Next() {
        var senderID, message string
        var createdAt time.Time
        if err := rows.Scan(&senderID, &message, &createdAt); err != nil {
            log.Printf("Ошибка при сканировании строки: %v", err)
            c.JSON(http.StatusInternalServerError, gin.H{"error": "Error scanning messages"})
            return
        }
        messages = append(messages, map[string]interface{}{
            "sender_id": senderID,
            "message":   message,
            "created_at": createdAt,
        })
    }

    if len(messages) == 0 {
        log.Printf("Для chat_id=%s сообщений не найдено", chatID)
        c.JSON(http.StatusNotFound, gin.H{"error": "Messages not found"})
        return
    }

    log.Printf("Отправляем %d сообщений для chat_id=%s", len(messages), chatID)
    c.JSON(http.StatusOK, messages)
}


func main() {

	initDB()

	r := gin.Default()



	r.GET("/apartments", getApartmentsHandler)
	r.POST("/apartments/create", createApartmentHandler)
	r.GET("/apartments/:id", getApartmentByIDHandler)
	r.PUT("/apartments/update/:id", updateApartmentHandler)
	r.DELETE("/apartments/delete/:id", deleteApartmentHandler)
	r.PUT("/apartments/favourite/:id", toggleFavouriteHandler)
    r.GET("/cart/:user_id", getCartHandler)
    r.POST("/cart", addToCartHandler)
    r.DELETE("/cart/:user_id/:apartment_id", removeFromCartHandler)
    r.POST("/orders", createOrderHandler)
    r.GET("/orders/:user_id", getOrdersHandler)
          // Создать чат
    r.POST("/messages", sendMessageHandler)    // Отправить сообщение
    r.GET("/messages/:chat_id", getMessagesHandler) // Получить сообщения
    r.POST("/chats", createOrGetChatHandler)

	log.Println("Сервер запущен на порту 8080")
	r.Run(":8080")
}
