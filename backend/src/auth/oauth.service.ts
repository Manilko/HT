import { AuthTokens, User } from '@types/index';

export class OAuthService {
  async exchangeGoogleCode(code: string, state: string): Promise<User & AuthTokens> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async exchangeGithubCode(code: string, state: string): Promise<User & AuthTokens> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async verifyGoogleIdToken(idToken: string): Promise<any> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async verifyGithubToken(accessToken: string): Promise<any> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }
}
