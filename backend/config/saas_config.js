module.exports = {
  // Mode: 'SAAS' (One DB, Many Companies) or 'ON_PREMISE' (Dedicated DB for one Company)
  DEPLOYMENT_MODE: process.env.DEPLOYMENT_MODE || 'SAAS',
  
  // Default Company Settings (Moved to ENV for security)
  DEFAULT_COMPANY_ID: process.env.DEFAULT_COMPANY_ID || 9901, 
  DEFAULT_COMPANY_NAME: process.env.DEFAULT_COMPANY_NAME || 'ZenHR Core',
  
  // Security
  RESTRICT_EMAILS_TO_DOMAIN: process.env.RESTRICT_EMAILS_TO_DOMAIN === 'true',
  ALLOWED_DOMAIN: process.env.ALLOWED_DOMAIN || '', 
  
  // Multi-tenancy Config
  TENANT_COLUMN_NAME: 'CompanyID', // Use UUIDs in production for unguessable IDs
  
  // Feature Toggles
  ENABLE_SUBSCRIPTIONS: process.env.ENABLE_SUBSCRIPTIONS !== 'false',
};
