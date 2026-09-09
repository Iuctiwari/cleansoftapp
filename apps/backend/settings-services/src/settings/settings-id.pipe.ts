import { BadRequestException, Injectable, type PipeTransform } from '@nestjs/common';
import { Types } from 'mongoose';

@Injectable()
export class SettingsIdPipe implements PipeTransform<string, string> {
  transform(value: string): string {
    if (!Types.ObjectId.isValid(value)) {
      throw new BadRequestException(`Invalid ID: ${value}`);
    }
    return value;
  }
}
