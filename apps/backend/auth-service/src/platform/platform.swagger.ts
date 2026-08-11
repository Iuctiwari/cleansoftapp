import { applyDecorators, type Type } from '@nestjs/common';
import {
  ApiCreatedResponse,
  ApiExtraModels,
  ApiOkResponse,
  ApiProperty,
  ApiPropertyOptional,
  getSchemaPath,
} from '@nestjs/swagger';

export class ApiSuccessMetaDto {
  @ApiProperty({
    example: 'b9a1d970-9868-4a1f-b4f2-4f48091d1984',
    description: 'Correlation identifier returned with every successful response.',
  })
  correlationId!: string;

  @ApiPropertyOptional({ example: 1, description: 'Current page number for paginated responses.' })
  page?: number;

  @ApiPropertyOptional({
    example: 20,
    description: 'Page size used to produce a paginated response.',
  })
  pageSize?: number;

  @ApiPropertyOptional({ example: 128, description: 'Total matching records for paginated data.' })
  total?: number;
}

export class ApiEnvelopeBaseDto {
  @ApiProperty({ type: ApiSuccessMetaDto })
  meta!: ApiSuccessMetaDto;
}

type EnvelopeOptions = {
  description?: string;
  isArray?: boolean;
  nullable?: boolean;
  status?: 'ok' | 'created';
};

function createEnvelopeSchema(model: Type<unknown>, options: EnvelopeOptions = {}): object {
  const dataSchema = options.isArray
    ? {
        type: 'array',
        items: { $ref: getSchemaPath(model) },
      }
    : options.nullable
      ? {
          anyOf: [{ $ref: getSchemaPath(model) }, { type: 'null' }],
        }
      : { $ref: getSchemaPath(model) };

  return {
    allOf: [
      { $ref: getSchemaPath(ApiEnvelopeBaseDto) },
      {
        type: 'object',
        properties: {
          data: dataSchema,
        },
        required: ['data', 'meta'],
      },
    ],
  };
}

export function ApiEnvelopeResponse(
  model: Type<unknown>,
  options: EnvelopeOptions = {},
): ReturnType<typeof applyDecorators> {
  const responseDecorator = options.status === 'created' ? ApiCreatedResponse : ApiOkResponse;

  return applyDecorators(
    ApiExtraModels(ApiEnvelopeBaseDto, ApiSuccessMetaDto, model),
    responseDecorator({
      description: options.description,
      schema: createEnvelopeSchema(model, options),
    }),
  );
}
