import { createReducer, on } from '@ngrx/store';
import * as AnalyticsActions from './analytics.actions';

export interface AnalyticsState {
  metrics: any[];
  reports: any[];
  loading: boolean;
  error: string | null;
}

export const initialState: AnalyticsState = {
  metrics: [],
  reports: [],
  loading: false,
  error: null
};

export const analyticsReducer = createReducer(
  initialState,
  on(AnalyticsActions.loadMetrics, state => ({
    ...state,
    loading: true,
    error: null
  })),
  on(AnalyticsActions.loadMetricsSuccess, (state, { metrics }) => ({
    ...state,
    metrics,
    loading: false,
    error: null
  })),
  on(AnalyticsActions.loadMetricsFailure, (state, { error }) => ({
    ...state,
    loading: false,
    error
  }))
);