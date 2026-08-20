//
//  handler.ts
//  WebSocket Connection Handler
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import WebSocket from 'ws';
import { verifyAccessToken } from '../utils/tokenUtils';
import { getMilestoneNotifications, recordMilestoneDelivery } from '../services/milestoneService';
import { logger } from '../config/logger';

export interface AuthenticatedWebSocket extends WebSocket {
  userId?: number;
  email?: string;
  isSubscribed?: boolean;
}

export interface WebSocketMessage {
  type: string;
  payload?: unknown;
}

export interface SubscribeMessage extends WebSocketMessage {
  type: 'subscribe';
  payload: {
    milestones: boolean;
  };
}

export interface UnsubscribeMessage extends WebSocketMessage {
  type: 'unsubscribe';
}

export interface MilestonePayload {
  habitId: number;
  habitName: string;
  milestone: number;
  currentStreak: number;
}

export interface MilestoneMessage extends WebSocketMessage {
  type: 'streak_milestone';
  payload: MilestonePayload;
}

export async function handleWebSocketConnection(
  ws: AuthenticatedWebSocket,
  req: any,
): Promise<void> {
  try {
    // Extract and verify token
    const token = extractTokenFromUrl(req.url);
    if (!token) {
      logger.warn('WebSocket connection attempted without token');
      ws.close(1008, 'Missing authentication token');
      return;
    }

    const decoded = verifyAccessToken(token);
    if (!decoded) {
      logger.warn('WebSocket connection attempted with invalid token');
      ws.close(1008, 'Invalid authentication token');
      return;
    }

    // Authenticate user from token (never from client)
    ws.userId = decoded.userId;
    ws.email = decoded.email;
    ws.isSubscribed = false;

    logger.info(`WebSocket connection established for user ${ws.userId}`);

    // Handle messages
    ws.on('message', async (data: WebSocket.Data) => {
      await handleMessage(ws, data);
    });

    // Handle connection close
    ws.on('close', () => {
      logger.info(`WebSocket connection closed for user ${ws.userId}`);
    });

    // Handle errors
    ws.on('error', (error) => {
      logger.error(`WebSocket error for user ${ws.userId}`, error);
    });
  } catch (error) {
    logger.error('WebSocket connection error', error);
    ws.close(1011, 'Internal server error');
  }
}

async function handleMessage(ws: AuthenticatedWebSocket, data: WebSocket.Data): Promise<void> {
  try {
    const message = parseMessage(data);

    switch (message.type) {
      case 'subscribe':
        await handleSubscribe(ws, message as SubscribeMessage);
        break;

      case 'unsubscribe':
        await handleUnsubscribe(ws, message as UnsubscribeMessage);
        break;

      default:
        logger.warn(`Unknown message type: ${message.type}`);
        ws.send(JSON.stringify({ type: 'error', payload: { message: 'Unknown message type' } }));
    }
  } catch (error) {
    logger.error('Error handling WebSocket message', error);
    ws.send(JSON.stringify({ type: 'error', payload: { message: 'Invalid message format' } }));
  }
}

async function handleSubscribe(
  ws: AuthenticatedWebSocket,
  message: SubscribeMessage,
): Promise<void> {
  if (!message.payload?.milestones) {
    ws.send(JSON.stringify({ type: 'error', payload: { message: 'Invalid subscribe payload' } }));
    return;
  }

  ws.isSubscribed = true;
  logger.info(`User ${ws.userId} subscribed to milestone notifications`);

  // Send any pending milestones
  try {
    const notifications = await getMilestoneNotifications(ws.userId!);

    for (const notification of notifications) {
      const milestoneMessage: MilestoneMessage = {
        type: 'streak_milestone',
        payload: {
          habitId: notification.habitId,
          habitName: notification.habitName,
          milestone: notification.milestone,
          currentStreak: notification.currentStreak,
        },
      };

      ws.send(JSON.stringify(milestoneMessage));

      // Record as delivered
      await recordMilestoneDelivery(ws.userId!, notification.habitId, notification.milestone);
    }

    logger.info(`Sent ${notifications.length} milestone notifications to user ${ws.userId}`);
  } catch (error) {
    logger.error(`Failed to send milestone notifications`, error);
    ws.send(JSON.stringify({ type: 'error', payload: { message: 'Failed to load milestones' } }));
  }
}

async function handleUnsubscribe(
  ws: AuthenticatedWebSocket,
  message: UnsubscribeMessage,
): Promise<void> {
  ws.isSubscribed = false;
  logger.info(`User ${ws.userId} unsubscribed from milestone notifications`);
}

function parseMessage(data: WebSocket.Data): WebSocketMessage {
  if (typeof data !== 'string') {
    throw new Error('Message must be a string');
  }

  const parsed = JSON.parse(data);

  if (!parsed.type || typeof parsed.type !== 'string') {
    throw new Error('Message must have a type field');
  }

  return parsed as WebSocketMessage;
}

function extractTokenFromUrl(url: string): string | null {
  try {
    const urlObj = new URL(url, 'ws://localhost');
    return urlObj.searchParams.get('token');
  } catch {
    return null;
  }
}
