import { Controller, Get } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Controller({ path: 'docs', version: '1' })
export class PlatformDocsController {
  constructor(private readonly configService: ConfigService) {}

  @Get('openapi.json')
  getOpenApiDocument(): Record<string, unknown> {
    const prefix = this.configService.getOrThrow<string>('API_PREFIX');
    const version = this.configService.getOrThrow<string>('API_VERSION');

    return {
      openapi: '3.1.0',
      info: {
        title: 'Nexoraa CleanSoft Gateway',
        version,
      },
      servers: [{ url: `/${prefix}/${version}` }],
      components: {
        securitySchemes: {
          bearerAuth: {
            type: 'http',
            scheme: 'bearer',
            bearerFormat: 'JWT',
          },
        },
      },
      paths: {
        '/health/live': {
          get: {
            summary: 'Gateway liveness probe',
          },
        },
        '/health/ready': {
          get: {
            summary: 'Gateway readiness probe',
          },
        },
        '/audit': {
          get: {
            summary: 'Query immutable audit evidence',
          },
        },
        '/audit/{auditId}': {
          get: {
            summary: 'Retrieve one immutable audit record',
          },
        },
        '/audit/exports': {
          post: {
            summary: 'Request an audit export intent',
          },
        },
        '/auth/login': {
          post: {
            summary: 'Authenticate a platform or tenant user',
          },
        },
        '/auth/refresh': {
          post: {
            summary: 'Rotate refresh credentials and issue a new access token',
          },
        },
        '/auth/logout': {
          post: {
            summary: 'Revoke the current authenticated session',
          },
        },
        '/auth/logout-all': {
          post: {
            summary: 'Revoke every active session for the authenticated user',
          },
        },
        '/auth/forgot-password': {
          post: {
            summary: 'Request a password reset proof',
          },
        },
        '/auth/reset-password': {
          post: {
            summary: 'Validate the reset proof and replace the password',
          },
        },
        '/auth/change-password': {
          post: {
            summary: 'Change the password for the authenticated user',
          },
        },
      },
    };
  }
}
