import { BadRequestException } from '@nestjs/common';

import { OrderIdPipe } from '../src/order/order-id.pipe';

describe('OrderIdPipe', () => {
  const pipe = new OrderIdPipe();

  it('accepts a valid MongoDB ObjectId', () => {
    expect(pipe.transform('64f0c18f7c4d2f0012ab34cd')).toBe('64f0c18f7c4d2f0012ab34cd');
  });

  it.each(['invalid', '123456789012', '', '64f0c18f7c4d2f0012ab34cg'])(
    'rejects invalid Order id %p',
    (value) => {
      expect(() => pipe.transform(value)).toThrow(BadRequestException);
    },
  );
});
