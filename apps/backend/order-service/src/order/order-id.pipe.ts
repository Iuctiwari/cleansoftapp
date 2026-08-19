import { BadRequestException, Injectable, type PipeTransform } from '@nestjs/common';
import { Types } from 'mongoose';

const MONGODB_OBJECT_ID_PATTERN = /^[0-9a-fA-F]{24}$/;

@Injectable()
export class OrderIdPipe implements PipeTransform<string, string> {
  transform(value: string): string {
    if (!MONGODB_OBJECT_ID_PATTERN.test(value) || !Types.ObjectId.isValid(value)) {
      throw new BadRequestException('Order id must be a valid MongoDB ObjectId');
    }

    return value;
  }
}
