/**
 * Lambda@Edge function for intelligent origin routing
 * Routes Chinese users to Japan origin for better connectivity
 * Routes other users to Singapore origin (primary)
 */

exports.handler = async (event) => {
    const request = event.Records[0].cf.request;
    const headers = request.headers;
    
    // Get CloudFront country code
    const countryCode = headers['cloudfront-viewer-country'] 
        ? headers['cloudfront-viewer-country'][0].value 
        : null;
    
    // Get client IP for additional geolocation
    const clientIP = headers['x-forwarded-for'] 
        ? headers['x-forwarded-for'][0].value.split(',')[0].trim()
        : request.clientIp;
    
    console.log(`Request from country: ${countryCode}, IP: ${clientIP}`);
    
    // China-specific routing optimization
    const chineseCountries = ['CN', 'HK', 'MO', 'TW'];
    const useJapanOrigin = chineseCountries.includes(countryCode);
    
    // Additional IP-based detection for China regions
    const chineseIPRanges = [
        '1.0.', '14.', '27.', '36.', '39.', '42.', '49.', '58.', '59.', '60.',
        '61.', '101.', '103.', '106.', '110.', '111.', '112.', '113.', '114.',
        '115.', '116.', '117.', '118.', '119.', '120.', '121.', '122.', '123.',
        '124.', '125.', '140.', '144.', '150.', '153.', '163.', '171.', '175.',
        '180.', '182.', '183.', '192.', '202.', '203.', '210.', '211.', '218.',
        '219.', '220.', '221.', '222.', '223.'
    ];
    
    const isLikelyChina = !countryCode && chineseIPRanges.some(range => clientIP.startsWith(range));
    
    // Determine optimal origin
    let targetOrigin;
    let routingReason;
    
    if (useJapanOrigin || isLikelyChina) {
        // Route to Japan origin (closer to China)
        targetOrigin = '${secondary_origin_id}';
        routingReason = useJapanOrigin 
            ? `Country-based routing: ${countryCode}` 
            : 'IP-based China detection';
        
        // Add special headers for China-optimized path
        request.headers['x-china-optimized'] = [{ key: 'X-China-Optimized', value: 'true' }];
        request.headers['x-origin-region'] = [{ key: 'X-Origin-Region', value: 'jp' }];
        
    } else {
        // Route to Singapore origin (primary)
        targetOrigin = '${primary_origin_id}';
        routingReason = `Default routing for country: ${countryCode || 'unknown'}`;
        request.headers['x-origin-region'] = [{ key: 'X-Origin-Region', value: 'sg' }];
    }
    
    // Update the request origin
    request.origin = {
        custom: {
            domainName: getDomainForOrigin(targetOrigin),
            port: 443,
            protocol: 'https',
            path: '',
            sslProtocols: ['TLSv1.2'],
            readTimeout: 30,
            keepaliveTimeout: 5
        }
    };
    
    // Add routing metadata to headers
    request.headers['x-routing-decision'] = [{
        key: 'X-Routing-Decision',
        value: routingReason
    }];
    
    request.headers['x-target-origin'] = [{
        key: 'X-Target-Origin', 
        value: targetOrigin
    }];
    
    // Network quality optimization for China users
    if (useJapanOrigin || isLikelyChina) {
        // Prefer smaller response sizes for slower networks
        request.headers['accept-encoding'] = [{
            key: 'Accept-Encoding',
            value: 'gzip, deflate, br'
        }];
        
        // Add cache-friendly headers
        request.headers['x-prefer-cached'] = [{
            key: 'X-Prefer-Cached',
            value: 'true'
        }];
    }
    
    // A/B testing for performance optimization
    const performanceGroup = getPerformanceTestGroup(clientIP);
    request.headers['x-performance-group'] = [{
        key: 'X-Performance-Group',
        value: performanceGroup
    }];
    
    console.log(`Routing decision: ${routingReason}, target: ${targetOrigin}`);
    
    return request;
};

/**
 * Get domain name for origin ID
 */
function getDomainForOrigin(originId) {
    const originMap = {
        'primary-app-origin': process.env.PRIMARY_ALB_DOMAIN,
        'secondary-app-origin': process.env.SECONDARY_ALB_DOMAIN
    };
    
    return originMap[originId] || originMap['primary-app-origin'];
}

/**
 * Assign users to performance test groups for optimization experiments
 */
function getPerformanceTestGroup(clientIP) {
    // Simple hash-based assignment for consistent grouping
    const hash = clientIP.split('.').reduce((acc, octet) => acc + parseInt(octet), 0);
    const groups = ['control', 'optimized-cache', 'compressed-response'];
    return groups[hash % groups.length];
}

/**
 * Additional helper for dynamic origin failover
 */
function checkOriginHealth(originId) {
    // In production, this could make health checks
    // For now, assume origins are healthy
    return true;
}