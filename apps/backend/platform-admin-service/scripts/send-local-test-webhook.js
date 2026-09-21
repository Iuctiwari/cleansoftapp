/**
 * ONE-OFF LOCAL SCRIPT — not committed. Builds a real payment.captured or
 * payment.failed Razorpay webhook body, signs it with the local
 * RAZORPAY_WEBHOOK_SECRET (HMAC-SHA256, exactly what BillingWebhookService
 * computes), and POSTs it to the running service.
 * Usage: node scripts/send-local-test-webhook.js <captured|failed> <orderId> <eventId>
 */
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const http = require('node:http');

const envPath = path.join(__dirname, '..', '.env');
for (const line of fs.readFileSync(envPath, 'utf8').split('\n')) {
  const match = /^([A-Z0-9_]+)=(.*)$/.exec(line.trim());
  if (match && !(match[1] in process.env)) process.env[match[1]] = match[2];
}

const KIND = process.argv[2] || 'captured';
const ORDER_ID = process.argv[3] || 'order_LIVEtest0000001';
const EVENT_ID = process.argv[4] || `evt_live_${Date.now()}`;
const SECRET = process.env.RAZORPAY_WEBHOOK_SECRET;
const BAD_SIGNATURE = process.argv[5] === 'bad-signature';

const body =
  KIND === 'captured'
    ? {
        entity: 'event',
        account_id: 'acc_BFQ7uQEaa7j2z7',
        event: 'payment.captured',
        contains: ['payment'],
        created_at: Math.floor(Date.now() / 1000),
        payload: {
          payment: {
            entity: {
              id: 'pay_LIVEtest0000001',
              entity: 'payment',
              amount: 99900,
              currency: 'INR',
              status: 'captured',
              order_id: ORDER_ID,
              method: 'netbanking',
              captured: true,
              error_code: null,
              error_description: null,
              created_at: Math.floor(Date.now() / 1000),
            },
          },
        },
      }
    : {
        entity: 'event',
        account_id: 'acc_BFQ7uQEaa7j2z7',
        event: 'payment.failed',
        contains: ['payment'],
        created_at: Math.floor(Date.now() / 1000),
        payload: {
          payment: {
            entity: {
              id: 'pay_LIVEtest0000002',
              entity: 'payment',
              amount: 99900,
              currency: 'INR',
              status: 'failed',
              order_id: ORDER_ID,
              method: 'netbanking',
              captured: false,
              error_code: 'BAD_REQUEST_ERROR',
              error_description: 'Card declined by issuer',
              error_reason: 'payment_failed',
              created_at: Math.floor(Date.now() / 1000),
            },
          },
        },
      };

const rawBody = Buffer.from(JSON.stringify(body));
const signature = BAD_SIGNATURE
  ? 'deadbeef'.repeat(8)
  : crypto.createHmac('sha256', SECRET).update(rawBody).digest('hex');

const request = http.request(
  {
    hostname: 'localhost',
    port: 3015,
    path: '/api/v1/platform-admin/billing/webhooks/razorpay',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': rawBody.length,
      'x-razorpay-signature': signature,
      'x-razorpay-event-id': EVENT_ID,
    },
  },
  (response) => {
    let responseBody = '';
    response.on('data', (chunk) => (responseBody += chunk));
    response.on('end', () => {
      console.log(`HTTP_STATUS:${response.statusCode}`);
      console.log(responseBody);
    });
  },
);
request.write(rawBody);
request.end();
