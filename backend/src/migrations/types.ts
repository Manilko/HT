//
//  types.ts
//  Migration System Types
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import { QueryResult } from 'pg';

export interface Migration {
  up(): Promise<void>;
  down(): Promise<void>;
}

export interface MigrationRecord {
  id: string;
  name: string;
  executed_at: Date;
}
