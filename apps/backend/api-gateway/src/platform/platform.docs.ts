import { Controller, Get, Redirect } from '@nestjs/common';
import { ApiExcludeController } from '@nestjs/swagger';

/**
 * Legacy redirect — forwards any request to the old /api/v1/docs/openapi.json
 * path to the live Swagger UI served by @nestjs/swagger at /api/docs.
 *
 * The authoritative OpenAPI specification is now generated automatically by
 * SwaggerModule in main.ts and served at /api/docs.
 */
@ApiExcludeController()
@Controller({ path: 'docs', version: '1' })
export class PlatformDocsController {
  @Get()
  @Redirect('/api/docs', 301)
  redirectToDocs(): void {
    // Redirected to /api/docs by the @Redirect decorator.
  }

  @Get('openapi.json')
  @Redirect('/api/docs-json', 301)
  redirectToOpenApiJson(): void {
    // Redirected to /api/docs-json (raw JSON) by the @Redirect decorator.
  }
}
