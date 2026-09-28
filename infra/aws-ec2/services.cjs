// Single source of truth for the AWS EC2 deployment: which backend services run,
// on which local port, and under which public subdomain (<subdomain>.<domain>).
// Read by ecosystem.config.cjs (PM2), deploy.sh (build + Caddy config) and the
// mobile-app URL printout. audit-service and scheduler-service were never
// deployed on Render either; add them here once they are needed.
const SERVICES = [
  { name: 'auth-service', port: 3001, subdomain: 'auth', mobileKey: 'AUTH', mobilePath: '/api' },
  { name: 'branch-service', port: 3002, subdomain: 'branch', mobileKey: 'BRANCH', mobilePath: '' },
  { name: 'customer-service', port: 3003, subdomain: 'customer', mobileKey: 'CUSTOMER', mobilePath: '' },
  { name: 'notification-service', port: 3005, subdomain: 'notification', mobileKey: 'NOTIFICATION', mobilePath: '/api' },
  { name: 'tenant-service', port: 3006, subdomain: 'tenant', mobileKey: 'TENANT', mobilePath: '/api/v1' },
  { name: 'order-service', port: 3007, subdomain: 'order', mobileKey: 'ORDER', mobilePath: '/api' },
  { name: 'report-service', port: 3008, subdomain: 'report', mobileKey: 'REPORT', mobilePath: '/api' },
  { name: 'expense-service', port: 3009, subdomain: 'expense', mobileKey: 'EXPENSE', mobilePath: '' },
  { name: 'payment-service', port: 3010, subdomain: 'payment', mobileKey: 'PAYMENT', mobilePath: '' },
  { name: 'service-service', port: 3012, subdomain: 'catalog', mobileKey: 'SERVICE', mobilePath: '/api' },
  { name: 'user-service', port: 3013, subdomain: 'user', mobileKey: 'USER', mobilePath: '' },
  { name: 'settings-services', port: 3014, subdomain: 'settings', mobileKey: 'SETTINGS', mobilePath: '/api' },
  { name: 'platform-admin-service', port: 3015, subdomain: 'admin', mobileKey: 'PLATFORM_ADMIN', mobilePath: '/api' },
  { name: 'search-service', port: 3016, subdomain: 'search', mobileKey: 'SEARCH', mobilePath: '' },
];

module.exports = { SERVICES };

// `node services.cjs <command> [domain]` — small CLI used by deploy.sh.
if (require.main === module) {
  const [command, domain] = process.argv.slice(2);
  if (command === 'names') {
    console.log(SERVICES.map((s) => s.name).join(' '));
  } else if (command === 'caddyfile') {
    console.log(
      SERVICES.map((s) => `${s.subdomain}.${domain} {\n\treverse_proxy 127.0.0.1:${s.port}\n}`).join('\n\n'),
    );
  } else if (command === 'mobile-env') {
    console.log(
      SERVICES.map((s) => `RENDER_${s.mobileKey}_API_BASE_URL=https://${s.subdomain}.${domain}${s.mobilePath}`).join('\n'),
    );
  } else {
    console.error('usage: node services.cjs names | caddyfile <domain> | mobile-env <domain>');
    process.exit(1);
  }
}
