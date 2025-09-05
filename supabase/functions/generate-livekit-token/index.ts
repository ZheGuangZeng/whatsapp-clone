import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { AccessToken } from 'https://esm.sh/livekit-server-sdk@1'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Get the user from the Authorization header
    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser()

    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Parse request body
    const { meeting_id, user_id, role = 'participant', ttl_seconds = 7200 } = await req.json()

    if (!meeting_id || !user_id) {
      return new Response(
        JSON.stringify({ error: 'Missing required parameters: meeting_id, user_id' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Verify user has access to this meeting
    const { data: meeting, error: meetingError } = await supabaseClient
      .from('meetings')
      .select(`
        *,
        participants:meeting_participants!inner(user_id, role)
      `)
      .eq('id', meeting_id)
      .or(`host_id.eq.${user_id},participants.user_id.eq.${user_id}`)
      .single()

    if (meetingError || !meeting) {
      return new Response(
        JSON.stringify({ error: 'Meeting not found or access denied' }),
        {
          status: 403,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Get LiveKit configuration from environment
    const livekitApiKey = Deno.env.get('LIVEKIT_API_KEY')
    const livekitApiSecret = Deno.env.get('LIVEKIT_API_SECRET')

    if (!livekitApiKey || !livekitApiSecret) {
      console.error('LiveKit credentials not configured')
      return new Response(
        JSON.stringify({ error: 'LiveKit not configured' }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Create LiveKit access token
    const token = new AccessToken(livekitApiKey, livekitApiSecret, {
      identity: user_id,
      name: user.user_metadata?.display_name || user.email,
      ttl: ttl_seconds,
    })

    // Set permissions based on role
    const roomName = meeting.livekit_room_name
    
    if (role === 'host' || role === 'admin') {
      // Host and admin have full permissions
      token.addGrant({
        room: roomName,
        roomJoin: true,
        roomList: true,
        roomRecord: true,
        roomAdmin: true,
        roomCreate: false,
        canPublish: true,
        canSubscribe: true,
        canPublishData: true,
        canUpdateOwnMetadata: true,
      })
    } else {
      // Participants have limited permissions
      token.addGrant({
        room: roomName,
        roomJoin: true,
        roomList: false,
        roomRecord: false,
        roomAdmin: false,
        roomCreate: false,
        canPublish: true,
        canSubscribe: true,
        canPublishData: true,
        canUpdateOwnMetadata: true,
      })
    }

    const jwt = await token.toJwt()

    return new Response(
      JSON.stringify({
        token: jwt,
        room_name: roomName,
        identity: user_id,
        expires_at: new Date(Date.now() + ttl_seconds * 1000).toISOString(),
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  } catch (error) {
    console.error('Error generating LiveKit token:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})