import { createReducer, on } from '@ngrx/store';
import * as NotificationActions from './notification.actions';

export interface NotificationState {
  notifications: any[];
  unreadCount: number;
  loading: boolean;
  error: string | null;
}

export const initialState: NotificationState = {
  notifications: [],
  unreadCount: 0,
  loading: false,
  error: null
};

export const notificationReducer = createReducer(
  initialState,
  on(NotificationActions.loadNotifications, state => ({
    ...state,
    loading: true,
    error: null
  })),
  on(NotificationActions.loadNotificationsSuccess, (state, { notifications }) => ({
    ...state,
    notifications,
    unreadCount: notifications.filter(n => !n.read).length,
    loading: false,
    error: null
  })),
  on(NotificationActions.loadNotificationsFailure, (state, { error }) => ({
    ...state,
    loading: false,
    error
  }))
);