import { AuthTokens, JWTPayload, User } from '@types/index';

export class JWTService {
  generateAccessToken(user: User): string {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  generateRefreshToken(userId: number): string {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  generateTokens(user: User): AuthTokens {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  verifyToken(token: string): JWTPayload {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  refreshTokens(refreshToken: string): AuthTokens {
    // Implementation coming soon
    throw new Error('Not implemented');
  }
}
