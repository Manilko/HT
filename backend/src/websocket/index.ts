//
//  index.ts
//  WebSocket Gateway
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import { Server as HTTPServer } from 'http';
import WebSocket from 'ws';
import { logger } from '../config/logger';
import { verifyToken } from '../utils/tokenUtils';

interface ClientConnection {
  ws: WebSocket;
  userId: number;
  subscribedHabits: Set<number>;
}

export class WebSocketGateway {
  private wss: WebSocket.Server;
  private clients: Map<string, ClientConnection> = new Map();

  constructor(httpServer: HTTPServer) {
    this.wss = new WebSocket.Server({ server: httpServer });
    this.setupEventHandlers();
  }

  private setupEventHandlers(): void {
    this.wss.on('connection', (ws: WebSocket, req) => {
      this.handleConnection(ws, req);
    });
  }

  private async handleConnection(ws: WebSocket, req: any): Promise<void> {
    try {
      const token = this.extractToken(req);
      if (!token) {
        ws.close(1008, 'Missing authentication token');
        return;
      }

      const payload = verifyToken(token);
      const userId = payload.sub;
      const clientId = `${userId}-${Date.now()}`;

      const connection: ClientConnection = {
        ws,
        userId,
        subscribedHabits: new Set(),
      };

      this.clients.set(clientId, connection);
      logger.info(`WebSocket client connected`, { userId, clientId });

      ws.on('message', (data: WebSocket.Data) => {
        this.handleMessage(clientId, data);
      });

      ws.on('close', () => {
        this.handleDisconnection(clientId);
      });

      ws.on('error', (error: Error) => {
        logger.error('WebSocket error', error);
      });
    } catch (error) {
      logger.warn('WebSocket auth failed', error instanceof Error ? error.message : 'unknown');
      ws.close(1008, 'Authentication failed');
    }
  }

  private handleMessage(clientId: string, data: WebSocket.Data): void {
    try {
      const connection = this.clients.get(clientId);
      if (!connection) return;

      const message = JSON.parse(data.toString());

      switch (message.type) {
      case 'subscribe_milestone':
        connection.subscribedHabits.add(message.data.habit_id);
        logger.debug('Client subscribed to habit', { clientId, habitId: message.data.habit_id });
        break;

      case 'unsubscribe_milestone':
        connection.subscribedHabits.delete(message.data.habit_id);
        logger.debug('Client unsubscribed from habit', { clientId, habitId: message.data.habit_id });
        break;

      case 'ping':
        connection.ws.send(JSON.stringify({ type: 'pong', timestamp: new Date().toISOString() }));
        break;

      default:
        logger.warn('Unknown WebSocket message type', { type: message.type });
      }
    } catch (error) {
      logger.error('Error handling WebSocket message', error);
    }
  }

  private handleDisconnection(clientId: string): void {
    const connection = this.clients.get(clientId);
    if (connection) {
      this.clients.delete(clientId);
      logger.info(`WebSocket client disconnected`, { userId: connection.userId, clientId });
    }
  }

  private extractToken(req: any): string | null {
    const url = new URL(req.url || '', 'http://localhost');
    return url.searchParams.get('token');
  }

  public broadcastMilestone(userId: number, habitId: number, milestone: number): void {
    const message = JSON.stringify({
      type: 'milestone_reached',
      data: {
        habit_id: habitId,
        current_streak: milestone,
        milestone,
      },
      timestamp: new Date().toISOString(),
    });

    for (const [, connection] of this.clients) {
      if (connection.userId === userId && connection.subscribedHabits.has(habitId)) {
        if (connection.ws.readyState === WebSocket.OPEN) {
          connection.ws.send(message);
        }
      }
    }
  }

  public close(): Promise<void> {
    return new Promise((resolve) => {
      this.wss.close(() => {
        logger.info('WebSocket server closed');
        resolve();
      });
    });
  }
}
