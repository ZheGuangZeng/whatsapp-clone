/**
 * Lambda@Edge function for intelligent routing
 * Routes requests based on user location for optimal performance
 * Specifically optimized for China network conditions
 */

'use strict';

// Configuration for regional routing
const REGIONS = {
    CHINA: {
        origin: 'your-production-project-jp.supabase.co', // Japan is closer to China
        countries: ['CN', 'HK', 'MO', 'TW']
    },
    ASIA_PACIFIC: {
        origin: 'your-production-project-sg.supabase.co', // Singapore primary
        countries: ['SG', 'MY', 'TH', 'VN', 'ID', 'PH', 'IN', 'AU', 'NZ', 'KR', 'JP']
    },
    DEFAULT: {
        origin: 'your-production-project-sg.supabase.co' // Default to Singapore
    }
};

// CDN edge locations with best performance for China
const CHINA_OPTIMIZED_PATHS = [
    '/user-avatars',
    '/chat-media',
    '/thumbnails',
    '/static'
];

// Function to determine the best origin based on request
function determineOrigin(request) {
    const headers = request.headers;
    
    // Get country code from CloudFront headers
    const country = headers['cloudfront-viewer-country'] 
        ? headers['cloudfront-viewer-country'][0].value 
        : null;
    
    // Check if request is from China or nearby regions
    if (country && REGIONS.CHINA.countries.includes(country)) {
        console.log(`Routing Chinese user (${country}) to Japan origin`);
        return REGIONS.CHINA.origin;
    }
    
    // Check if request is from Asia-Pacific region
    if (country && REGIONS.ASIA_PACIFIC.countries.includes(country)) {
        console.log(`Routing APAC user (${country}) to Singapore origin`);
        return REGIONS.ASIA_PACIFIC.origin;
    }
    
    // Default routing
    console.log(`Using default routing for country: ${country || 'unknown'}`);
    return REGIONS.DEFAULT.origin;
}

// Function to optimize request for China network conditions
function optimizeForChina(request, country) {
    const isChineseUser = REGIONS.CHINA.countries.includes(country);
    
    if (isChineseUser) {
        // Add headers for China optimization
        request.headers['x-china-optimized'] = [{ key: 'X-China-Optimized', value: 'true' }];
        
        // Enable additional compression for slower networks
        if (!request.headers['accept-encoding']) {
            request.headers['accept-encoding'] = [{ key: 'Accept-Encoding', value: 'gzip, deflate, br' }];
        }
        
        // Prioritize smaller image formats
        if (request.uri.match(/\.(jpg|jpeg|png|gif|webp)$/i)) {
            request.headers['accept'] = [{ 
                key: 'Accept', 
                value: 'image/webp,image/avif,image/*,*/*;q=0.8' 
            }];
        }
    }
    
    return request;
}

// Main Lambda@Edge function
exports.handler = async (event) => {
    const request = event.Records[0].cf.request;
    const headers = request.headers;
    
    try {
        // Get user's country
        const country = headers['cloudfront-viewer-country'] 
            ? headers['cloudfront-viewer-country'][0].value 
            : null;
        
        // Log request details for monitoring
        console.log(`Processing request: ${request.method} ${request.uri} from ${country || 'unknown'}`);
        
        // Determine optimal origin
        const optimalOrigin = determineOrigin(request);
        
        // Update origin if different from current
        if (request.origin.custom && request.origin.custom.domainName !== optimalOrigin) {
            request.origin.custom.domainName = optimalOrigin;
            console.log(`Switched origin to: ${optimalOrigin}`);
        }
        
        // Optimize request for Chinese users
        if (country) {
            request = optimizeForChina(request, country);
        }
        
        // Add cache optimization headers
        request.headers['cache-control'] = [{ 
            key: 'Cache-Control', 
            value: 'public, max-age=86400' 
        }];
        
        // Add performance monitoring headers
        request.headers['x-edge-location'] = [{ 
            key: 'X-Edge-Location', 
            value: headers['cloudfront-viewer-country-region'] 
                ? headers['cloudfront-viewer-country-region'][0].value 
                : 'unknown'
        }];
        
        // Handle special paths for mobile optimization
        if (request.uri.startsWith('/mobile/')) {
            request.headers['x-mobile-optimized'] = [{ key: 'X-Mobile-Optimized', value: 'true' }];
        }
        
        // Add request ID for tracing
        const requestId = Math.random().toString(36).substring(2, 15);
        request.headers['x-request-id'] = [{ key: 'X-Request-ID', value: requestId }];
        
        console.log(`Request ${requestId} processed successfully`);
        
    } catch (error) {
        console.error('Error in Lambda@Edge function:', error);
        // Don't block the request on errors, just log and continue
    }
    
    return request;
};

// Health check function for monitoring
exports.healthCheck = () => {
    return {
        statusCode: 200,
        body: JSON.stringify({
            status: 'healthy',
            timestamp: new Date().toISOString(),
            version: '1.0.0',
            regions: Object.keys(REGIONS)
        })
    };
};