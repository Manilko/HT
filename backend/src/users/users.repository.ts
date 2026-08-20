import { User } from '@types/index';

export class UsersRepository {
  async findById(userId: number): Promise<User | null> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async findByEmail(email: string): Promise<User | null> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async findByOAuthId(oauthId: string, oauthProvider: string): Promise<User | null> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async create(user: Partial<User>): Promise<User> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async update(userId: number, data: Partial<User>): Promise<User> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async delete(userId: number): Promise<void> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }
}
