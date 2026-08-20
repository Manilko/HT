import WebSocket from 'ws';
import { WebSocketMessage } from '@types/index';

export class WebSocketGateway {
  private clients: Map<number, WebSocket.Server> = new Map();

  async handleConnection(client: WebSocket, userId: number): Promise<void> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async handleMessage(userId: number, message: WebSocketMessage): Promise<void> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async handleDisconnection(userId: number): Promise<void> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async broadcastMilestone(userId: number, habitId: number, milestone: number): Promise<void> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }
}
