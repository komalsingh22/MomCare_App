// CORS handler for Flutter web
(function() {
  // Only run in Flutter web environment
  if (window.location.hostname !== 'localhost' && window.location.hostname !== '127.0.0.1') {
    return;
  }
  
  console.log('CORS handler initialized for Flutter web development');
  
  // Log API calls for debugging
  const originalFetch = window.fetch;
  window.fetch = function(url, options) {
    // Only log API requests
    if (url && url.toString().includes('localhost:8080')) {
      console.log('Flutter Web API Request:', {
        url: url.toString(),
        method: options?.method || 'GET',
        headers: options?.headers || {}
      });
      
      // Do NOT modify the request - let the browser handle CORS normally
      // The server must set the appropriate CORS headers
    }
    
    // Always use the original fetch without modification
    return originalFetch(url, options);
  };
})(); 