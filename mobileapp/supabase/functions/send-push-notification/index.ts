// Supabase Edge Function: send-push-notification
// Sends push notifications via Firebase Cloud Messaging HTTP v1 API

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Types
interface PushNotificationRequest {
  user_id: string
  title: string
  body: string
  data?: Record<string, string>
}

interface FCMToken {
  id: string
  user_id: string
  token: string
  device_type: string
}

interface FCMMessage {
  message: {
    token: string
    notification: {
      title: string
      body: string
    }
    data?: Record<string, string>
    android?: {
      priority: string
      notification: {
        channel_id: string
        sound: string
      }
    }
  }
}

// Get FCM access token using service account
async function getFCMAccessToken(): Promise<string> {
  const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
  if (!serviceAccountJson) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT environment variable not set')
  }

  const serviceAccount = JSON.parse(serviceAccountJson)

  // Create JWT for Google OAuth
  const header = {
    alg: 'RS256',
    typ: 'JWT',
  }

  const now = Math.floor(Date.now() / 1000)
  const claim = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  }

  // Encode header and claim
  const encoder = new TextEncoder()
  const headerB64 = btoa(JSON.stringify(header)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')
  const claimB64 = btoa(JSON.stringify(claim)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')
  const unsignedToken = `${headerB64}.${claimB64}`

  // Sign with private key
  const privateKey = serviceAccount.private_key
  const pemHeader = '-----BEGIN PRIVATE KEY-----'
  const pemFooter = '-----END PRIVATE KEY-----'
  const pemContents = privateKey.replace(pemHeader, '').replace(pemFooter, '').replace(/\s/g, '')
  const binaryDer = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0))

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    binaryDer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  )

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    encoder.encode(unsignedToken)
  )

  const signatureB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')

  const jwt = `${unsignedToken}.${signatureB64}`

  // Exchange JWT for access token
  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  })

  const tokenData = await tokenResponse.json()
  if (!tokenData.access_token) {
    throw new Error(`Failed to get access token: ${JSON.stringify(tokenData)}`)
  }

  return tokenData.access_token
}

// Send push notification via FCM HTTP v1 API
async function sendPushNotification(
  token: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<{ success: boolean; error?: string }> {
  const projectId = Deno.env.get('FIREBASE_PROJECT_ID')
  if (!projectId) {
    return { success: false, error: 'FIREBASE_PROJECT_ID not set' }
  }

  try {
    const accessToken = await getFCMAccessToken()

    const message: FCMMessage = {
      message: {
        token,
        notification: {
          title,
          body,
        },
        data,
        android: {
          priority: 'high',
          notification: {
            channel_id: 'paws_notifications',
            sound: 'default',
          },
        },
      },
    }

    const response = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(message),
      }
    )

    if (!response.ok) {
      const errorData = await response.json()

      // Check for invalid/expired token errors
      const errorCode = errorData?.error?.details?.[0]?.errorCode
      if (errorCode === 'UNREGISTERED' || errorCode === 'INVALID_ARGUMENT') {
        return { success: false, error: 'TOKEN_INVALID' }
      }

      return { success: false, error: JSON.stringify(errorData) }
    }

    return { success: true }
  } catch (error) {
    return { success: false, error: error.message }
  }
}

serve(async (req) => {
  // CORS headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  }

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Parse request body
    const { user_id, title, body, data } = await req.json() as PushNotificationRequest

    if (!user_id || !title || !body) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: user_id, title, body' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Initialize Supabase client with service role
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Get user's FCM tokens
    const { data: tokens, error: tokensError } = await supabase
      .from('fcm_tokens')
      .select('*')
      .eq('user_id', user_id)

    if (tokensError) {
      console.error('Error fetching tokens:', tokensError)
      return new Response(
        JSON.stringify({ error: 'Failed to fetch FCM tokens' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!tokens || tokens.length === 0) {
      console.log(`No FCM tokens found for user ${user_id}`)
      return new Response(
        JSON.stringify({ message: 'No FCM tokens registered for this user' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Send to all user's devices
    const results: { token: string; success: boolean; error?: string }[] = []
    const tokensToDelete: string[] = []

    for (const fcmToken of tokens as FCMToken[]) {
      const result = await sendPushNotification(fcmToken.token, title, body, data)
      results.push({ token: fcmToken.token.substring(0, 20) + '...', ...result })

      // Mark invalid tokens for deletion
      if (!result.success && result.error === 'TOKEN_INVALID') {
        tokensToDelete.push(fcmToken.id)
      }
    }

    // Clean up invalid tokens
    if (tokensToDelete.length > 0) {
      await supabase
        .from('fcm_tokens')
        .delete()
        .in('id', tokensToDelete)
      console.log(`Deleted ${tokensToDelete.length} invalid tokens`)
    }

    const successCount = results.filter((r) => r.success).length
    console.log(`Sent ${successCount}/${results.length} push notifications for user ${user_id}`)

    return new Response(
      JSON.stringify({
        message: `Sent to ${successCount}/${results.length} devices`,
        results,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Edge function error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
