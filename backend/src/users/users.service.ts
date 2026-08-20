import { User } from '@types/index';

export class UsersService {
  async getUserById(userId: number): Promise<User> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async getUserByEmail(email: string): Promise<User | null> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async createUser(data: Partial<User>): Promise<User> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async updateUser(userId: number, data: Partial<User>): Promise<User> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async deleteUser(userId: number): Promise<void> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }
}
