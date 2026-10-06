import { mobileMatcher } from '../src/customer/customer.mongo.repository';

describe('mobileMatcher (linking online customers to shop-entered ones)', () => {
  const matcher = mobileMatcher('9876543210');

  it.each([
    '9876543210',
    '+91 98765 43210',
    '+919876543210',
    '919876543210',
    '098765-43210',
    ' 98765 43210 ',
  ])('matches %s', (stored) => {
    expect(matcher.test(stored)).toBe(true);
  });

  it.each(['9876543211', '19876543210', '98765432100', '+44 9876543210', '987654321'])(
    'does not match %s',
    (stored) => {
      expect(matcher.test(stored)).toBe(false);
    },
  );
});
