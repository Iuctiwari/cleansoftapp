const { randomBytes, scryptSync } = require('crypto');

function hashPassword(password) {
  const salt = randomBytes(16).toString('hex');
  const hash = scryptSync(password, salt, 64).toString('hex');
  return `scrypt$${salt}$${hash}`;
}

const hash = hashPassword('Admin123!');
console.log(hash);
