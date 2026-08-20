//
//  tokenUtils.ts
//  Habit Tracker Backend
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import jwt from 'jsonwebtoken';
import { config } from '../config/env';

export interface JWTPayload {
  sub: number;
  email: string;
  oauthProvider: 'google' | 'github';
  oauthId: string;
  iat: number;
  exp: number;
  aud: string;
}

export function verifyToken(token: string): JWTPayload {
  try {
    const payload = jwt.verify(token, config.jwt.secret, {
      audience: 'ios-app',
    }) as JWTPayload;
    return payload;
  } catch (error) {
    throw new Error('Invalid or expired token');
  }
}

export function generateAccessToken(userId: number, email: string, oauthProvider: 'google' | 'github', oauthId: string): string {
  return jwt.sign(
    {
      sub: userId,
      email,
      oauthProvider,
      oauthId,
      aud: 'ios-app',
    },
    config.jwt.secret,
    { expiresIn: config.jwt.accessTokenExpiry },
  );
}

export function generateRefreshToken(userId: number): string {
  return jwt.sign(
    {
      sub: userId,
      type: 'refresh',
      aud: 'ios-app',
    },
    config.jwt.secret,
    { expiresIn: config.jwt.refreshTokenExpiry },
  );
}
