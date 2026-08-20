import dotenv from 'dotenv';

dotenv.config();

export const config = {
  server: {
    nodeEnv: process.env.NODE_ENV || 'development',
    port: parseInt(process.env.PORT || '3000', 10),
    logLevel: process.env.LOG_LEVEL || 'info',
  },
  database: {
    url: process.env.DATABASE_URL || '',
  },
  jwt: {
    secret: process.env.JWT_SECRET || 'change-me-in-production',
    accessTokenExpiry: parseInt(process.env.JWT_ACCESS_TOKEN_EXPIRY || '900', 10),
    refreshTokenExpiry: parseInt(process.env.JWT_REFRESH_TOKEN_EXPIRY || '604800', 10),
  },
  oauth: {
    google: {
      clientId: process.env.GOOGLE_CLIENT_ID || '',
      clientSecret: process.env.GOOGLE_CLIENT_SECRET || '',
      redirectUri: process.env.GOOGLE_REDIRECT_URI || '',
    },
    github: {
      clientId: process.env.GITHUB_CLIENT_ID || '',
      clientSecret: process.env.GITHUB_CLIENT_SECRET || '',
      redirectUri: process.env.GITHUB_REDIRECT_URI || '',
    },
  },
  websocket: {
    url: process.env.WS_URL || 'ws://localhost:3000',
  },
  cors: {
    origin: process.env.CORS_ORIGIN?.split(',') || ['http://localhost:3000'],
  },
};

export function validateConfig(): void {
  if (!config.database.url) {
    throw new Error('DATABASE_URL environment variable is required');
  }

  if (!config.jwt.secret || config.jwt.secret === 'change-me-in-production') {
    if (config.server.nodeEnv === 'production') {
      throw new Error('JWT_SECRET must be set in production');
    }
  }

  if (config.server.nodeEnv !== 'test') {
    if (!config.oauth.google.clientId || !config.oauth.google.clientSecret) {
      console.warn('Google OAuth not configured');
    }

    if (!config.oauth.github.clientId || !config.oauth.github.clientSecret) {
      console.warn('GitHub OAuth not configured');
    }
  }
}
