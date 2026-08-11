import { validateAuthEnvironment } from '../src/auth/auth.config';

const validEnvironment = {
  APP_NAME: 'Nexoraa CleanSoft',
  NODE_ENV: 'test',
  HOST: '127.0.0.1',
  PORT: '3000',
  API_PREFIX: 'api',
  API_VERSION: 'v1',
  MONGODB_URI: 'mongodb://localhost:27017/nexoraa_test',
  AUTH_ACCESS_TOKEN_SECRET: 'access-secret-that-is-longer-than-thirty-two-characters',
  AUTH_REFRESH_TOKEN_SECRET: 'refresh-secret-that-is-different-and-long-enough',
  AUTH_ACCESS_TOKEN_TTL_SECONDS: '900',
  AUTH_REFRESH_TOKEN_TTL_SECONDS: '604800',
  AUTH_LOGIN_MAX_ATTEMPTS: '5',
  AUTH_LOCKOUT_SECONDS: '900',
  AUTH_OTP_TTL_SECONDS: '600',
  AUTH_OTP_MAX_ATTEMPTS: '5',
  AUTH_MAX_ACTIVE_SESSIONS: '3',
  AUTH_ALLOW_MULTI_DEVICE: 'true',
};

describe('validateAuthEnvironment', () => {
  it('accepts a complete secure configuration', () => {
    expect(validateAuthEnvironment(validEnvironment)).toMatchObject({
      API_PREFIX: 'api',
      API_VERSION: 'v1',
      PORT: 3000,
    });
  });

  it('rejects missing token secrets instead of applying a fallback', () => {
    const environment: Record<string, unknown> = { ...validEnvironment };
    delete environment.AUTH_ACCESS_TOKEN_SECRET;

    expect(() => validateAuthEnvironment(environment)).toThrow(
      'Environment variable AUTH_ACCESS_TOKEN_SECRET is required',
    );
  });

  it('rejects identical access and refresh secrets', () => {
    expect(() =>
      validateAuthEnvironment({
        ...validEnvironment,
        AUTH_REFRESH_TOKEN_SECRET: validEnvironment.AUTH_ACCESS_TOKEN_SECRET,
      }),
    ).toThrow('Access-token and refresh-token secrets must be different');
  });
});
