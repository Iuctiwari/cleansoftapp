db.tenantOwners.updateOne(
  {email: 'admin@nexoraa.com'},
  {$set: {passwordHash: 'scrypt$bf530e75f7571ba79e69b0a3471f2e89$ff55bc37d9bb1ce0653d125c6a56cb64672814e4f2d11c31da3c506bf5f97e2fb3d3cf929b45884b6efeb17355f4aaca95d217011fc66e03cc1306337ec25c4d'}}
)
db.tenantOwners.updateOne(
  {email: 'test@example.com'},
  {$set: {passwordHash: 'scrypt$bf530e75f7571ba79e69b0a3471f2e89$ff55bc37d9bb1ce0653d125c6a56cb64672814e4f2d11c31da3c506bf5f97e2fb3d3cf929b45884b6efeb17355f4aaca95d217011fc66e03cc1306337ec25c4d'}}
)
