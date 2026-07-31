import type { SwaggerCustomOptions } from '@nestjs/swagger';

export interface SwaggerTag {
  description: string;
  name: string;
}

export interface SwaggerConfiguration {
  description?: string;
  documentPath?: string;
  jsonDocumentUrl?: string;
  serverDescription?: string;
  serverUrl?: string;
  tags?: readonly SwaggerTag[];
  title: string;
  useGlobalPrefix?: boolean;
  version?: string;
}

export type SwaggerUiOptions = SwaggerCustomOptions;
