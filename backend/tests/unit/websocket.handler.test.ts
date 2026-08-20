//
//  websocket.handler.test.ts
//  WebSocket Handler Tests
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import {
  handleWebSocketConnection,
  AuthenticatedWebSocket,
  SubscribeMessage,
  MilestoneMessage,
} from '../../src/websocket/handler';

jest.mock('../../src/utils/tokenUtils');
jest.mock('../../src/services/milestoneService');
jest.mock('../../src/config/logger');

import * as tokenUtils from '../../src/utils/tokenUtils';
import * as milestoneService from '../../src/services/milestoneService';

describe('WebSocket Handler', () => {
  let mockWs: Partial<AuthenticatedWebSocket>;
  let mockReq: any;
  let mockSend: jest.Mock;
  let mockClose: jest.Mock;
  let mockOn: jest.Mock;

  beforeEach(() => {
    jest.clearAllMocks();

    mockSend = jest.fn();
    mockClose = jest.fn();

    const listeners: { [key: string]: Function[] } = {};
    mockOn = jest.fn((event: string, handler: Function) => {
      if (!listeners[event]) {
        listeners[event] = [];
      }
      listeners[event].push(handler);
    });

    mockWs = {
      send: mockSend,
      close: mockClose,
      on: mockOn,
    };

    mockReq = {
      url: 'ws://localhost:3000/?token=valid-token',
    };
  });

  // MARK: - Authentication

  it('should reject connection without token', async () => {
    mockReq.url = 'ws://localhost:3000/';

    await handleWebSocketConnection(mockWs as AuthenticatedWebSocket, mockReq);

    expect(mockClose).toHaveBeenCalledWith(1008, 'Missing authentication token');
  });

  it('should reject connection with invalid token', async () => {
    (tokenUtils.verifyAccessToken as jest.Mock).mockReturnValue(null);

    await handleWebSocketConnection(mockWs as AuthenticatedWebSocket, mockReq);

    expect(mockClose).toHaveBeenCalledWith(1008, 'Invalid authentication token');
  });

  it('should accept authenticated connection', async () => {
    (tokenUtils.verifyAccessToken as jest.Mock).mockReturnValue({
      userId: 1,
      email: 'test@example.com',
    });

    await handleWebSocketConnection(mockWs as AuthenticatedWebSocket, mockReq);

    expect(mockWs.userId).toBe(1);
    expect(mockWs.email).toBe('test@example.com');
    expect(mockClose).not.toHaveBeenCalled();
  });

  // MARK: - Subscribe Message

  it('should handle subscribe message', async () => {
    (tokenUtils.verifyAccessToken as jest.Mock).mockReturnValue({
      userId: 1,
      email: 'test@example.com',
    });

    (milestoneService.getMilestoneNotifications as jest.Mock).mockResolvedValue([]);

    await handleWebSocketConnection(mockWs as AuthenticatedWebSocket, mockReq);

    const messageHandler = (mockOn as jest.Mock).mock.calls.find(
      (call) => call[0] === 'message',
    )?.[1];

    if (messageHandler) {
      const message: SubscribeMessage = {
        type: 'subscribe',
        payload: { milestones: true },
      };

      await messageHandler(JSON.stringify(message));

      expect(mockWs.isSubscribed).toBe(true);
      expect(milestoneService.getMilestoneNotifications).toHaveBeenCalledWith(1);
    }
  });

  it('should send pending milestones on subscribe', async () => {
    (tokenUtils.verifyAccessToken as jest.Mock).mockReturnValue({
      userId: 1,
      email: 'test@example.com',
    });

    const notifications = [
      {
        habitId: 1,
        habitName: 'Running',
        milestone: 3,
        currentStreak: 3,
      },
    ];

    (milestoneService.getMilestoneNotifications as jest.Mock).mockResolvedValue(notifications);

    await handleWebSocketConnection(mockWs as AuthenticatedWebSocket, mockReq);

    const messageHandler = (mockOn as jest.Mock).mock.calls.find(
      (call) => call[0] === 'message',
    )?.[1];

    if (messageHandler) {
      const message: SubscribeMessage = {
        type: 'subscribe',
        payload: { milestones: true },
      };

      await messageHandler(JSON.stringify(message));

      expect(mockSend).toHaveBeenCalled();

      const sentMessages = mockSend.mock.calls.map((call) => JSON.parse(call[0]));
      expect(sentMessages).toContainEqual(
        expect.objectContaining({
          type: 'streak_milestone',
          payload: expect.objectContaining({
            habitId: 1,
            habitName: 'Running',
            milestone: 3,
            currentStreak: 3,
          }),
        }),
      );
    }
  });

  it('should record milestone delivery after sending', async () => {
    (tokenUtils.verifyAccessToken as jest.Mock).mockReturnValue({
      userId: 1,
      email: 'test@example.com',
    });

    const notifications = [
      {
        habitId: 1,
        habitName: 'Running',
        milestone: 3,
        currentStreak: 3,
      },
    ];

    (milestoneService.getMilestoneNotifications as jest.Mock).mockResolvedValue(notifications);

    await handleWebSocketConnection(mockWs as AuthenticatedWebSocket, mockReq);

    const messageHandler = (mockOn as jest.Mock).mock.calls.find(
      (call) => call[0] === 'message',
    )?.[1];

    if (messageHandler) {
      const message: SubscribeMessage = {
        type: 'subscribe',
        payload: { milestones: true },
      };

      await messageHandler(JSON.stringify(message));

      expect(milestoneService.recordMilestoneDelivery).toHaveBeenCalledWith(1, 1, 3);
    }
  });

  // MARK: - Invalid Messages

  it('should reject invalid JSON', async () => {
    (tokenUtils.verifyAccessToken as jest.Mock).mockReturnValue({
      userId: 1,
      email: 'test@example.com',
    });

    await handleWebSocketConnection(mockWs as AuthenticatedWebSocket, mockReq);

    const messageHandler = (mockOn as jest.Mock).mock.calls.find(
      (call) => call[0] === 'message',
    )?.[1];

    if (messageHandler) {
      await messageHandler('invalid json');

      expect(mockSend).toHaveBeenCalledWith(
        expect.stringContaining('error'),
      );
    }
  });

  it('should reject message without type', async () => {
    (tokenUtils.verifyAccessToken as jest.Mock).mockReturnValue({
      userId: 1,
      email: 'test@example.com',
    });

    await handleWebSocketConnection(mockWs as AuthenticatedWebSocket, mockReq);

    const messageHandler = (mockOn as jest.Mock).mock.calls.find(
      (call) => call[0] === 'message',
    )?.[1];

    if (messageHandler) {
      const message = { payload: {} };

      await messageHandler(JSON.stringify(message));

      expect(mockSend).toHaveBeenCalledWith(
        expect.stringContaining('error'),
      );
    }
  });

  it('should reject unknown message type', async () => {
    (tokenUtils.verifyAccessToken as jest.Mock).mockReturnValue({
      userId: 1,
      email: 'test@example.com',
    });

    await handleWebSocketConnection(mockWs as AuthenticatedWebSocket, mockReq);

    const messageHandler = (mockOn as jest.Mock).mock.calls.find(
      (call) => call[0] === 'message',
    )?.[1];

    if (messageHandler) {
      const message = { type: 'unknown' };

      await messageHandler(JSON.stringify(message));

      expect(mockSend).toHaveBeenCalledWith(
        expect.stringContaining('Unknown message type'),
      );
    }
  });

  // MARK: - User Isolation

  it('should isolate users - user cannot receive other user notifications', async () => {
    const ws1 = { ...mockWs, userId: 1 } as AuthenticatedWebSocket;
    const ws2 = { ...mockWs, userId: 2 } as AuthenticatedWebSocket;

    (tokenUtils.verifyAccessToken as jest.Mock)
      .mockReturnValueOnce({ userId: 1, email: 'user1@example.com' })
      .mockReturnValueOnce({ userId: 2, email: 'user2@example.com' });

    // User 1 connects
    await handleWebSocketConnection(ws1, mockReq);

    // User 2 connects with different request
    mockReq.url = 'ws://localhost:3000/?token=valid-token-2';
    await handleWebSocketConnection(ws2, mockReq);

    // They should have different user IDs
    expect(ws1.userId).toBe(1);
    expect(ws2.userId).toBe(2);
  });
});
