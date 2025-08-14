import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';

@NgModule({
  declarations: [],
  imports: [
    CommonModule,
    RouterModule.forChild([
      {
        path: '',
        loadChildren: () => import('../shop/shop.module').then(m => m.ShopModule)
      }
    ])
  ]
})
export class ShopOwnerModule { }