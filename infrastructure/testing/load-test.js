// K6 Load Testing Script for WhatsApp Clone
// Tests web app performance, messaging simulation, and meeting load

import http from 'k6/http';
import ws from 'k6/ws';
import { check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// Custom metrics
const messageRate = new Rate('message_success_rate');
const connectionTime = new Trend('websocket_connection_time');
const messageLatency = new Trend('message_latency');
const errorCount = new Counter('errors');

// Test configuration
const TARGET_URL = __ENV.TARGET_URL || 'https://whatsappclone.com';
const SUPABASE_URL = __ENV.SUPABASE_URL || 'https://your-project.supabase.co';
const LIVEKIT_URL = __ENV.LIVEKIT_URL || 'wss://whatsappclone.livekit.cloud';

// Load testing scenarios
export const options = {
  scenarios: {
    // Web application load test
    web_load: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '2m', target: 50 },   // Ramp up to 50 users
        { duration: '5m', target: 50 },   // Stay at 50 users
        { duration: '2m', target: 100 },  // Ramp up to 100 users
        { duration: '10m', target: 100 }, // Stay at 100 users
        { duration: '3m', target: 200 },  // Spike to 200 users
        { duration: '2m', target: 200 },  // Stay at 200 users
        { duration: '2m', target: 0 },    // Ramp down
      ],
      gracefulRampDown: '30s',
      tags: { test_type: 'web_load' },
    },

    // Real-time messaging simulation
    messaging_load: {
      executor: 'constant-vus',
      vus: 50,
      duration: '15m',
      tags: { test_type: 'messaging' },
    },

    // Meeting/call load simulation
    meeting_load: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '1m', target: 10 },   // Ramp up to 10 concurrent meetings
        { duration: '10m', target: 10 },  // Maintain 10 meetings
        { duration: '2m', target: 20 },   // Spike to 20 meetings
        { duration: '2m', target: 20 },   // Maintain spike
        { duration: '1m', target: 0 },    // Ramp down
      ],
      tags: { test_type: 'meetings' },
    },

    // China network simulation (high latency)
    china_simulation: {
      executor: 'constant-vus',
      vus: 20,
      duration: '10m',
      tags: { test_type: 'china_network' },
    }
  },

  thresholds: {
    // Overall performance thresholds
    http_req_duration: ['p(95)<2000', 'p(99)<5000'], // 95% < 2s, 99% < 5s
    http_req_failed: ['rate<0.05'],                    // Error rate < 5%
    
    // Custom metrics thresholds
    message_success_rate: ['rate>0.95'],              // 95% message success
    websocket_connection_time: ['p(95)<1000'],        // 95% connections < 1s
    message_latency: ['p(95)<500'],                    // 95% messages < 500ms
    
    // Scenario-specific thresholds
    'http_req_duration{test_type:web_load}': ['p(95)<1500'],
    'http_req_duration{test_type:messaging}': ['p(95)<800'],
    'http_req_duration{test_type:china_network}': ['p(95)<3000'],
  },
};

// Test data
const testUsers = [
  { email: 'user1@test.com', password: 'testpass123' },
  { email: 'user2@test.com', password: 'testpass123' },
  { email: 'user3@test.com', password: 'testpass123' },
];

const testMessages = [
  'Hello there!',
  'How are you doing?',
  'This is a test message for load testing.',
  'Can you see this message?',
  '👋 Hello from the load test!',
  'Testing emoji support 😊',
  'Long message to test performance with larger payloads. This message contains more text to simulate real user behavior when sending longer messages.',
];

// Setup function - runs once per VU
export function setup() {
  // Health check
  const healthRes = http.get(`${TARGET_URL}/health`);
  check(healthRes, {
    'health check passes': (r) => r.status === 200,
  });

  return {
    baseUrl: TARGET_URL,
    supabaseUrl: SUPABASE_URL,
    livekitUrl: LIVEKIT_URL,
  };
}

// Main test function
export default function (data) {
  const scenario = __ENV.K6_SCENARIO || 'web_load';
  
  switch (scenario) {
    case 'web_load':
      testWebApplication(data);
      break;
    case 'messaging':
      testMessaging(data);
      break;
    case 'meetings':
      testMeetingLoad(data);
      break;
    case 'china_network':
      testChinaNetwork(data);
      break;
    default:
      testWebApplication(data);
  }
}

// Web application load testing
function testWebApplication(data) {
  const responses = http.batch([
    ['GET', `${data.baseUrl}/`, null, { tags: { name: 'homepage' } }],
    ['GET', `${data.baseUrl}/login`, null, { tags: { name: 'login_page' } }],
    ['GET', `${data.baseUrl}/signup`, null, { tags: { name: 'signup_page' } }],
  ]);

  responses.forEach((response, index) => {
    check(response, {
      [`request ${index} status is 200`]: (r) => r.status === 200,
      [`request ${index} response time < 2s`]: (r) => r.timings.duration < 2000,
    });
  });

  // Simulate user authentication
  const authPayload = {
    email: testUsers[Math.floor(Math.random() * testUsers.length)].email,
    password: 'testpass123',
  };

  const authResponse = http.post(
    `${data.supabaseUrl}/auth/v1/token?grant_type=password`,
    JSON.stringify(authPayload),
    {
      headers: {
        'Content-Type': 'application/json',
        'apikey': 'your-supabase-anon-key',
      },
      tags: { name: 'authentication' },
    }
  );

  const authSuccess = check(authResponse, {
    'authentication successful': (r) => r.status === 200,
    'auth response time < 1s': (r) => r.timings.duration < 1000,
  });

  if (!authSuccess) {
    errorCount.add(1);
    return;
  }

  // Test dashboard and chat list loading
  const dashboardResponse = http.get(
    `${data.baseUrl}/dashboard`,
    {
      headers: {
        'Authorization': `Bearer ${JSON.parse(authResponse.body).access_token}`,
      },
      tags: { name: 'dashboard' },
    }
  );

  check(dashboardResponse, {
    'dashboard loads successfully': (r) => r.status === 200,
    'dashboard response time < 1.5s': (r) => r.timings.duration < 1500,
  });

  sleep(1); // Simulate user reading time
}

// Real-time messaging simulation
function testMessaging(data) {
  const startTime = Date.now();
  
  const wsUrl = data.supabaseUrl.replace('https://', 'wss://') + '/realtime/v1/websocket';
  
  const response = ws.connect(wsUrl, {
    headers: {
      'apikey': 'your-supabase-anon-key',
    },
  }, function (socket) {
    connectionTime.add(Date.now() - startTime);

    socket.on('open', () => {
      console.log('WebSocket connected');
      
      // Join a chat channel
      const joinPayload = {
        topic: 'realtime:public:messages',
        event: 'phx_join',
        payload: {},
        ref: '1',
      };
      
      socket.send(JSON.stringify(joinPayload));
    });

    socket.on('message', (message) => {
      const data = JSON.parse(message);
      
      if (data.event === 'INSERT') {
        const latency = Date.now() - data.payload.timestamp;
        messageLatency.add(latency);
        messageRate.add(true);
      }
    });

    socket.on('error', (e) => {
      console.error('WebSocket error:', e);
      errorCount.add(1);
      messageRate.add(false);
    });

    // Send test messages periodically
    const messageInterval = setInterval(() => {
      const message = {
        topic: 'realtime:public:messages',
        event: 'INSERT',
        payload: {
          content: testMessages[Math.floor(Math.random() * testMessages.length)],
          user_id: Math.floor(Math.random() * 1000),
          chat_id: Math.floor(Math.random() * 10),
          timestamp: Date.now(),
        },
        ref: String(Date.now()),
      };

      socket.send(JSON.stringify(message));
    }, 2000 + Math.random() * 3000); // Send message every 2-5 seconds

    socket.setTimeout(() => {
      clearInterval(messageInterval);
      socket.close();
    }, 60000); // Close after 1 minute
  });

  check(response, {
    'WebSocket connection successful': (r) => r && r.status === 101,
  });
}

// Meeting/video call load simulation
function testMeetingLoad(data) {
  // Simulate LiveKit room creation
  const roomName = `load-test-room-${Math.floor(Math.random() * 1000)}`;
  
  const createRoomResponse = http.post(
    `${data.livekitUrl}/twirp/livekit.RoomService/CreateRoom`,
    JSON.stringify({
      name: roomName,
      empty_timeout: 300,
      max_participants: 50,
    }),
    {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer your-livekit-token',
      },
      tags: { name: 'create_room' },
    }
  );

  const roomCreated = check(createRoomResponse, {
    'room created successfully': (r) => r.status === 200,
    'room creation time < 2s': (r) => r.timings.duration < 2000,
  });

  if (!roomCreated) {
    errorCount.add(1);
    return;
  }

  // Simulate participant joining
  const participantCount = 5 + Math.floor(Math.random() * 10); // 5-15 participants
  
  for (let i = 0; i < participantCount; i++) {
    const joinResponse = http.post(
      `${data.livekitUrl}/twirp/livekit.RoomService/CreateAccessToken`,
      JSON.stringify({
        room: roomName,
        identity: `participant-${i}`,
        video: true,
        audio: true,
      }),
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer your-livekit-token',
        },
        tags: { name: 'join_room' },
      }
    );

    check(joinResponse, {
      [`participant ${i} joined successfully`]: (r) => r.status === 200,
    });

    sleep(0.5); // Stagger participant joins
  }

  // Simulate meeting duration
  sleep(30 + Math.random() * 60); // 30-90 seconds

  // Clean up room
  http.post(
    `${data.livekitUrl}/twirp/livekit.RoomService/DeleteRoom`,
    JSON.stringify({ room: roomName }),
    {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer your-livekit-token',
      },
      tags: { name: 'delete_room' },
    }
  );
}

// China network simulation with high latency
function testChinaNetwork(data) {
  // Add artificial delay to simulate China network conditions
  const networkDelay = 300 + Math.random() * 500; // 300-800ms additional delay
  
  sleep(networkDelay / 1000);
  
  // Test with increased timeout thresholds
  const response = http.get(`${data.baseUrl}/`, {
    timeout: '10s', // Higher timeout for China conditions
    tags: { name: 'china_homepage' },
  });

  check(response, {
    'china network - page loads': (r) => r.status === 200,
    'china network - reasonable load time': (r) => r.timings.duration < 5000,
  });

  // Test CDN performance for static assets
  const cdnResponse = http.get(`${data.baseUrl}/flutter.js`, {
    tags: { name: 'china_cdn_asset' },
  });

  check(cdnResponse, {
    'china network - CDN asset loads': (r) => r.status === 200,
    'china network - CDN performance acceptable': (r) => r.timings.duration < 3000,
  });

  sleep(2); // Simulate user interaction delay
}

// Teardown function
export function teardown(data) {
  // Cleanup or final health check
  const finalHealthRes = http.get(`${data.baseUrl}/health`);
  check(finalHealthRes, {
    'final health check passes': (r) => r.status === 200,
  });
}