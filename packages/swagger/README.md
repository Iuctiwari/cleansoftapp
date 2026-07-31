# @nexoraa/swagger

Central Swagger/OpenAPI setup for all NestJS backend applications.

Call `setupSwagger(app, { title: 'Service API' })` during bootstrap. The default
Swagger UI is available at `/api/docs`, with a JWT bearer authorization scheme
named `access-token`.
