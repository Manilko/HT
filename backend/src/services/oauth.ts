//
//  oauth.ts
//  OAuth Provider Services
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import { logger } from '../config/logger';

export interface OAuthUserInfo {
  provider_user_id: string;
  email: string | null;
  display_name: string;
  avatar_url: string | null;
}

export interface OAuthProvider {
  exchangeCodeForTokens(code: string): Promise<string>;
  fetchUserInfo(accessToken: string): Promise<OAuthUserInfo>;
}

export class GoogleOAuthService implements OAuthProvider {
  constructor(private clientId: string, private clientSecret: string, private redirectUri: string) {}

  async exchangeCodeForTokens(code: string): Promise<string> {
    // In production, make real HTTPS POST request to:
    // https://oauth2.googleapis.com/token
    // with: code, client_id, client_secret, grant_type, redirect_uri
    // Return access_token from response

    // For now, mock implementation for testing
    logger.debug('Google OAuth: exchanging code for tokens');
    return `google_access_token_${code}`;
  }

  async fetchUserInfo(accessToken: string): Promise<OAuthUserInfo> {
    // In production, make real HTTPS GET request to:
    // https://www.googleapis.com/oauth2/v2/userinfo
    // with Authorization header: Bearer {accessToken}
    // Return user info from response

    // For now, mock implementation for testing
    logger.debug('Google OAuth: fetching user info');
    return {
      provider_user_id: 'google_user_123',
      email: 'user@example.com',
      display_name: 'Test User',
      avatar_url: 'https://lh3.googleusercontent.com/a/default-user',
    };
  }
}

export class GitHubOAuthService implements OAuthProvider {
  constructor(private clientId: string, private clientSecret: string, private redirectUri: string) {}

  async exchangeCodeForTokens(code: string): Promise<string> {
    // In production, make real HTTPS POST request to:
    // https://github.com/login/oauth/access_token
    // with: code, client_id, client_secret
    // Return access_token from response

    // For now, mock implementation for testing
    logger.debug('GitHub OAuth: exchanging code for tokens');
    return `github_access_token_${code}`;
  }

  async fetchUserInfo(accessToken: string): Promise<OAuthUserInfo> {
    // In production, make real HTTPS GET requests to:
    // https://api.github.com/user (for basic info)
    // https://api.github.com/user/emails (for email)
    // with Authorization header: Bearer {accessToken}

    // For now, mock implementation for testing
    logger.debug('GitHub OAuth: fetching user info');
    return {
      provider_user_id: 'github_user_456',
      email: null, // GitHub doesn't always provide email
      display_name: 'GitHub User',
      avatar_url: 'https://avatars.githubusercontent.com/u/1?v=4',
    };
  }
}

export class MockOAuthService implements OAuthProvider {
  constructor(private provider: 'google' | 'github') {}

  async exchangeCodeForTokens(code: string): Promise<string> {
    logger.debug(`Mock OAuth (${this.provider}): exchanging code for tokens`);
    if (code === 'invalid_code') {
      throw new Error('Invalid authorization code');
    }
    return `mock_${this.provider}_access_token_${code}`;
  }

  async fetchUserInfo(accessToken: string): Promise<OAuthUserInfo> {
    logger.debug(`Mock OAuth (${this.provider}): fetching user info`);
    if (accessToken === 'invalid_token') {
      throw new Error('Invalid access token');
    }

    if (this.provider === 'google') {
      return {
        provider_user_id: 'google_test_user_123',
        email: 'google@test.example.com',
        display_name: 'Google Test User',
        avatar_url: 'https://lh3.googleusercontent.com/a/test',
      };
    }

    return {
      provider_user_id: 'github_test_user_456',
      email: null,
      display_name: 'GitHub Test User',
      avatar_url: 'https://avatars.githubusercontent.com/u/test',
    };
  }
}
