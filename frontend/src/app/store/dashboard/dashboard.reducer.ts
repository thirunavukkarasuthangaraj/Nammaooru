import { createReducer, on } from '@ngrx/store';
import * as DashboardActions from './dashboard.actions';

export interface DashboardState {
  metrics: DashboardActions.DashboardMetrics | null;
  geographicData: any[] | null;
  revenueAnalytics: any | null;
  loading: boolean;
  error: string | null;
  lastUpdated: Date | null;
}

export const initialState: DashboardState = {
  metrics: null,
  geographicData: null,
  revenueAnalytics: null,
  loading: false,
  error: null,
  lastUpdated: null
};

export const dashboardReducer = createReducer(
  initialState,
  on(DashboardActions.loadDashboardMetrics, state => ({
    ...state,
    loading: true,
    error: null
  })),
  on(DashboardActions.loadDashboardMetricsSuccess, (state, { metrics }) => ({
    ...state,
    metrics,
    loading: false,
    error: null,
    lastUpdated: new Date()
  })),
  on(DashboardActions.loadDashboardMetricsFailure, (state, { error }) => ({
    ...state,
    loading: false,
    error
  })),
  on(DashboardActions.updateLiveMetrics, (state, { metrics }) => ({
    ...state,
    metrics: state.metrics ? { ...state.metrics, ...metrics } : null
  })),
  on(DashboardActions.loadGeographicDataSuccess, (state, { data }) => ({
    ...state,
    geographicData: data
  })),
  on(DashboardActions.loadRevenueAnalyticsSuccess, (state, { revenue }) => ({
    ...state,
    revenueAnalytics: revenue
  }))
);