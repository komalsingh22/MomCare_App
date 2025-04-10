package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/gorilla/mux"
	"github.com/joho/godotenv"
	_ "github.com/lib/pq"
)

// Database connection
var db *sql.DB

// Models
type HealthData struct {
	ID              int64      `json:"id"`
	Timestamp       time.Time  `json:"timestamp"`
	PregnancyMonth  *int       `json:"pregnancyMonth,omitempty"`
	DueDate         *string    `json:"dueDate,omitempty"`
	Weight          *string    `json:"weight,omitempty"`
	Height          *string    `json:"height,omitempty"`
	SystolicBP      *string    `json:"systolicBP,omitempty"`
	DiastolicBP     *string    `json:"diastolicBP,omitempty"`
	Temperature     *string    `json:"temperature,omitempty"`
	Hemoglobin      *string    `json:"hemoglobin,omitempty"`
	Glucose         *string    `json:"glucose,omitempty"`
	Symptoms        *string    `json:"symptoms,omitempty"`
	DietaryLog      *string    `json:"dietaryLog,omitempty"`
	PhysicalActivity *string   `json:"physicalActivity,omitempty"`
	Supplements     *string    `json:"supplements,omitempty"`
	MoodRating      *float64   `json:"moodRating,omitempty"`
	HasAnxiety      *bool      `json:"hasAnxiety,omitempty"`
	AnxietyLevel    *float64   `json:"anxietyLevel,omitempty"`
}

type HealthAlert struct {
	ID          int64     `json:"id"`
	Title       string    `json:"title"`
	Message     string    `json:"message"`
	Severity    int       `json:"severity"`
	Timestamp   time.Time `json:"timestamp"`
	IsRead      bool      `json:"isRead"`
}

type Reminder struct {
	ID           int64     `json:"id"`
	Title        string    `json:"title"`
	Description  *string   `json:"description,omitempty"`
	ReminderType int       `json:"reminderType"`
	Date         string    `json:"date"`
	Time         string    `json:"time"`
	IsCompleted  bool      `json:"isCompleted"`
	CreatedAt    time.Time `json:"createdAt"`
	UpdatedAt    time.Time `json:"updatedAt"`
}

// AI Chat Models
type ChatRequest struct {
	Messages []ChatMessage `json:"messages"`
	UserInfo UserInfo      `json:"userInfo"`
}

type ChatMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type UserInfo struct {
	PregnancyMonth int    `json:"pregnancyMonth"`
	DueDate        string `json:"dueDate"`
	RecentSymptoms string `json:"recentSymptoms"`
}

type GeminiRequest struct {
	Contents []GeminiContent    `json:"contents"`
	SafetySettings []SafetySetting `json:"safetySettings"`
	GenerationConfig GeminiGenerationConfig `json:"generationConfig"`
}

type GeminiContent struct {
	Parts []GeminiPart `json:"parts"`
	Role  string       `json:"role,omitempty"`
}

type GeminiPart struct {
	Text string `json:"text"`
}

type SafetySetting struct {
	Category  string `json:"category"`
	Threshold string `json:"threshold"`
}

type GeminiGenerationConfig struct {
	Temperature     float64 `json:"temperature"`
	TopK            int     `json:"topK"`
	TopP            float64 `json:"topP"`
	MaxOutputTokens int     `json:"maxOutputTokens"`
}

type GeminiResponse struct {
	Candidates []struct {
		Content struct {
			Parts []struct {
				Text string `json:"text"`
			} `json:"parts"`
		} `json:"content"`
		FinishReason string `json:"finishReason"`
	} `json:"candidates"`
}

// Educational Content Models
type EducationalContent struct {
	ID          int64      `json:"id"`
	Title       string     `json:"title"`
	Content     string     `json:"content"`
	Category    string     `json:"category"`
	ImageURL    string     `json:"imageUrl,omitempty"`
	CreatedAt   time.Time  `json:"createdAt"`
	UpdatedAt   time.Time  `json:"updatedAt"`
}

type EducationalRequest struct {
	Query       string     `json:"query"`
	Category    string     `json:"category,omitempty"`
	Topics      []string   `json:"topics,omitempty"`
}

// CORS middleware to allow cross-origin requests
func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Get the origin from the request
		origin := r.Header.Get("Origin")
		
		// Allow all localhost origins or set to * if no origin
		if origin == "" {
			origin = "*"
		}
		
		// Set CORS headers for all responses
		w.Header().Set("Access-Control-Allow-Origin", origin)
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, Accept, X-Requested-With")
		w.Header().Set("Access-Control-Allow-Credentials", "true")
		w.Header().Set("Access-Control-Max-Age", "3600")
		
		// Handle preflight OPTIONS requests with a 200 OK response
		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}
		
		// Call the next handler for non-OPTIONS requests
		next.ServeHTTP(w, r)
	})
}

func init() {
	// Load .env file
	if err := godotenv.Load(); err != nil {
		log.Printf("No .env file found: %v", err)
	}

	// Get database URL from environment
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("DATABASE_URL environment variable is not set")
	}

	// Connect to PostgreSQL
	var err error
	db, err = sql.Open("postgres", dbURL)
	if err != nil {
		log.Fatalf("Error connecting to database: %v", err)
	}

	// Test connection
	if err = db.Ping(); err != nil {
		log.Fatalf("Error pinging database: %v", err)
	}

	// Create tables if they don't exist
	createTables()
}

func createTables() {
	// Health Data table
	_, err := db.Exec(`
		CREATE TABLE IF NOT EXISTS health_data (
			id SERIAL PRIMARY KEY,
			timestamp TIMESTAMP NOT NULL,
			pregnancy_month INTEGER,
			due_date TEXT,
			weight TEXT,
			height TEXT,
			systolic_bp TEXT,
			diastolic_bp TEXT,
			temperature TEXT,
			hemoglobin TEXT,
			glucose TEXT,
			symptoms TEXT,
			dietary_log TEXT,
			physical_activity TEXT,
			supplements TEXT,
			mood_rating FLOAT,
			has_anxiety BOOLEAN,
			anxiety_level FLOAT
		)
	`)
	if err != nil {
		log.Fatalf("Error creating health_data table: %v", err)
	}

	// Health Alerts table
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS health_alerts (
			id SERIAL PRIMARY KEY,
			title TEXT NOT NULL,
			message TEXT NOT NULL,
			severity INTEGER NOT NULL,
			timestamp TIMESTAMP NOT NULL,
			is_read BOOLEAN DEFAULT false
		)
	`)
	if err != nil {
		log.Fatalf("Error creating health_alerts table: %v", err)
	}

	// Reminders table
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS reminders (
			id SERIAL PRIMARY KEY,
			title TEXT NOT NULL,
			description TEXT,
			reminder_type INTEGER NOT NULL,
			date TEXT NOT NULL,
			time TEXT NOT NULL,
			is_completed BOOLEAN DEFAULT false,
			created_at TIMESTAMP NOT NULL,
			updated_at TIMESTAMP NOT NULL
		)
	`)
	if err != nil {
		log.Fatalf("Error creating reminders table: %v", err)
	}
	
	// Chat History table (for storing AI chat history)
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS chat_history (
			id SERIAL PRIMARY KEY,
			user_id TEXT,
			message TEXT NOT NULL,
			is_user BOOLEAN NOT NULL,
			timestamp TIMESTAMP NOT NULL
		)
	`)
	if err != nil {
		log.Fatalf("Error creating chat_history table: %v", err)
	}

	// Educational Content table
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS educational_content (
			id SERIAL PRIMARY KEY,
			title TEXT NOT NULL,
			content TEXT NOT NULL,
			category TEXT NOT NULL,
			image_url TEXT,
			created_at TIMESTAMP NOT NULL,
			updated_at TIMESTAMP NOT NULL
		)
	`)
	if err != nil {
		log.Fatalf("Error creating educational_content table: %v", err)
	}
}

// Health Data Endpoints

func saveHealthData(w http.ResponseWriter, r *http.Request) {
	var data HealthData
	if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	data.Timestamp = time.Now()

	var id int64
	err := db.QueryRow(`
		INSERT INTO health_data (
			timestamp, pregnancy_month, due_date, weight, height,
			systolic_bp, diastolic_bp, temperature, hemoglobin,
			glucose, symptoms, dietary_log, physical_activity,
			supplements, mood_rating, has_anxiety, anxiety_level
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
		RETURNING id
	`, data.Timestamp, data.PregnancyMonth, data.DueDate, data.Weight,
		data.Height, data.SystolicBP, data.DiastolicBP, data.Temperature,
		data.Hemoglobin, data.Glucose, data.Symptoms, data.DietaryLog,
		data.PhysicalActivity, data.Supplements, data.MoodRating,
		data.HasAnxiety, data.AnxietyLevel).Scan(&id)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(map[string]int64{"id": id})
}

func getLatestHealthData(w http.ResponseWriter, r *http.Request) {
	var data HealthData
	err := db.QueryRow(`
		SELECT id, timestamp, pregnancy_month, due_date, weight, height,
			systolic_bp, diastolic_bp, temperature, hemoglobin,
			glucose, symptoms, dietary_log, physical_activity,
			supplements, mood_rating, has_anxiety, anxiety_level
		FROM health_data
		ORDER BY timestamp DESC
		LIMIT 1
	`).Scan(&data.ID, &data.Timestamp, &data.PregnancyMonth, &data.DueDate,
		&data.Weight, &data.Height, &data.SystolicBP, &data.DiastolicBP,
		&data.Temperature, &data.Hemoglobin, &data.Glucose, &data.Symptoms,
		&data.DietaryLog, &data.PhysicalActivity, &data.Supplements,
		&data.MoodRating, &data.HasAnxiety, &data.AnxietyLevel)

	if err == sql.ErrNoRows {
		w.WriteHeader(http.StatusNotFound)
		return
	}
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(data)
}

func getAllHealthData(w http.ResponseWriter, r *http.Request) {
	rows, err := db.Query(`
		SELECT id, timestamp, pregnancy_month, due_date, weight, height,
			systolic_bp, diastolic_bp, temperature, hemoglobin,
			glucose, symptoms, dietary_log, physical_activity,
			supplements, mood_rating, has_anxiety, anxiety_level
		FROM health_data
		ORDER BY timestamp DESC
	`)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var healthData []HealthData
	for rows.Next() {
		var data HealthData
		err := rows.Scan(&data.ID, &data.Timestamp, &data.PregnancyMonth,
			&data.DueDate, &data.Weight, &data.Height, &data.SystolicBP,
			&data.DiastolicBP, &data.Temperature, &data.Hemoglobin,
			&data.Glucose, &data.Symptoms, &data.DietaryLog,
			&data.PhysicalActivity, &data.Supplements, &data.MoodRating,
			&data.HasAnxiety, &data.AnxietyLevel)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		healthData = append(healthData, data)
	}

	json.NewEncoder(w).Encode(healthData)
}

// Health Alerts Endpoints

func saveHealthAlert(w http.ResponseWriter, r *http.Request) {
	var alert HealthAlert
	if err := json.NewDecoder(r.Body).Decode(&alert); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	alert.Timestamp = time.Now()
	alert.IsRead = false

	err := db.QueryRow(`
		INSERT INTO health_alerts (title, message, severity, timestamp, is_read)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id
	`, alert.Title, alert.Message, alert.Severity, alert.Timestamp, alert.IsRead).Scan(&alert.ID)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(alert)
}

func getHealthAlerts(w http.ResponseWriter, r *http.Request) {
	limit := r.URL.Query().Get("limit")
	query := `
		SELECT id, title, message, severity, timestamp, is_read
		FROM health_alerts
		ORDER BY timestamp DESC
	`
	if limit != "" {
		query += fmt.Sprintf(" LIMIT %s", limit)
	}

	rows, err := db.Query(query)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var alerts []HealthAlert
	for rows.Next() {
		var alert HealthAlert
		err := rows.Scan(&alert.ID, &alert.Title, &alert.Message,
			&alert.Severity, &alert.Timestamp, &alert.IsRead)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		alerts = append(alerts, alert)
	}

	json.NewEncoder(w).Encode(alerts)
}

func markHealthAlertAsRead(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id := vars["id"]

	result, err := db.Exec(`
		UPDATE health_alerts
		SET is_read = true
		WHERE id = $1
	`, id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	if rowsAffected == 0 {
		http.Error(w, "Alert not found", http.StatusNotFound)
		return
	}

	w.WriteHeader(http.StatusOK)
}

// Reminders Endpoints

func saveReminder(w http.ResponseWriter, r *http.Request) {
	var reminder Reminder
	if err := json.NewDecoder(r.Body).Decode(&reminder); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	now := time.Now()
	reminder.CreatedAt = now
	reminder.UpdatedAt = now

	err := db.QueryRow(`
		INSERT INTO reminders (
			title, description, reminder_type, date, time,
			is_completed, created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id
	`, reminder.Title, reminder.Description, reminder.ReminderType,
		reminder.Date, reminder.Time, reminder.IsCompleted,
		reminder.CreatedAt, reminder.UpdatedAt).Scan(&reminder.ID)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(reminder)
}

func getReminders(w http.ResponseWriter, r *http.Request) {
	rows, err := db.Query(`
		SELECT id, title, description, reminder_type, date, time,
			is_completed, created_at, updated_at
		FROM reminders
		ORDER BY date ASC, time ASC
	`)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var reminders []Reminder
	for rows.Next() {
		var reminder Reminder
		err := rows.Scan(&reminder.ID, &reminder.Title, &reminder.Description,
			&reminder.ReminderType, &reminder.Date, &reminder.Time,
			&reminder.IsCompleted, &reminder.CreatedAt, &reminder.UpdatedAt)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		reminders = append(reminders, reminder)
	}

	json.NewEncoder(w).Encode(reminders)
}

func updateReminder(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id := vars["id"]

	var reminder Reminder
	if err := json.NewDecoder(r.Body).Decode(&reminder); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	reminder.UpdatedAt = time.Now()

	result, err := db.Exec(`
		UPDATE reminders
		SET title = $1, description = $2, reminder_type = $3,
			date = $4, time = $5, is_completed = $6, updated_at = $7
		WHERE id = $8
	`, reminder.Title, reminder.Description, reminder.ReminderType,
		reminder.Date, reminder.Time, reminder.IsCompleted,
		reminder.UpdatedAt, id)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	if rowsAffected == 0 {
		http.Error(w, "Reminder not found", http.StatusNotFound)
		return
	}

	w.WriteHeader(http.StatusOK)
}

func deleteReminder(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id := vars["id"]

	result, err := db.Exec("DELETE FROM reminders WHERE id = $1", id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	if rowsAffected == 0 {
		http.Error(w, "Reminder not found", http.StatusNotFound)
		return
	}

	w.WriteHeader(http.StatusOK)
}

func toggleReminderCompletion(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id := vars["id"]

	result, err := db.Exec(`
		UPDATE reminders
		SET is_completed = NOT is_completed,
			updated_at = $1
		WHERE id = $2
	`, time.Now(), id)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	if rowsAffected == 0 {
		http.Error(w, "Reminder not found", http.StatusNotFound)
		return
	}

	w.WriteHeader(http.StatusOK)
}

// AI Chat Endpoints

// Handle chat request
func chatHandler(w http.ResponseWriter, r *http.Request) {
	// Get API key
	apiKey := os.Getenv("GEMINI_API_KEY")
	if apiKey == "" {
		http.Error(w, "API key not configured", http.StatusInternalServerError)
		return
	}

	// Parse request
	var chatReq ChatRequest
	if err := json.NewDecoder(r.Body).Decode(&chatReq); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Structure the prompt with user's health info
	userPrompt := formatUserPrompt(chatReq)

	// Convert to Gemini format
	geminiReq := createGeminiRequest(chatReq, userPrompt)

	// Call Gemini API
	url := fmt.Sprintf("https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key=%s", apiKey)
	jsonData, err := json.Marshal(geminiReq)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Make the request
	resp, err := http.Post(url, "application/json", strings.NewReader(string(jsonData)))
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	// Process the response
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Parse Gemini response
	var geminiResp GeminiResponse
	if err := json.Unmarshal(body, &geminiResp); err != nil {
		log.Printf("Error parsing response: %v, Body: %s", err, string(body))
		http.Error(w, "Error parsing AI response", http.StatusInternalServerError)
		return
	}

	// Extract response text
	if len(geminiResp.Candidates) == 0 || len(geminiResp.Candidates[0].Content.Parts) == 0 {
		http.Error(w, "No response from AI", http.StatusInternalServerError)
		return
	}

	response := geminiResp.Candidates[0].Content.Parts[0].Text

	// Store messages in chat history
	storeMessage(chatReq.Messages[len(chatReq.Messages)-1].Content, true)
	storeMessage(response, false)

	// Return response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"response": response,
	})
}

// Get chat history
func getChatHistory(w http.ResponseWriter, r *http.Request) {
	rows, err := db.Query(`
		SELECT message, is_user, timestamp
		FROM chat_history
		ORDER BY timestamp ASC
	`)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var messages []ChatMessage
	for rows.Next() {
		var msg string
		var isUser bool
		var timestamp time.Time
		
		if err := rows.Scan(&msg, &isUser, &timestamp); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		
		role := "assistant"
		if isUser {
			role = "user"
		}
		
		messages = append(messages, ChatMessage{
			Role:    role,
			Content: msg,
		})
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(messages)
}

// Store message in chat history
func storeMessage(message string, isUser bool) {
	_, err := db.Exec(`
		INSERT INTO chat_history (message, is_user, timestamp)
		VALUES ($1, $2, $3)
	`, message, isUser, time.Now())
	
	if err != nil {
		log.Printf("Error storing chat message: %v", err)
	}
}

// Format user prompt with relevant health information
func formatUserPrompt(req ChatRequest) string {
	lastMessage := req.Messages[len(req.Messages)-1].Content
	
	// Build context about the user
	context := "You are a friendly and knowledgeable AI assistant for pregnant women. "
	
	if req.UserInfo.PregnancyMonth > 0 {
		context += fmt.Sprintf("I am %d months pregnant. ", req.UserInfo.PregnancyMonth)
	}
	
	if req.UserInfo.DueDate != "" {
		context += fmt.Sprintf("My due date is %s. ", req.UserInfo.DueDate)
	}
	
	if req.UserInfo.RecentSymptoms != "" {
		context += fmt.Sprintf("I've recently experienced these symptoms: %s. ", req.UserInfo.RecentSymptoms)
	}
	
	return context + "\n\nUser query: " + lastMessage
}

// Create Gemini API request
func createGeminiRequest(req ChatRequest, prompt string) GeminiRequest {
	return GeminiRequest{
		Contents: []GeminiContent{
			{
				Parts: []GeminiPart{
					{
						Text: prompt,
					},
				},
			},
		},
		SafetySettings: []SafetySetting{
			{
				Category:  "HARM_CATEGORY_HARASSMENT",
				Threshold: "BLOCK_MEDIUM_AND_ABOVE",
			},
			{
				Category:  "HARM_CATEGORY_HATE_SPEECH",
				Threshold: "BLOCK_MEDIUM_AND_ABOVE",
			},
			{
				Category:  "HARM_CATEGORY_SEXUALLY_EXPLICIT",
				Threshold: "BLOCK_MEDIUM_AND_ABOVE",
			},
			{
				Category:  "HARM_CATEGORY_DANGEROUS_CONTENT",
				Threshold: "BLOCK_MEDIUM_AND_ABOVE",
			},
		},
		GenerationConfig: GeminiGenerationConfig{
			Temperature:     0.7,
			TopK:            40,
			TopP:            0.95,
			MaxOutputTokens: 1024,
		},
	}
}

// Health data analysis endpoint
func analyzeHealthData(w http.ResponseWriter, r *http.Request) {
	// Parse request
	var data HealthData
	if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	
	// Get API key
	apiKey := os.Getenv("GEMINI_API_KEY")
	if apiKey == "" {
		http.Error(w, "API key not configured", http.StatusInternalServerError)
		return
	}
	
	// Create analysis prompt
	prompt := "As a healthcare AI, provide an analysis of the following health data for a pregnant woman:\n\n"
	
	if data.PregnancyMonth != nil {
		prompt += fmt.Sprintf("Pregnancy Month: %d\n", *data.PregnancyMonth)
	}
	
	if data.DueDate != nil {
		prompt += fmt.Sprintf("Due Date: %s\n", *data.DueDate)
	}
	
	if data.Weight != nil {
		prompt += fmt.Sprintf("Weight: %s\n", *data.Weight)
	}
	
	if data.SystolicBP != nil && data.DiastolicBP != nil {
		prompt += fmt.Sprintf("Blood Pressure: %s/%s\n", *data.SystolicBP, *data.DiastolicBP)
	}
	
	if data.Temperature != nil {
		prompt += fmt.Sprintf("Temperature: %s\n", *data.Temperature)
	}
	
	if data.Hemoglobin != nil {
		prompt += fmt.Sprintf("Hemoglobin: %s\n", *data.Hemoglobin)
	}
	
	if data.Glucose != nil {
		prompt += fmt.Sprintf("Glucose: %s\n", *data.Glucose)
	}
	
	if data.Symptoms != nil {
		prompt += fmt.Sprintf("Symptoms: %s\n", *data.Symptoms)
	}
	
	if data.MoodRating != nil {
		prompt += fmt.Sprintf("Mood Rating: %.1f out of 5\n", *data.MoodRating)
	}
	
	if data.HasAnxiety != nil && *data.HasAnxiety && data.AnxietyLevel != nil {
		prompt += fmt.Sprintf("Anxiety Level: %.1f out of 5\n", *data.AnxietyLevel)
	}
	
	prompt += "\nPlease provide a brief analysis of this health data, including any potential concerns or recommendations. Use a friendly, calm tone and highlight both positive aspects and areas that might need attention. Offer practical advice for maintaining good health during pregnancy."
	
	// Create Gemini request
	geminiReq := GeminiRequest{
		Contents: []GeminiContent{
			{
				Parts: []GeminiPart{
					{
						Text: prompt,
					},
				},
			},
		},
		SafetySettings: []SafetySetting{
			{
				Category:  "HARM_CATEGORY_DANGEROUS_CONTENT",
				Threshold: "BLOCK_MEDIUM_AND_ABOVE",
			},
		},
		GenerationConfig: GeminiGenerationConfig{
			Temperature:     0.4,
			TopK:            40,
			TopP:            0.95,
			MaxOutputTokens: 800,
		},
	}
	
	// Call Gemini API
	url := fmt.Sprintf("https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key=%s", apiKey)
	jsonData, err := json.Marshal(geminiReq)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	
	// Make the request
	resp, err := http.Post(url, "application/json", strings.NewReader(string(jsonData)))
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()
	
	// Process the response
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	
	// Parse Gemini response
	var geminiResp GeminiResponse
	if err := json.Unmarshal(body, &geminiResp); err != nil {
		log.Printf("Error parsing response: %v, Body: %s", err, string(body))
		http.Error(w, "Error parsing AI response", http.StatusInternalServerError)
		return
	}
	
	// Extract response text
	if len(geminiResp.Candidates) == 0 || len(geminiResp.Candidates[0].Content.Parts) == 0 {
		http.Error(w, "No response from AI", http.StatusInternalServerError)
		return
	}
	
	analysis := geminiResp.Candidates[0].Content.Parts[0].Text
	
	// Return response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"analysis": analysis,
	})
}

// Educational Content Endpoints

// Get all educational content
func getEducationalContent(w http.ResponseWriter, r *http.Request) {
	category := r.URL.Query().Get("category")
	
	var query string
	var args []interface{}
	
	if category != "" {
		query = `
			SELECT id, title, content, category, image_url, created_at, updated_at
			FROM educational_content
			WHERE category = $1
			ORDER BY created_at DESC
		`
		args = append(args, category)
	} else {
		query = `
			SELECT id, title, content, category, image_url, created_at, updated_at
			FROM educational_content
			ORDER BY created_at DESC
		`
	}
	
	rows, err := db.Query(query, args...)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	
	var content []EducationalContent
	for rows.Next() {
		var item EducationalContent
		var imageURL sql.NullString
		err := rows.Scan(&item.ID, &item.Title, &item.Content, &item.Category, 
			&imageURL, &item.CreatedAt, &item.UpdatedAt)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		if imageURL.Valid {
			item.ImageURL = imageURL.String
		}
		content = append(content, item)
	}
	
	json.NewEncoder(w).Encode(content)
}

// Get specific educational content item
func getEducationalContentItem(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id := vars["id"]
	
	var item EducationalContent
	var imageURL sql.NullString
	
	err := db.QueryRow(`
		SELECT id, title, content, category, image_url, created_at, updated_at
		FROM educational_content
		WHERE id = $1
	`, id).Scan(&item.ID, &item.Title, &item.Content, &item.Category, 
		&imageURL, &item.CreatedAt, &item.UpdatedAt)
	
	if err == sql.ErrNoRows {
		http.Error(w, "Content not found", http.StatusNotFound)
		return
	}
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	
	if imageURL.Valid {
		item.ImageURL = imageURL.String
	}
	
	json.NewEncoder(w).Encode(item)
}

// Save educational content
func saveEducationalContent(w http.ResponseWriter, r *http.Request) {
	var item EducationalContent
	if err := json.NewDecoder(r.Body).Decode(&item); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	
	now := time.Now()
	item.CreatedAt = now
	item.UpdatedAt = now
	
	err := db.QueryRow(`
		INSERT INTO educational_content (title, content, category, image_url, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id
	`, item.Title, item.Content, item.Category, item.ImageURL, item.CreatedAt, item.UpdatedAt).Scan(&item.ID)
	
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	
	json.NewEncoder(w).Encode(item)
}

// Generate educational content using AI
func generateEducationalContent(w http.ResponseWriter, r *http.Request) {
	// Get API key
	apiKey := os.Getenv("GEMINI_API_KEY")
	if apiKey == "" {
		http.Error(w, "API key not configured", http.StatusInternalServerError)
		return
	}
	
	// Parse request
	var eduReq EducationalRequest
	if err := json.NewDecoder(r.Body).Decode(&eduReq); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	
	// Create prompt
	prompt := "You are an expert in maternal health education. "
	
	if eduReq.Category != "" {
		prompt += fmt.Sprintf("Focus on the category: %s. ", eduReq.Category)
	}
	
	if len(eduReq.Topics) > 0 {
		prompt += "Include information about the following topics: "
		for i, topic := range eduReq.Topics {
			if i > 0 {
				prompt += ", "
			}
			prompt += topic
		}
		prompt += ". "
	}
	
	prompt += "Please provide educational content for pregnant women about the following: " + eduReq.Query
	prompt += "\n\nFormat your response as a well-structured educational article with a title, introduction, main content with subheadings, and a conclusion. Use markdown formatting."
	
	// Create Gemini request
	geminiReq := GeminiRequest{
		Contents: []GeminiContent{
			{
				Parts: []GeminiPart{
					{
						Text: prompt,
					},
				},
			},
		},
		SafetySettings: []SafetySetting{
			{
				Category:  "HARM_CATEGORY_DANGEROUS_CONTENT",
				Threshold: "BLOCK_MEDIUM_AND_ABOVE",
			},
		},
		GenerationConfig: GeminiGenerationConfig{
			Temperature:     0.2,
			TopK:            40,
			TopP:            0.95,
			MaxOutputTokens: 2048,
		},
	}
	
	// Call Gemini API
	url := fmt.Sprintf("https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key=%s", apiKey)
	jsonData, err := json.Marshal(geminiReq)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	
	// Make the request
	resp, err := http.Post(url, "application/json", strings.NewReader(string(jsonData)))
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()
	
	// Process the response
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	
	// Parse Gemini response
	var geminiResp GeminiResponse
	if err := json.Unmarshal(body, &geminiResp); err != nil {
		log.Printf("Error parsing response: %v, Body: %s", err, string(body))
		http.Error(w, "Error parsing AI response", http.StatusInternalServerError)
		return
	}
	
	// Extract response text
	if len(geminiResp.Candidates) == 0 || len(geminiResp.Candidates[0].Content.Parts) == 0 {
		http.Error(w, "No response from AI", http.StatusInternalServerError)
		return
	}
	
	content := geminiResp.Candidates[0].Content.Parts[0].Text
	
	// Try to extract a title from the content
	title := eduReq.Query
	lines := strings.Split(content, "\n")
	if len(lines) > 0 && (strings.HasPrefix(lines[0], "# ") || strings.HasPrefix(lines[0], "## ")) {
		title = strings.TrimSpace(strings.TrimPrefix(strings.TrimPrefix(lines[0], "# "), "## "))
	}
	
	// Create an educational content item
	eduContent := EducationalContent{
		Title:     title,
		Content:   content,
		Category:  eduReq.Category,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
	
	// Return response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(eduContent)
}

func main() {
	r := mux.NewRouter()
	
	// Apply CORS middleware to all routes
	r.Use(corsMiddleware)

	// Health Data endpoints
	r.HandleFunc("/api/health-data", saveHealthData).Methods("POST", "OPTIONS")
	r.HandleFunc("/api/health-data/latest", getLatestHealthData).Methods("GET", "OPTIONS")
	r.HandleFunc("/api/health-data", getAllHealthData).Methods("GET", "OPTIONS")

	// Health Alerts endpoints
	r.HandleFunc("/api/health-alerts", saveHealthAlert).Methods("POST", "OPTIONS")
	r.HandleFunc("/api/health-alerts", getHealthAlerts).Methods("GET", "OPTIONS")
	r.HandleFunc("/api/health-alerts/{id}/read", markHealthAlertAsRead).Methods("PATCH", "OPTIONS")

	// Reminders endpoints
	r.HandleFunc("/api/reminders", saveReminder).Methods("POST", "OPTIONS")
	r.HandleFunc("/api/reminders", getReminders).Methods("GET", "OPTIONS")
	r.HandleFunc("/api/reminders/{id}", updateReminder).Methods("PATCH", "OPTIONS")
	r.HandleFunc("/api/reminders/{id}", deleteReminder).Methods("DELETE", "OPTIONS")
	r.HandleFunc("/api/reminders/{id}/toggle", toggleReminderCompletion).Methods("PATCH", "OPTIONS")
	
	// AI Chat endpoints
	r.HandleFunc("/api/chat", chatHandler).Methods("POST", "OPTIONS")
	r.HandleFunc("/api/chat/history", getChatHistory).Methods("GET", "OPTIONS")
	r.HandleFunc("/api/analyze", analyzeHealthData).Methods("POST", "OPTIONS")

	// Educational Content endpoints
	r.HandleFunc("/api/educational-content", getEducationalContent).Methods("GET", "OPTIONS")
	r.HandleFunc("/api/educational-content/{id}", getEducationalContentItem).Methods("GET", "OPTIONS")
	r.HandleFunc("/api/educational-content", saveEducationalContent).Methods("POST", "OPTIONS")
	r.HandleFunc("/api/generate-educational-content", generateEducationalContent).Methods("POST", "OPTIONS")

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	log.Printf("Server starting on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, r))
} 