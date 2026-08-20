//
//  auth.ts
//  Authentication Routes
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import { Router, Request, Response } from 'express';
import { config } from '../config/env';
import { logger } from '../config/logger';
import { AppError, asyncHandler, ApiResponse } from '../middleware/errorHandler';
import { generateAccessToken, generateRefreshToken, verifyToken } from '../utils/tokenUtils';
import { findOrCreateUser, getUserById } from '../repositories/userRepository';
import { GoogleOAuthService, GitHubOAuthService, MockOAuthService } from '../services/oauth';

const router = Router();

interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  user: {
    id: number;
    email: string | null;
    displayName: string;
    avatarUrl: string | null;
  };
}

// Initialize OAuth services
const googleOAuthService =
  config.server.nodeEnv === 'test'
    ? new MockOAuthService('google')
    : new GoogleOAuthService(config.oauth.google.clientId, config.oauth.google.clientSecret, config.oauth.google.redirectUri);

const githubOAuthService =
  config.server.nodeEnv === 'test'
    ? new MockOAuthService('github')
    : new GitHubOAuthService(config.oauth.github.clientId, config.oauth.github.clientSecret, config.oauth.github.redirectUri);

// POST /v1/auth/google/callback
// Exchange Google authorization code for tokens
router.post(
  '/google/callback',
  asyncHandler(async (req: Request, res: Response) => {
    const { code } = req.body;

    if (!code) {
      throw new AppError('INVALID_REQUEST', 400, 'Authorization code is required');
    }

    logger.info('Google OAuth: exchanging code for tokens');

    // Exchange code for Google access token
    const googleAccessToken = await googleOAuthService.exchangeCodeForTokens(code);

    // Fetch user info from Google
    const userInfo = await googleOAuthService.fetchUserInfo(googleAccessToken);

    // Create or find user in database
    const user = await findOrCreateUser({
      provider: 'google',
      provider_user_id: userInfo.provider_user_id,
      email: userInfo.email,
      display_name: userInfo.display_name,
      avatar_url: userInfo.avatar_url,
    });

    // Generate app tokens
    const accessToken = generateAccessToken(user.id, user.email || '', 'google', user.provider_user_id);
    const refreshToken = generateRefreshToken(user.id);

    logger.info(`User authenticated: ${user.id}`);

    const response: ApiResponse<AuthResponse> = {
      success: true,
      data: {
        accessToken,
        refreshToken,
        user: {
          id: user.id,
          email: user.email,
          displayName: user.display_name,
          avatarUrl: user.avatar_url,
        },
      },
      timestamp: new Date().toISOString(),
    };

    res.status(200).json(response);
  }),
);

// POST /v1/auth/github/callback
// Exchange GitHub authorization code for tokens
router.post(
  '/github/callback',
  asyncHandler(async (req: Request, res: Response) => {
    const { code } = req.body;

    if (!code) {
      throw new AppError('INVALID_REQUEST', 400, 'Authorization code is required');
    }

    logger.info('GitHub OAuth: exchanging code for tokens');

    // Exchange code for GitHub access token
    const githubAccessToken = await githubOAuthService.exchangeCodeForTokens(code);

    // Fetch user info from GitHub
    const userInfo = await githubOAuthService.fetchUserInfo(githubAccessToken);

    // Create or find user in database
    const user = await findOrCreateUser({
      provider: 'github',
      provider_user_id: userInfo.provider_user_id,
      email: userInfo.email,
      display_name: userInfo.display_name,
      avatar_url: userInfo.avatar_url,
    });

    // Generate app tokens
    const accessToken = generateAccessToken(user.id, user.email || '', 'github', user.provider_user_id);
    const refreshToken = generateRefreshToken(user.id);

    logger.info(`User authenticated: ${user.id}`);

    const response: ApiResponse<AuthResponse> = {
      success: true,
      data: {
        accessToken,
        refreshToken,
        user: {
          id: user.id,
          email: user.email,
          displayName: user.display_name,
          avatarUrl: user.avatar_url,
        },
      },
      timestamp: new Date().toISOString(),
    };

    res.status(200).json(response);
  }),
);

// POST /v1/auth/refresh
// Validate refresh token and return new access token
router.post(
  '/refresh',
  asyncHandler(async (req: Request, res: Response) => {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      throw new AppError('INVALID_REQUEST', 400, 'Refresh token is required');
    }

    logger.info('Refreshing access token');

    // Verify refresh token
    const payload = verifyToken(refreshToken);

    // Get user from database
    const user = await getUserById(payload.sub);
    if (!user) {
      throw new AppError('USER_NOT_FOUND', 404, 'User not found');
    }

    // Generate new access token
    const newAccessToken = generateAccessToken(user.id, user.email || '', payload.oauthProvider, payload.oauthId);

    const response: ApiResponse<{ accessToken: string }> = {
      success: true,
      data: {
        accessToken: newAccessToken,
      },
      timestamp: new Date().toISOString(),
    };

    res.status(200).json(response);
  }),
);

// POST /v1/auth/logout
// Logout and invalidate session
router.post(
  '/logout',
  asyncHandler(async (req: Request, res: Response) => {
    logger.info('User logged out');

    // Future: Add token to blacklist table
    // For now, client just discards token

    const response: ApiResponse = {
      success: true,
      timestamp: new Date().toISOString(),
    };

    res.status(200).json(response);
  }),
);

export function createAuthRouter() {
  return router;
}
