import { createAction, props } from '@ngrx/store';

export interface DashboardMetrics {
  totalRevenue: number;
  totalOrders: number;
  totalCustomers: number;
  totalShops: number;
  averageOrderValue: number;
  conversionRate: number;
  monthlyGrowth: number;
  revenueData: any[];
  orderData: any[];
  categoryData: any[];
  topShops: any[];
  activeDeliveries: number;
  pendingApprovals: number;
  systemHealth: {
    cpu: number;
    memory: number;
    activeUsers: number;
    responseTime: number;
  };
}

export const loadDashboardMetrics = createAction(
  '[Dashboard] Load Metrics',
  props<{ role: string; period: string }>()
);

export const loadDashboardMetricsSuccess = createAction(
  '[Dashboard] Load Metrics Success',
  props<{ metrics: DashboardMetrics }>()
);

export const loadDashboardMetricsFailure = createAction(
  '[Dashboard] Load Metrics Failure',
  props<{ error: string }>()
);

export const refreshDashboard = createAction('[Dashboard] Refresh');

export const updateLiveMetrics = createAction(
  '[Dashboard] Update Live Metrics',
  props<{ metrics: Partial<DashboardMetrics> }>()
);

export const loadGeographicData = createAction(
  '[Dashboard] Load Geographic Data'
);

export const loadGeographicDataSuccess = createAction(
  '[Dashboard] Load Geographic Data Success',
  props<{ data: any[] }>()
);

export const loadRevenueAnalytics = createAction(
  '[Dashboard] Load Revenue Analytics',
  props<{ startDate: Date; endDate: Date }>()
);

export const loadRevenueAnalyticsSuccess = createAction(
  '[Dashboard] Load Revenue Analytics Success',
  props<{ revenue: any }>()
);