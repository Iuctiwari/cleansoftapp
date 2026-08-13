interface Envelope<T> {
  readonly data: T;
}

interface LoginData {
  readonly accessToken: string;
  readonly branch?: { readonly branchId: string };
}

const authUrl = process.env.CUSTOMER_E2E_AUTH_URL;
const customerUrl = process.env.CUSTOMER_E2E_CUSTOMER_URL;
const identifier = process.env.CUSTOMER_E2E_IDENTIFIER;
const password = process.env.CUSTOMER_E2E_PASSWORD;
const branchId = process.env.CUSTOMER_E2E_BRANCH_ID;
const runE2e = Boolean(authUrl && customerUrl && identifier && password && branchId);

describe('Customer authentication and MongoDB integration', () => {
  (runE2e ? it : it.skip)(
    'covers login, bearer authentication, selected branch scope, persistence, and soft delete',
    async () => {
      const loginResponse = await fetch(`${authUrl}/v1/auth/login`, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ context: 'tenant', identifier, password }),
      });
      expect(loginResponse.status).toBe(200);
      const login = (await loginResponse.json()) as Envelope<LoginData>;
      const headers = {
        authorization: `Bearer ${login.data.accessToken}`,
        'content-type': 'application/json',
        'x-branch-id': branchId!,
      };

      const unauthenticated = await fetch(`${customerUrl}/customers`);
      expect(unauthenticated.status).toBe(401);

      const createResponse = await fetch(`${customerUrl}/customers`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          name: `E2E Customer ${Date.now()}`,
          mobile: `+91${Date.now().toString().slice(-10)}`,
          customerType: 'Regular',
        }),
      });
      expect(createResponse.status).toBe(201);
      const created = (await createResponse.json()) as {
        readonly id: string;
        readonly branchId: string;
      };
      expect(created.branchId).toBe(branchId);

      const details = await fetch(`${customerUrl}/customers/${created.id}`, { headers });
      expect(details.status).toBe(200);

      const forbiddenBranch = await fetch(`${customerUrl}/customers/${created.id}`, {
        headers: { ...headers, 'x-branch-id': 'unassigned-branch' },
      });
      expect(forbiddenBranch.status).toBe(403);

      const deletion = await fetch(`${customerUrl}/customers/${created.id}`, {
        method: 'DELETE',
        headers,
      });
      expect(deletion.status).toBe(204);
      expect((await fetch(`${customerUrl}/customers/${created.id}`, { headers })).status).toBe(404);
    },
    30_000,
  );
});
