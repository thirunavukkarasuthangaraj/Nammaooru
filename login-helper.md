# Login Credentials for Testing

## Super Admin Account
- Username: `superadmin`
- Password: `password123`

## Alternative Login with Mock Token
If backend authentication is not working, you can manually set the authentication in browser console:

```javascript
// Run this in browser console (F12) to set mock authentication
localStorage.setItem('shop_management_token', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJzdXBlcmFkbWluIiwiZW1haWwiOiJhZG1pbkBzaG9wLmNvbSIsInJvbGUiOiJTVVBFUl9BRE1JTiIsImV4cCI6OTk5OTk5OTk5OX0.fake-token');
localStorage.setItem('shop_management_user', JSON.stringify({
  id: 1,
  username: 'superadmin',
  email: 'admin@shop.com',
  role: 'SUPER_ADMIN',
  isActive: true,
  createdAt: new Date(),
  updatedAt: new Date()
}));
location.reload();
```

## Backend API Endpoints

### Working Endpoints:
- `/api/shops` - List all shops
- `/api/auth/login` - Authentication
- `/api/orders` - Orders management
- `/api/users` - User management
- `/api/products` - Product management
- `/api/dashboard/metrics` - Dashboard analytics

### Test API Directly:
```bash
# Test shops API
curl http://localhost:8082/api/shops

# Test with authentication
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:8082/api/orders
```