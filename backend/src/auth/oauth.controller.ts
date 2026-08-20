import { Request, Response } from 'express';

export class OAuthController {
  async googleCallback(req: Request, res: Response): Promise<void> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async githubCallback(req: Request, res: Response): Promise<void> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async refresh(req: Request, res: Response): Promise<void> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async logout(req: Request, res: Response): Promise<void> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }
}
