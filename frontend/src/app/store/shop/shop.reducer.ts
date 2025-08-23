import { createReducer, on } from '@ngrx/store';
import * as ShopActions from './shop.actions';

export interface ShopState {
  shops: any[];
  currentShop: any | null;
  loading: boolean;
  error: string | null;
}

export const initialState: ShopState = {
  shops: [],
  currentShop: null,
  loading: false,
  error: null
};

export const shopReducer = createReducer(
  initialState,
  on(ShopActions.loadShops, state => ({
    ...state,
    loading: true,
    error: null
  })),
  on(ShopActions.loadShopsSuccess, (state, { shops }) => ({
    ...state,
    shops,
    loading: false,
    error: null
  })),
  on(ShopActions.loadShopsFailure, (state, { error }) => ({
    ...state,
    loading: false,
    error
  }))
);