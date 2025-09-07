/**
 * Lambda@Edge function for security headers
 * Adds comprehensive security headers to all responses
 * Implements security best practices for mobile app CDN
 */

'use strict';

// Security headers configuration
const SECURITY_HEADERS = {
    // Content Security Policy - Strict policy for production
    'Content-Security-Policy': [
        "default-src 'self'",
        "script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net https://unpkg.com",
        "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
        "font-src 'self' https://fonts.gstatic.com",
        "img-src 'self' data: https:",
        "media-src 'self' blob: https:",
        "connect-src 'self' https://*.supabase.co wss://*.livekit.cloud https://*.sentry.io",
        "worker-src 'self' blob:",
        "frame-ancestors 'none'",
        "base-uri 'self'",
        "form-action 'self'"
    ].join('; '),
    
    // Prevent clickjacking attacks
    'X-Frame-Options': 'DENY',
    
    // Prevent MIME type sniffing
    'X-Content-Type-Options': 'nosniff',
    
    // XSS Protection (legacy browsers)
    'X-XSS-Protection': '1; mode=block',
    
    // Referrer Policy
    'Referrer-Policy': 'strict-origin-when-cross-origin',
    
    // Permissions Policy (replace Feature-Policy)
    'Permissions-Policy': [
        'camera=()',
        'microphone=()',
        'geolocation=()',
        'payment=()',
        'usb=()',
        'magnetometer=()',
        'gyroscope=()',
        'accelerometer=()'
    ].join(', '),
    
    // Strict Transport Security (HSTS)
    'Strict-Transport-Security': 'max-age=31536000; includeSubDomains; preload',
    
    // Cross-Origin Resource Policy
    'Cross-Origin-Resource-Policy': 'cross-origin',
    
    // Cross-Origin Opener Policy
    'Cross-Origin-Opener-Policy': 'same-origin-allow-popups',
    
    // Cross-Origin Embedder Policy
    'Cross-Origin-Embedder-Policy': 'unsafe-none'
};

// Headers specific to different content types
const CONTENT_TYPE_HEADERS = {
    'image': {
        'Cache-Control': 'public, max-age=2592000, immutable', // 30 days
        'Cross-Origin-Resource-Policy': 'cross-origin'
    },
    'video': {
        'Cache-Control': 'public, max-age=2592000', // 30 days
        'Cross-Origin-Resource-Policy': 'cross-origin'
    },
    'audio': {
        'Cache-Control': 'public, max-age=2592000', // 30 days
        'Cross-Origin-Resource-Policy': 'cross-origin'
    },
    'font': {
        'Cache-Control': 'public, max-age=31536000, immutable', // 1 year
        'Cross-Origin-Resource-Policy': 'cross-origin',
        'Access-Control-Allow-Origin': '*'
    },
    'json': {
        'Cache-Control': 'public, max-age=3600', // 1 hour
        'Content-Type': 'application/json; charset=utf-8'
    },
    'js': {
        'Cache-Control': 'public, max-age=31536000, immutable', // 1 year
        'Content-Type': 'application/javascript; charset=utf-8'
    },
    'css': {
        'Cache-Control': 'public, max-age=31536000, immutable', // 1 year
        'Content-Type': 'text/css; charset=utf-8'
    }
};

// CORS headers for API requests
const CORS_HEADERS = {
    'Access-Control-Allow-Origin': '*', // Configure this based on your domain
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Authorization, Content-Type, X-Requested-With',
    'Access-Control-Max-Age': '86400'
};

// Function to determine content type from URI
function getContentType(uri) {
    const extension = uri.split('.').pop().toLowerCase();
    
    const typeMap = {
        // Images
        'jpg': 'image', 'jpeg': 'image', 'png': 'image', 'gif': 'image',
        'webp': 'image', 'avif': 'image', 'svg': 'image', 'ico': 'image',
        
        // Videos
        'mp4': 'video', 'webm': 'video', 'mov': 'video', 'avi': 'video',
        
        // Audio
        'mp3': 'audio', 'wav': 'audio', 'm4a': 'audio', 'aac': 'audio',
        
        // Fonts
        'woff': 'font', 'woff2': 'font', 'ttf': 'font', 'eot': 'font',
        
        // Scripts and styles
        'js': 'js', 'mjs': 'js',
        'css': 'css',
        
        // Data
        'json': 'json'
    };
    
    return typeMap[extension] || 'default';
}

// Function to add security headers to response
function addSecurityHeaders(response) {
    const headers = response.headers;
    
    // Add all security headers
    Object.entries(SECURITY_HEADERS).forEach(([key, value]) => {
        headers[key.toLowerCase()] = [{ key, value }];
    });
    
    return response;
}

// Function to add content-specific headers
function addContentHeaders(response, contentType, uri) {
    const headers = response.headers;
    
    // Add content-type specific headers
    if (CONTENT_TYPE_HEADERS[contentType]) {
        Object.entries(CONTENT_TYPE_HEADERS[contentType]).forEach(([key, value]) => {
            headers[key.toLowerCase()] = [{ key, value }];
        });
    }
    
    // Add CORS headers for API requests
    if (uri.startsWith('/api/') || uri.startsWith('/storage/')) {
        Object.entries(CORS_HEADERS).forEach(([key, value]) => {
            headers[key.toLowerCase()] = [{ key, value }];
        });
    }
    
    return response;
}

// Function to add performance headers
function addPerformanceHeaders(response, request) {
    const headers = response.headers;
    
    // Add ETag for caching
    if (!headers['etag'] && response.status === '200') {
        const etag = `"${Math.random().toString(36).substring(2)}"`;
        headers['etag'] = [{ key: 'ETag', value: etag }];
    }
    
    // Add Vary header for better caching
    headers['vary'] = [{ key: 'Vary', value: 'Accept-Encoding, Origin' }];
    
    // Add Last-Modified if not present
    if (!headers['last-modified'] && response.status === '200') {
        headers['last-modified'] = [{ 
            key: 'Last-Modified', 
            value: new Date().toUTCString() 
        }];
    }
    
    // Add server timing for performance monitoring
    const serverTiming = [];
    
    if (request.headers['x-edge-location']) {
        const edgeLocation = request.headers['x-edge-location'][0].value;
        serverTiming.push(`edge;desc="${edgeLocation}"`);
    }
    
    if (request.headers['x-china-optimized']) {
        serverTiming.push('china;desc="optimized"');
    }
    
    if (serverTiming.length > 0) {
        headers['server-timing'] = [{ key: 'Server-Timing', value: serverTiming.join(', ') }];
    }
    
    return response;
}

// Function to handle error responses
function handleErrorResponse(response) {
    const headers = response.headers;
    const status = response.status;
    
    // Don't cache error responses for too long
    if (status >= '400') {
        headers['cache-control'] = [{ 
            key: 'Cache-Control', 
            value: 'no-cache, no-store, must-revalidate' 
        }];
        
        // Add error-specific headers
        headers['x-error-handled'] = [{ key: 'X-Error-Handled', value: 'true' }];
    }
    
    return response;
}

// Main Lambda@Edge function
exports.handler = async (event) => {
    const { request, response } = event.Records[0].cf;
    
    try {
        // Log response processing
        console.log(`Processing response: ${response.status} for ${request.uri}`);
        
        // Determine content type
        const contentType = getContentType(request.uri);
        
        // Add security headers
        addSecurityHeaders(response);
        
        // Add content-specific headers
        addContentHeaders(response, contentType, request.uri);
        
        // Add performance headers
        addPerformanceHeaders(response, request);
        
        // Handle error responses
        if (response.status >= '400') {
            handleErrorResponse(response);
        }
        
        // Add custom app headers
        response.headers['x-powered-by'] = [{ key: 'X-Powered-By', value: 'WhatsApp Clone CDN' }];
        response.headers['x-content-type-detected'] = [{ key: 'X-Content-Type-Detected', value: contentType }];
        
        // Add request tracing
        if (request.headers['x-request-id']) {
            response.headers['x-request-id'] = request.headers['x-request-id'];
        }
        
        console.log(`Response headers added successfully for ${request.uri}`);
        
    } catch (error) {
        console.error('Error in security headers Lambda@Edge function:', error);
        
        // Add error header but don't block response
        response.headers['x-header-error'] = [{ key: 'X-Header-Error', value: 'true' }];
    }
    
    return response;
};

// Export configuration for testing
exports.SECURITY_HEADERS = SECURITY_HEADERS;
exports.CONTENT_TYPE_HEADERS = CONTENT_TYPE_HEADERS;
exports.CORS_HEADERS = CORS_HEADERS;