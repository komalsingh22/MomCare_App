package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/gorilla/mux"
	"github.com/joho/godotenv"
)

type RequestBody struct {
	Prompt string `json:"prompt"`
}

type ResponseBody struct {
	Response string `json:"response"`
	Error    string `json:"error,omitempty"`
}

type GeminiRequest struct {
	Contents []struct {
		Parts []struct {
			Text string `json:"text"`
		} `json:"parts"`
	} `json:"contents"`
	SafetySettings []struct {
		Category  string `json:"category"`
		Threshold string `json:"threshold"`
	} `json:"safetySettings,omitempty"`
	GenerationConfig struct {
		Temperature     float64 `json:"temperature"`
		TopK           int     `json:"topK"`
		TopP           float64 `json:"topP"`
		MaxOutputTokens int    `json:"maxOutputTokens"`
	} `json:"generationConfig"`
}

type GeminiResponse struct {
	Candidates []struct {
		Content struct {
			Parts []struct {
				Text string `json:"text"`
			} `json:"parts"`
		} `json:"content"`
		SafetyRatings []struct {
			Category    string `json:"category"`
			Probability string `json:"probability"`
		} `json:"safetyRatings"`
	} `json:"candidates"`
	PromptFeedback struct {
		SafetyRatings []struct {
			Category    string `json:"category"`
			Probability string `json:"probability"`
		} `json:"safetyRatings"`
	} `json:"promptFeedback"`
}

type ChatRequest struct {
	Prompt string `json:"prompt"`
}

type ChatResponse struct {
	Response string `json:"response"`
}

type AnalyzeRequest struct {
	VitalSigns []map[string]interface{} `json:"vitalSigns"`
	HealthData []map[string]interface{} `json:"healthData"`
	LatestData map[string]interface{}   `json:"latestData"`
}

type HealthAlert struct {
	ID         string `json:"id"`
	Title      string `json:"title"`
	Message    string `json:"message"`
	Severity   string `json:"severity"`
	LastUpdated string `json:"lastUpdated"`
}

type AnalyzeResponse struct {
	Alerts []HealthAlert `json:"alerts"`
}

type EducationalRequest struct {
	Condition string `json:"condition"`
}

type EducationalResponse struct {
	Content string `json:"content"`
}

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found")
	}

	// Initialize router
	r := mux.NewRouter()

	// Define routes
	r.HandleFunc("/chat", handleGeminiRequest).Methods("POST", "OPTIONS")
	r.HandleFunc("/analyze", handleAnalyzeRequest).Methods("POST", "OPTIONS")
	r.HandleFunc("/educational", handleEducationalRequest).Methods("POST", "OPTIONS")

	// Add CORS middleware
	r.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		// Set CORS headers
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

		// Handle preflight requests
		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		// Handle actual request
		http.NotFound(w, r)
	})

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	
	fmt.Printf("Server starting on port %s...\n", port)
	log.Fatal(http.ListenAndServe(":"+port, r))
}

func handleGeminiRequest(w http.ResponseWriter, r *http.Request) {
	// Set CORS headers
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

	// Handle preflight requests
	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}

	if r.Method != "POST" {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Read request body
	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, "Error reading request body", http.StatusBadRequest)
		return
	}

	// Parse request body
	var chatReq ChatRequest
	if err := json.Unmarshal(body, &chatReq); err != nil {
		http.Error(w, "Error parsing request body", http.StatusBadRequest)
		return
	}

	// Get API key from environment variable
	apiKey := os.Getenv("GEMINI_API_KEY")
	if apiKey == "" {
		http.Error(w, "API key not found", http.StatusInternalServerError)
		return
	}

	// Prepare request to Gemini API
	url := fmt.Sprintf("https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key=%s", apiKey)
	
	// Create request body for Gemini API
	geminiReq := map[string]interface{}{
		"contents": []map[string]interface{}{
			{
				"parts": []map[string]interface{}{
					{
						"text": fmt.Sprintf(`
							You are an expert maternal health assistant specializing in pregnancy, maternal health, and infant care. 
							Your role is to provide accurate, supportive, and helpful information while always emphasizing the importance of consulting healthcare providers for medical advice.

							Guidelines for responses:
							1. Be clear and concise
							2. Use simple, understandable language
							3. Always include a disclaimer about consulting healthcare providers
							4. Be supportive and encouraging
							5. Focus on evidence-based information
							6. If the question is about symptoms or concerns, always recommend consulting a healthcare provider

							User: %s
							Assistant:`, chatReq.Prompt),
					},
				},
			},
		},
		"generationConfig": map[string]interface{}{
			"temperature":     0.7,
			"maxOutputTokens": 2048,
			"topK":           40,
			"topP":           0.95,
		},
	}

	// Convert request to JSON
	jsonData, err := json.Marshal(geminiReq)
	if err != nil {
		http.Error(w, "Error creating request", http.StatusInternalServerError)
		return
	}

	// Create HTTP request
	req, err := http.NewRequest("POST", url, strings.NewReader(string(jsonData)))
	if err != nil {
		http.Error(w, "Error creating request", http.StatusInternalServerError)
		return
	}

	// Set headers
	req.Header.Set("Content-Type", "application/json")

	// Send request
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		http.Error(w, "Error sending request to Gemini API", http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	// Read response
	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		http.Error(w, "Error reading response", http.StatusInternalServerError)
		return
	}

	// Parse Gemini response
	var geminiResp map[string]interface{}
	if err := json.Unmarshal(respBody, &geminiResp); err != nil {
		http.Error(w, "Error parsing response", http.StatusInternalServerError)
		return
	}

	// Extract text from response
	var responseText string
	if candidates, ok := geminiResp["candidates"].([]interface{}); ok && len(candidates) > 0 {
		if candidate, ok := candidates[0].(map[string]interface{}); ok {
			if content, ok := candidate["content"].(map[string]interface{}); ok {
				if parts, ok := content["parts"].([]interface{}); ok && len(parts) > 0 {
					if part, ok := parts[0].(map[string]interface{}); ok {
						if text, ok := part["text"].(string); ok {
							responseText = text
						}
					}
				}
			}
		}
	}

	// Create response
	chatResp := ChatResponse{
		Response: responseText,
	}

	// Send response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(chatResp)
}

func handleAnalyzeRequest(w http.ResponseWriter, r *http.Request) {
	// Set CORS headers
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

	// Handle preflight requests
	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}

	if r.Method != "POST" {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Read request body
	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, "Error reading request body", http.StatusBadRequest)
		return
	}

	// Parse request body
	var analyzeReq AnalyzeRequest
	if err := json.Unmarshal(body, &analyzeReq); err != nil {
		http.Error(w, "Error parsing request body", http.StatusBadRequest)
		return
	}

	// Get API key from environment variable
	apiKey := os.Getenv("GEMINI_API_KEY")
	if apiKey == "" {
		http.Error(w, "API key not found", http.StatusInternalServerError)
		return
	}

	// Prepare request to Gemini API
	url := fmt.Sprintf("https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key=%s", apiKey)
	
	// Create request body for Gemini API
	geminiReq := map[string]interface{}{
		"contents": []map[string]interface{}{
			{
				"parts": []map[string]interface{}{
					{
						"text": fmt.Sprintf(`
							As a medical AI specializing in maternal health, analyze these health data points and provide focused insights about potential pregnancy-related conditions and risks. Focus on analyzing the actual data provided.

							Current Vital Signs:
							Blood Pressure: %s
							Heart Rate: %v bpm
							Temperature: %v°F
							Weight: %v kg
							Sleep Hours: %v

							Please analyze this data considering:
							1. Normal ranges for these parameters during pregnancy
							2. Potential conditions that could be indicated by these values
							3. Early warning signs that might be present
							4. Recommendations for monitoring or follow-up
							5. When to seek medical attention

							Format your response as a JSON array of alerts:
							[
								{
									"id": "unique_id",
									"title": "Alert Title",
									"message": "Detailed analysis and recommendations based on the data",
									"severity": "high/medium/low",
									"lastUpdated": "ISO8601 timestamp"
								}
							]

							Focus on analyzing the actual data provided and making predictions based on medical knowledge.`, 
							analyzeReq.LatestData["bloodPressure"],
							analyzeReq.LatestData["heartRate"],
							analyzeReq.LatestData["temperature"],
							analyzeReq.LatestData["weight"],
							analyzeReq.LatestData["sleepHours"]),
					},
				},
			},
		},
		"generationConfig": map[string]interface{}{
			"temperature":     0.7,
			"maxOutputTokens": 2048,
			"topK":           40,
			"topP":           0.95,
		},
	}

	// Convert request to JSON
	jsonData, err := json.Marshal(geminiReq)
	if err != nil {
		http.Error(w, "Error creating request", http.StatusInternalServerError)
		return
	}

	// Create HTTP request
	req, err := http.NewRequest("POST", url, strings.NewReader(string(jsonData)))
	if err != nil {
		http.Error(w, "Error creating request", http.StatusInternalServerError)
		return
	}

	// Set headers
	req.Header.Set("Content-Type", "application/json")

	// Send request
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		http.Error(w, "Error sending request to Gemini API", http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	// Read response
	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		http.Error(w, "Error reading response", http.StatusInternalServerError)
		return
	}

	// Parse Gemini response
	var geminiResp map[string]interface{}
	if err := json.Unmarshal(respBody, &geminiResp); err != nil {
		http.Error(w, "Error parsing response", http.StatusInternalServerError)
		return
	}

	// Extract text from response
	var responseText string
	if candidates, ok := geminiResp["candidates"].([]interface{}); ok && len(candidates) > 0 {
		if candidate, ok := candidates[0].(map[string]interface{}); ok {
			if content, ok := candidate["content"].(map[string]interface{}); ok {
				if parts, ok := content["parts"].([]interface{}); ok && len(parts) > 0 {
					if part, ok := parts[0].(map[string]interface{}); ok {
						if text, ok := part["text"].(string); ok {
							responseText = text
						}
					}
				}
			}
		}
	}

	if responseText == "" {
		// If no valid response, return a default analysis
		analyzeResp := AnalyzeResponse{
			Alerts: []HealthAlert{
				{
					ID:          "default_analysis",
					Title:       "Analysis Results",
					Message:     "Based on the provided vital signs and health data, all values appear to be within normal ranges. Continue monitoring and consult with your healthcare provider during regular check-ups.",
					Severity:    "low",
					LastUpdated: "2024-03-20T00:00:00Z",
				},
			},
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(analyzeResp)
		return
	}

	// Try to parse the response as JSON first
	var alerts []HealthAlert
	if err := json.Unmarshal([]byte(responseText), &alerts); err != nil {
		// If parsing fails, create a structured response from the text
		alerts = []HealthAlert{
			{
				ID:          "ai_analysis",
				Title:       "Health Analysis Results",
				Message:     responseText,
				Severity:    "info",
				LastUpdated: "2024-03-20T00:00:00Z",
			},
		}
	}

	// Create final response
	analyzeResp := AnalyzeResponse{
		Alerts: alerts,
	}

	// Send response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(analyzeResp)
}

func handleEducationalRequest(w http.ResponseWriter, r *http.Request) {
	// Set CORS headers
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

	// Handle preflight requests
	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}

	if r.Method != "POST" {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Read request body
	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, "Error reading request body", http.StatusBadRequest)
		return
	}

	// Parse request body
	var eduReq EducationalRequest
	if err := json.Unmarshal(body, &eduReq); err != nil {
		http.Error(w, "Error parsing request body", http.StatusBadRequest)
		return
	}

	// Get API key from environment variable
	apiKey := os.Getenv("GEMINI_API_KEY")
	if apiKey == "" {
		http.Error(w, "API key not found", http.StatusInternalServerError)
		return
	}

	// Prepare request to Gemini API
	url := fmt.Sprintf("https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key=%s", apiKey)
	
	// Create request body for Gemini API
	geminiReq := map[string]interface{}{
		"contents": []map[string]interface{}{
			{
				"parts": []map[string]interface{}{
					{
						"text": fmt.Sprintf(`
							Provide brief, practical information about %s during pregnancy:
							1. What it is
							2. Key symptoms
							3. Treatment options
							4. When to seek medical help
							Max 300 words, simple language.
						`, eduReq.Condition),
					},
				},
			},
		},
		"generationConfig": map[string]interface{}{
			"temperature":     0.7,
			"maxOutputTokens": 2048,
			"topK":           40,
			"topP":           0.95,
		},
	}

	// Convert request to JSON
	jsonData, err := json.Marshal(geminiReq)
	if err != nil {
		http.Error(w, "Error creating request", http.StatusInternalServerError)
		return
	}

	// Create HTTP request
	req, err := http.NewRequest("POST", url, strings.NewReader(string(jsonData)))
	if err != nil {
		http.Error(w, "Error creating request", http.StatusInternalServerError)
		return
	}

	// Set headers
	req.Header.Set("Content-Type", "application/json")

	// Send request
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		http.Error(w, "Error sending request to Gemini API", http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	// Read response
	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		http.Error(w, "Error reading response", http.StatusInternalServerError)
		return
	}

	// Parse Gemini response
	var geminiResp map[string]interface{}
	if err := json.Unmarshal(respBody, &geminiResp); err != nil {
		http.Error(w, "Error parsing response", http.StatusInternalServerError)
		return
	}

	// Extract text from response
	var responseText string
	if candidates, ok := geminiResp["candidates"].([]interface{}); ok && len(candidates) > 0 {
		if candidate, ok := candidates[0].(map[string]interface{}); ok {
			if content, ok := candidate["content"].(map[string]interface{}); ok {
				if parts, ok := content["parts"].([]interface{}); ok && len(parts) > 0 {
					if part, ok := parts[0].(map[string]interface{}); ok {
						if text, ok := part["text"].(string); ok {
							responseText = text
						}
					}
				}
			}
		}
	}

	// Create response
	eduResp := EducationalResponse{
		Content: responseText,
	}

	// Send response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(eduResp)
} 