import { createAction, props } from '@ngrx/store';

export const loadOrders = createAction('[Order] Load Orders');

export const loadOrdersSuccess = createAction(
  '[Order] Load Orders Success',
  props<{ orders: any[] }>()
);

export const loadOrdersFailure = createAction(
  '[Order] Load Orders Failure',
  props<{ error: string }>()
);