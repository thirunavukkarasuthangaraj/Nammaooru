import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { ShopListComponent } from './components/shop-list/shop-list.component';
import { ProductListComponent } from './components/product-list/product-list.component';
import { ShoppingCartComponent } from './components/shopping-cart/shopping-cart.component';
import { CheckoutComponent } from './components/checkout/checkout.component';
import { OrderTrackingComponent } from './components/order-tracking/order-tracking.component';
import { OrderConfirmationComponent } from './components/order-confirmation/order-confirmation.component';
import { OrdersListComponent } from './components/orders-list/orders-list.component';
import { CustomerDashboardComponent } from './components/customer-dashboard/customer-dashboard.component';
import { CustomerProfileComponent } from './components/customer-profile/customer-profile.component';
import { NotificationsComponent } from './components/notifications/notifications.component';

const routes: Routes = [
  { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
  { path: 'dashboard', component: CustomerDashboardComponent },
  { path: 'shops', component: ShopListComponent },
  { path: 'products/:id', component: ProductListComponent },
  { path: 'cart', component: ShoppingCartComponent },
  { path: 'checkout', component: CheckoutComponent },
  { path: 'orders', component: OrdersListComponent },
  { path: 'notifications', component: NotificationsComponent },
  { path: 'track-order/:orderNumber', component: OrderTrackingComponent },
  { path: 'order-confirmation', component: OrderConfirmationComponent },
  { path: 'profile', component: CustomerProfileComponent }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class CustomerRoutingModule { }
