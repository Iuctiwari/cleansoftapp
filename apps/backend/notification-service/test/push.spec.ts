import { createVerify, generateKeyPairSync } from 'node:crypto';

import { BadRequestException, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { NotificationService } from '../src/notification/notification.service';
import type { NotificationScope } from '../src/notification/notification.types';
import { FcmSender } from '../src/push/fcm.sender';
import { PushInternalController } from '../src/push/push.controllers';
import { PushService } from '../src/push/push.service';

const { publicKey, privateKey } = generateKeyPairSync('rsa', {
  modulusLength: 2048,
  publicKeyEncoding: { type: 'spki', format: 'pem' },
  privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
});
const serviceAccountJson = JSON.stringify({
  type: 'service_account',
  project_id: 'nexoraa-test',
  client_email: 'push@nexoraa-test.iam.gserviceaccount.com',
  private_key: privateKey,
  token_uri: 'https://oauth2.googleapis.com/token',
});
const TOKEN = 'd'.repeat(60);

interface FetchCall {
  readonly url: string;
  readonly init: RequestInit;
}

/** Replaces fetch: Google's token endpoint, then FCM answering as scripted. */
function fakeFetch(fcmResponses: { status: number; body?: unknown }[]) {
  const calls: FetchCall[] = [];
  const original = globalThis.fetch;
  globalThis.fetch = jest.fn((url: string | URL | Request, init?: RequestInit) => {
    calls.push({ url: String(url), init: init ?? {} });
    if (String(url).includes('oauth2.googleapis.com')) {
      return Promise.resolve(
        new Response(JSON.stringify({ access_token: 'access-1', expires_in: 3600 }), {
          status: 200,
        }),
      );
    }
    const next = fcmResponses.shift() ?? { status: 200, body: { name: 'ok' } };
    return Promise.resolve(new Response(JSON.stringify(next.body ?? {}), { status: next.status }));
  });
  return { calls, restore: () => (globalThis.fetch = original) };
}

const sender = (env: Record<string, string> = { FCM_SERVICE_ACCOUNT_JSON: serviceAccountJson }) =>
  new FcmSender(new ConfigService(env));

describe('FcmSender', () => {
  it('is switched off without a key and never calls out', async () => {
    const http = fakeFetch([]);
    const off = sender({});

    expect(off.enabled).toBe(false);
    await expect(off.send(TOKEN, { title: 't', body: 'b' })).resolves.toBe('failed');
    expect(http.calls).toHaveLength(0);
    http.restore();
  });

  it('is switched off (not crashing) when the key is unreadable', () => {
    expect(sender({ FCM_SERVICE_ACCOUNT_JSON: '{ not json' }).enabled).toBe(false);
    expect(sender({ FCM_SERVICE_ACCOUNT_FILE: 'C:/does/not/exist.json' }).enabled).toBe(false);
    expect(sender({ FCM_SERVICE_ACCOUNT_JSON: '{"project_id":"x"}' }).enabled).toBe(false);
  });

  it('signs in to Google with a valid RS256 token and sends the message', async () => {
    const http = fakeFetch([{ status: 200 }]);

    const result = await sender().send(TOKEN, {
      title: 'New online request',
      body: 'Riya · Laundry',
      data: { type: 'online_request', count: 3 as unknown as string },
    });

    expect(result).toBe('sent');
    const [login, push] = http.calls;
    const assertion = new URLSearchParams(String(login.init.body)).get('assertion')!;
    const [header, claims, signature] = assertion.split('.');
    expect(JSON.parse(Buffer.from(header, 'base64url').toString())).toEqual({
      alg: 'RS256',
      typ: 'JWT',
    });
    expect(JSON.parse(Buffer.from(claims, 'base64url').toString())).toMatchObject({
      iss: 'push@nexoraa-test.iam.gserviceaccount.com',
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
    });
    expect(
      createVerify('RSA-SHA256')
        .update(`${header}.${claims}`)
        .verify(publicKey, signature, 'base64url'),
    ).toBe(true);

    expect(push.url).toBe('https://fcm.googleapis.com/v1/projects/nexoraa-test/messages:send');
    expect((push.init.headers as Record<string, string>).authorization).toBe('Bearer access-1');
    expect(JSON.parse(String(push.init.body)).message).toEqual({
      token: TOKEN,
      notification: { title: 'New online request', body: 'Riya · Laundry' },
      data: { type: 'online_request', count: '3' }, // FCM needs string values
      android: { priority: 'HIGH', notification: { channel_id: 'nexoraa_default' } },
    });
    http.restore();
  });

  it('reuses the Google access token between messages', async () => {
    const http = fakeFetch([{ status: 200 }, { status: 200 }]);
    const fcm = sender();

    await fcm.send(TOKEN, { title: 'a', body: 'b' });
    await fcm.send(TOKEN, { title: 'a', body: 'b' });

    expect(http.calls.filter((call) => call.url.includes('oauth2'))).toHaveLength(1);
    http.restore();
  });

  it('retries once with a fresh access token after a 401', async () => {
    const http = fakeFetch([{ status: 401 }, { status: 200 }]);

    await expect(sender().send(TOKEN, { title: 'a', body: 'b' })).resolves.toBe('sent');
    expect(http.calls.filter((call) => call.url.includes('oauth2'))).toHaveLength(2);
    http.restore();
  });

  it.each([
    ['an uninstalled app', { status: 404, body: { error: { status: 'NOT_FOUND' } } }],
    [
      'an unregistered token',
      { status: 400, body: { error: { details: [{ errorCode: 'UNREGISTERED' }] } } },
    ],
    [
      'a malformed token',
      {
        status: 400,
        body: {
          error: { message: 'The registration token is not a valid FCM registration token' },
        },
      },
    ],
  ])('reports %s as a dead token', async (_name, response) => {
    const http = fakeFetch([response]);

    await expect(sender().send(TOKEN, { title: 'a', body: 'b' })).resolves.toBe('invalid_token');
    http.restore();
  });

  it('reports a temporary failure without calling the token dead', async () => {
    const http = fakeFetch([{ status: 503, body: { error: { status: 'UNAVAILABLE' } } }]);

    await expect(sender().send(TOKEN, { title: 'a', body: 'b' })).resolves.toBe('failed');
    http.restore();
  });
});

// ── PushService ─────────────────────────────────────────────────────────────

function createPush(
  options: {
    enabled?: boolean;
    devices?: { token: string }[];
    results?: Record<string, string>;
  } = {},
) {
  const found = options.devices ?? [];
  const devices = {
    replaceOne: jest.fn(() => ({ exec: () => Promise.resolve({}) })),
    find: jest.fn((..._args: unknown[]) => ({
      sort: () => ({ skip: () => ({ lean: () => ({ exec: () => Promise.resolve([]) }) }) }),
      lean: () => ({ exec: () => Promise.resolve(found) }),
    })),
    deleteOne: jest.fn(() => ({ exec: () => Promise.resolve({}) })),
    deleteMany: jest.fn(() => ({ exec: () => Promise.resolve({}) })),
  };
  const fcm = {
    enabled: options.enabled ?? true,
    send: jest.fn((token: string) => Promise.resolve(options.results?.[token] ?? 'sent')),
  };
  return { push: new PushService(devices as never, fcm as unknown as FcmSender), devices, fcm };
}

const owner: NotificationScope = {
  actorId: 'owner-1',
  authorization: 'Bearer x',
  branchId: 'b1',
  tenantId: 't1',
  roleCode: 'Owner',
  permissions: [],
};
const worker: NotificationScope = {
  actorId: 'worker-1',
  authorization: 'Bearer x',
  branchId: 'b1',
  tenantId: 't1',
  roleCode: 'Staff',
  permissions: ['orders:read'],
};
const cashier: NotificationScope = {
  actorId: 'cashier-1',
  authorization: 'Bearer x',
  branchId: 'b1',
  tenantId: 't1',
  roleCode: 'Cashier',
  permissions: ['process:payments'],
};

describe('PushService registering phones', () => {
  it('stores the phone for the signed-in account and records what they may hear about', async () => {
    const { push, devices } = createPush();

    await push.registerShopDevice(owner, { token: TOKEN, appVersion: '1.0.3' });
    await push.registerShopDevice(cashier, { token: 'e'.repeat(60) });

    const rows = (
      devices.replaceOne.mock.calls as unknown as [unknown, Record<string, unknown>][]
    ).map((call) => call[1]);
    expect(rows[0]).toMatchObject({
      kind: 'shop',
      accountId: 'owner-1',
      isOwner: true,
      seesOrders: true,
      tenantId: 't1',
      branchId: 'b1',
    });
    expect(rows[1]).toMatchObject({ accountId: 'cashier-1', isOwner: false, seesOrders: false });
  });

  it('registers a customer phone without any shop information', async () => {
    const { push, devices } = createPush();

    await push.registerConsumerDevice('consumer-1', { token: TOKEN });

    const row = (
      devices.replaceOne.mock.calls as unknown as [unknown, Record<string, unknown>][]
    )[0][1];
    expect(row).toMatchObject({ kind: 'consumer', accountId: 'consumer-1' });
    expect(row.tenantId).toBeUndefined();
  });

  it.each([undefined, 42, '', 'short', `has space ${'x'.repeat(60)}`])(
    'rejects the token %p',
    async (token) => {
      const { push } = createPush();

      await expect(push.registerShopDevice(owner, { token })).rejects.toBeInstanceOf(
        BadRequestException,
      );
    },
  );

  it('signing out removes only that account’s row for the token', async () => {
    const { push, devices } = createPush();

    await push.unregister(TOKEN, 'worker-1');

    expect(devices.deleteOne).toHaveBeenCalledWith({ token: TOKEN, accountId: 'worker-1' });
  });
});

describe('PushService sending', () => {
  it('does nothing and reports "off" when Firebase is not configured', async () => {
    const { push, devices, fcm } = createPush({ enabled: false });

    const outcome = await push.send({ kind: 'user', userId: 'w1' }, { title: 'a', body: 'b' });

    expect(outcome).toEqual({ enabled: false, devices: 0, sent: 0, removed: 0 });
    expect(devices.find).not.toHaveBeenCalled();
    expect(fcm.send).not.toHaveBeenCalled();
  });

  it('sends to every phone of the account and removes dead tokens', async () => {
    const { push, devices } = createPush({
      devices: [{ token: 'ok-1' }, { token: 'dead-1' }, { token: 'ok-2' }, { token: 'flaky' }],
      results: { 'dead-1': 'invalid_token', flaky: 'failed' },
    });

    const outcome = await push.send({ kind: 'user', userId: 'w1' }, { title: 'a', body: 'b' });

    expect(outcome).toEqual({ enabled: true, devices: 4, sent: 2, removed: 1 });
    expect(devices.deleteMany).toHaveBeenCalledWith({ token: { $in: ['dead-1'] } });
  });

  it('never throws, even if the database does', async () => {
    const { push, devices } = createPush();
    devices.find.mockImplementationOnce(() => {
      throw new Error('db down');
    });

    await expect(
      push.send({ kind: 'user', userId: 'w1' }, { title: 'a', body: 'b' }),
    ).resolves.toMatchObject({
      sent: 0,
    });
  });

  it('picks the right people for each audience', () => {
    const { push } = createPush();

    expect(push.filterFor({ kind: 'user', userId: 'w1' })).toEqual({
      kind: 'shop',
      accountId: 'w1',
    });
    expect(push.filterFor({ kind: 'consumer', consumerId: 'c1' })).toEqual({
      kind: 'consumer',
      accountId: 'c1',
    });
    expect(
      push.filterFor({ kind: 'branch', tenantId: 't1', branchId: 'b1', excludeUserId: 'u9' }),
    ).toEqual({
      kind: 'shop',
      tenantId: 't1',
      seesOrders: true,
      // owners everywhere, everyone else only in this branch, never the person who acted
      $or: [{ isOwner: true }, { branchId: 'b1' }],
      accountId: { $ne: 'u9' },
    });
  });
});

describe('internal push endpoint', () => {
  function endpoint() {
    const send = jest.fn().mockResolvedValue({ enabled: true, devices: 1, sent: 1, removed: 0 });
    const controller = new PushInternalController(
      { send } as unknown as PushService,
      new ConfigService({ INTERNAL_SERVICE_SECRET: 'shared-secret' }),
    );
    return { controller, send };
  }
  const body = {
    audience: { tenantId: 't1', branchId: 'b1' },
    title: 'New online request',
    body: 'Riya',
    data: { requestId: 'r1', n: 2, nested: { x: 1 } },
  };

  it.each([undefined, 'wrong-secret', ''])('refuses the secret %p', async (secret) => {
    const { controller, send } = endpoint();

    await expect(controller.send(secret, body)).rejects.toBeInstanceOf(UnauthorizedException);
    expect(send).not.toHaveBeenCalled();
  });

  it('refuses everything when no secret is configured', async () => {
    const controller = new PushInternalController({} as PushService, new ConfigService({}));

    await expect(controller.send('anything', body)).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('sends to a branch, keeping only plain data values', async () => {
    const { controller, send } = endpoint();

    await controller.send('shared-secret', body);

    expect(send).toHaveBeenCalledWith(
      { kind: 'branch', tenantId: 't1', branchId: 'b1', excludeUserId: undefined },
      { title: 'New online request', body: 'Riya', data: { requestId: 'r1', n: 2 } },
    );
  });

  it('accepts a customer or a single user as the audience', async () => {
    const { controller, send } = endpoint();

    await controller.send('shared-secret', { ...body, audience: { consumerId: 'c1' } });
    await controller.send('shared-secret', { ...body, audience: { userId: 'u1' } });

    expect(send.mock.calls[0][0]).toEqual({ kind: 'consumer', consumerId: 'c1' });
    expect(send.mock.calls[1][0]).toEqual({ kind: 'user', userId: 'u1' });
  });

  it.each([
    [{ ...body, audience: {} }],
    [{ ...body, audience: { tenantId: 't1' } }],
    [{ ...body, title: '' }],
    [{ ...body, body: undefined }],
  ])('rejects an incomplete request', async (input) => {
    const { controller } = endpoint();

    await expect(controller.send('shared-secret', input as never)).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });
});

// ── Worker pushes: every in-app notification also becomes a push ────────────

describe('NotificationService → push', () => {
  const created = {
    _id: { toString: () => 'n1' },
    tenantId: { toString: () => 't1' },
    branchId: 'b1',
    recipientId: { toString: () => '64f0c18f7c4d2f0012ab34aa' },
    title: 'New task assigned',
    message: 'Order ORD-1 was assigned to you',
    type: 'WorkerAssigned',
    orderId: { toString: () => '64f0c18f7c4d2f0012ab34bb' },
    isRead: false,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  function service() {
    const model = { create: jest.fn().mockResolvedValue(created) };
    const push = { send: jest.fn().mockResolvedValue({}) };
    const gateway = { emitNew: jest.fn() };
    return {
      push,
      service: new NotificationService(
        model as never,
        gateway as never,
        push as unknown as PushService,
      ),
    };
  }
  const input = {
    recipientId: '64f0c18f7c4d2f0012ab34aa',
    title: 'New task assigned',
    message: 'Order ORD-1 was assigned to you',
    type: 'WorkerAssigned',
  };
  const scope = (actorId: string): NotificationScope => ({
    ...owner,
    actorId,
    tenantId: '64f0c18f7c4d2f0012ab34cc',
    permissions: [],
  });

  it('pushes the recipient’s phones with what to open when tapped', async () => {
    const { service: subject, push } = service();

    await subject.create(scope('owner-1'), input);

    expect(push.send).toHaveBeenCalledWith(
      { kind: 'user', userId: '64f0c18f7c4d2f0012ab34aa' },
      expect.objectContaining({
        title: 'New task assigned',
        body: 'Order ORD-1 was assigned to you',
        data: expect.objectContaining({
          type: 'WorkerAssigned',
          orderId: '64f0c18f7c4d2f0012ab34bb',
        }),
      }),
    );
  });

  it('does not push people about something they did themselves', async () => {
    const { service: subject, push } = service();

    await subject.create(scope('64f0c18f7c4d2f0012ab34aa'), input);

    expect(push.send).not.toHaveBeenCalled();
  });
});

describe('owners-only audience', () => {
  it('targets only owners of that shop', () => {
    const service = Object.create(PushService.prototype) as PushService;
    expect(service.filterFor({ kind: 'owners', tenantId: 't1' })).toEqual({
      kind: 'shop',
      tenantId: 't1',
      isOwner: true,
    });
  });
});
