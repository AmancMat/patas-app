import { JWT } from 'https://esm.sh/google-auth-library@9.0.0';

interface FcmNotificationPayload {
  token: string;
  title: string;
  body: string;
  sound: string;
  channelId: string;
  data: Record<string, string>;
}

export async function sendFcmNotification(payload: FcmNotificationPayload) {
  let serviceAccountRaw = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
  if (!serviceAccountRaw) {
    throw new Error('Secret FIREBASE_SERVICE_ACCOUNT não está configurado.');
  }

  // Decodifica se estiver em Base64 (não começa com '{')
  serviceAccountRaw = serviceAccountRaw.trim();
  if (!serviceAccountRaw.startsWith('{')) {
    try {
      serviceAccountRaw = atob(serviceAccountRaw);
    } catch (e) {
      throw new Error(`Falha ao decodificar Base64 do FIREBASE_SERVICE_ACCOUNT: ${e.message}`);
    }
  }

  const credentials = JSON.parse(serviceAccountRaw);

  // 1. Obter o token de acesso OAuth2 usando o SDK oficial do Google
  const auth = new JWT({
    email: credentials.client_email,
    key: credentials.private_key,
    scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
  });

  const tokenInfo = await auth.getAccessToken();
  const accessToken = tokenInfo.token;
  if (!accessToken) {
    throw new Error('Falha ao obter token de acesso OAuth2 do Google.');
  }

  // 2. Montar o payload da mensagem no formato FCM HTTP v1
  const message = {
    message: {
      token: payload.token,
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: payload.data,
      android: {
        priority: 'high',
        notification: {
          sound: payload.sound !== 'default' ? payload.sound : 'default',
          channel_id: payload.channelId,
        },
      },
      apns: {
        headers: {
          'apns-priority': '10',
        },
        payload: {
          aps: {
            sound: payload.sound !== 'default' ? `${payload.sound}.wav` : 'default',
          },
        },
      },
    },
  };

  const projectId = credentials.project_id;
  const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

  // 3. Enviar a requisição POST para o FCM HTTP v1
  const response = await fetch(fcmUrl, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(message),
  });

  const result = await response.json();
  if (!response.ok) {
    throw new Error(`Erro na API do FCM v1: ${JSON.stringify(result)}`);
  }

  return result;
}
