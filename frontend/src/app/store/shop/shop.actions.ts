import { createAction, props } from '@ngrx/store';

export const loadShops = createAction('[Shop] Load Shops');

export const loadShopsSuccess = createAction(
  '[Shop] Load Shops Success',
  props<{ shops: any[] }>()
);

export const loadShopsFailure = createAction(
  '[Shop] Load Shops Failure',
  props<{ error: string }>()
);