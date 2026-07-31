import {
  DocumentBuilder,
  SwaggerModule,
  type OpenAPIObject,
  type SwaggerCustomOptions,
} from '@nestjs/swagger';

import {
  COMMON_SWAGGER_TAGS,
  DEFAULT_API_VERSION,
  DEFAULT_SWAGGER_PATH,
  JWT_AUTH_NAME,
} from './swagger.constants';
import type { SwaggerConfiguration } from './swagger.types';

const DEFAULT_UI_OPTIONS: SwaggerCustomOptions = {
  customSiteTitle: 'Nexoraa API Documentation',
  swaggerOptions: {
    displayRequestDuration: true,
    persistAuthorization: true,
    tryItOutEnabled: true,
  },
};

export function createSwaggerDocumentBuilder(configuration: SwaggerConfiguration): DocumentBuilder {
  const builder = new DocumentBuilder()
    .setTitle(configuration.title)
    .setDescription(configuration.description ?? `${configuration.title} OpenAPI documentation`)
    .setVersion(configuration.version ?? DEFAULT_API_VERSION)
    .addServer(configuration.serverUrl ?? '/', configuration.serverDescription ?? 'Current service')
    .addBearerAuth(
      {
        bearerFormat: 'JWT',
        description: 'Enter a valid JWT access token',
        scheme: 'bearer',
        type: 'http',
      },
      JWT_AUTH_NAME,
    )
    .addTag(COMMON_SWAGGER_TAGS.health, 'Service health and readiness endpoints');

  for (const tag of configuration.tags ?? []) {
    builder.addTag(tag.name, tag.description);
  }

  return builder;
}

export function createSwaggerDocument(
  app: unknown,
  configuration: SwaggerConfiguration,
): OpenAPIObject {
  const nestApplication = app as Parameters<typeof SwaggerModule.createDocument>[0];

  return SwaggerModule.createDocument(
    nestApplication,
    createSwaggerDocumentBuilder(configuration).build(),
    {
      deepScanRoutes: true,
    },
  );
}

export function setupSwagger(app: unknown, configuration: SwaggerConfiguration): OpenAPIObject {
  const document = createSwaggerDocument(app, configuration);
  const nestApplication = app as Parameters<typeof SwaggerModule.setup>[1];

  SwaggerModule.setup(
    configuration.documentPath ?? DEFAULT_SWAGGER_PATH,
    nestApplication,
    document,
    {
      ...DEFAULT_UI_OPTIONS,
      jsonDocumentUrl: configuration.jsonDocumentUrl,
      useGlobalPrefix: configuration.useGlobalPrefix,
    },
  );

  return document;
}
