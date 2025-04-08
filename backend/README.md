# MomCare Backend Server

A simple Go server that acts as a proxy for Gemini API calls.

## Setup

1. Install Go (if not already installed)
2. Install dependencies:
   ```bash
   go mod tidy
   ```
3. Create a `.env` file with your Gemini API key:
   ```
   GEMINI_API_KEY=your_gemini_api_key_here
   PORT=8080
   ```

## Running the Server

```bash
go run main.go
```

The server will start on port 8080 by default.

## API Endpoint

### POST /api/gemini

Request body:
```json
{
    "prompt": "Your prompt here"
}
```

Response:
```json
{
    "response": "Gemini's response here"
}
```

## Error Handling

If an error occurs, the response will include an error message:
```json
{
    "error": "Error message here"
}
```

## Security

- The API key is stored in the `.env` file and is not committed to the repository
- CORS is enabled to allow requests from any origin (you may want to restrict this in production) 