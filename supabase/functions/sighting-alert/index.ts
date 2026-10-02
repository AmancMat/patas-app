import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4"
import { sendFcmNotification } from "../common/fcm.ts"
import { getCorsHeaders, handleCors } from "../common/cors.ts"

serve(async (req) => {
  // CORS check com Allowlist oficial
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;
  const corsHeaders = getCorsHeaders(req);

  try {
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const body = await req.json()

    let tagId: string
    let latitude: number | null = null
    let longitude: number | null = null

    if (body.type === 'INSERT' && body.table === 'sightings') {
      const record = body.record
      tagId = record.tag_id
      latitude = record.latitude
      longitude = record.longitude
    } else {
      tagId = body.tag_id
      latitude = body.latitude
      longitude = body.longitude
    }

    if (!tagId) {
      throw new Error('tag_id é obrigatório')
    }

    const { data: tag, error: tagError } = await supabaseAdmin
      .from('tags')
      .select('id, pet_id, tutor_id, is_lost, pets(id, name, photo_url)')
      .eq('id', tagId)
      .single()

    if (tagError || !tag) {
      throw new Error(`Tag não encontrada: ${tagId}`)
    }

    if (tag.is_lost !== true) {
      return new Response(
        JSON.stringify({ message: 'Tag não está no modo perdido. Alerta ignorado.' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Lê o tutor_id diretamente da tag (mais robusto que buscar via pet)
    const tutorId = tag.tutor_id as string
    if (!tutorId) {
      throw new Error(`Tag sem tutor associado: ${tagId}`)
    }

    // Trata pets de forma segura caso o Supabase retorne como objeto único ou array
    let petName = 'Pet'
    let petId = tag.pet_id as string | null

    if (tag.pets) {
      if (Array.isArray(tag.pets) && tag.pets.length > 0) {
        petName = (tag.pets[0].name as string) ?? 'Pet'
        petId = (tag.pets[0].id as string) ?? petId
      } else if (!Array.isArray(tag.pets)) {
        const petObj = tag.pets as Record<string, unknown>
        petName = (petObj.name as string) ?? 'Pet'
        petId = (petObj.id as string) ?? petId
      }
    }

    const { data: tutorUser, error: userError } = await supabaseAdmin
      .from('users')
      .select('fcm_token, notification_sound_key')
      .eq('id', tutorId)
      .single()

    if (userError || !tutorUser?.fcm_token) {
      console.warn(`Tutor ${tutorId} não possui FCM token cadastrado. Notificação ignorada.`)
      return new Response(
        JSON.stringify({ 
          message: 'FCM token não disponível para o tutor.',
          debug: {
            tutorId,
            userError: userError ? { message: userError.message, details: userError.details, code: userError.code } : null,
            tutorUserFound: tutorUser ? { hasToken: !!tutorUser.fcm_token, sound: tutorUser.notification_sound_key } : null,
            tagReceived: { id: tag.id, tutor_id: tag.tutor_id, pet_id: tag.pet_id }
          }
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const fcmToken = tutorUser.fcm_token as string
    const notificationSound = (tutorUser.notification_sound_key as string) ?? 'default'

    let locationText = 'Localização disponível no app.'
    if (latitude && longitude) {
      locationText = `📍 Lat: ${latitude.toFixed(4)}, Long: ${longitude.toFixed(4)}`
    }

    // Disparar push notification usando o novo módulo HTTP v1
    const channelId = notificationSound !== 'default'
      ? `channel_${notificationSound}`
      : 'high_importance_channel'

    await sendFcmNotification({
      token: fcmToken,
      title: `🚨 ${petName} foi avistado!`,
      body: locationText,
      sound: notificationSound,
      channelId,
      data: {
        type: 'sighting_alert',
        tag_id: tagId,
        pet_id: petId as string,
        pet_name: petName,
        latitude: String(latitude ?? ''),
        longitude: String(longitude ?? ''),
      },
    })

    await supabaseAdmin.from('notifications').insert({
      user_id: tutorId,
      type: 'sighting',
      title: `🚨 ${petName} foi avistado!`,
      content: locationText,
      data: {
        tag_id: tagId,
        pet_id: petId,
        latitude,
        longitude,
      },
    })

    console.log(`✅ Alerta de avistamento FCM v1 enviado para tutor ${tutorId}. Pet: ${petName}`)

    return new Response(
      JSON.stringify({ success: true, message: `Alerta enviado para ${petName}` }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('❌ ERRO NO SIGHTING-ALERT:', error.message)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
