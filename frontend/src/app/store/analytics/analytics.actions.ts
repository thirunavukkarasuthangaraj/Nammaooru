import { createAction, props } from '@ngrx/store';

export const loadMetrics = createAction('[Analytics] Load Metrics');

export const loadMetricsSuccess = createAction(
  '[Analytics] Load Metrics Success',
  props<{ metrics: any[] }>()
);

export const loadMetricsFailure = createAction(
  '[Analytics] Load Metrics Failure',
  props<{ error: string }>()
);