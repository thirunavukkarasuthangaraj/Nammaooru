import { createAction, props } from '@ngrx/store';

export const loadNotifications = createAction('[Notification] Load Notifications');

export const loadNotificationsSuccess = createAction(
  '[Notification] Load Notifications Success',
  props<{ notifications: any[] }>()
);

export const loadNotificationsFailure = createAction(
  '[Notification] Load Notifications Failure',
  props<{ error: string }>()
);