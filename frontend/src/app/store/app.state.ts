import { AuthState } from './auth/auth.reducer';
import { DashboardState } from './dashboard/dashboard.reducer';
import { ShopState } from './shop/shop.reducer';
import { OrderState } from './orders/order.reducer';
import { UserState } from './users/user.reducer';
import { AnalyticsState } from './analytics/analytics.reducer';
import { NotificationState } from './notifications/notification.reducer';

export interface AppState {
  auth: AuthState;
  dashboard: DashboardState;
  shop: ShopState;
  orders: OrderState;
  users: UserState;
  analytics: AnalyticsState;
  notifications: NotificationState;
}