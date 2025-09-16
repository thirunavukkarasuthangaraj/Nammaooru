import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { Shop } from '../../../../core/models/shop.model';
import { ShopService } from '../../../../core/services/shop.service';

@Component({
  selector: 'app-shop-form',
  template: `
    <div class="shop-form-container">
      <div class="header">
        <button mat-icon-button (click)="goBack()">
          <mat-icon>arrow_back</mat-icon>
        </button>
        <h1>{{isEdit ? 'Edit Shop' : 'Add New Shop'}}</h1>
      </div>

      <form [formGroup]="shopForm" (ngSubmit)="onSubmit()">
        <mat-card class="form-section">
          <mat-card-header>
            <mat-card-title>Basic Information</mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <div class="form-grid">
              <mat-form-field>
                <mat-label>Shop Name</mat-label>
                <input matInput formControlName="name" placeholder="Enter shop name">
                <mat-error *ngIf="shopForm.get('name')?.hasError('required')">
                  Shop name is required
                </mat-error>
              </mat-form-field>

              <mat-form-field>
                <mat-label>Business Type</mat-label>
                <mat-select formControlName="businessType">
                  <mat-option value="GROCERY">Grocery</mat-option>
                  <mat-option value="PHARMACY">Pharmacy</mat-option>
                  <mat-option value="RESTAURANT">Restaurant</mat-option>
                  <mat-option value="GENERAL">General</mat-option>
                </mat-select>
                <mat-error *ngIf="shopForm.get('businessType')?.hasError('required')">
                  Business type is required
                </mat-error>
              </mat-form-field>

              <mat-form-field class="full-width">
                <mat-label>Description</mat-label>
                <textarea matInput formControlName="description" rows="3" placeholder="Enter shop description"></textarea>
              </mat-form-field>

              <mat-form-field>
                <mat-label>Business Name</mat-label>
                <input matInput formControlName="businessName" placeholder="Enter business name">
                <mat-error *ngIf="shopForm.get('businessName')?.hasError('required')">
                  Business name is required
                </mat-error>
              </mat-form-field>
            </div>
          </mat-card-content>
        </mat-card>

        <mat-card class="form-section">
          <mat-card-header>
            <mat-card-title>Owner Information</mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <div class="form-grid">
              <mat-form-field>
                <mat-label>Owner Name</mat-label>
                <input matInput formControlName="ownerName" placeholder="Enter owner name">
                <mat-error *ngIf="shopForm.get('ownerName')?.hasError('required')">
                  Owner name is required
                </mat-error>
              </mat-form-field>

              <mat-form-field>
                <mat-label>Owner Email</mat-label>
                <input matInput type="email" formControlName="ownerEmail" placeholder="Enter owner email">
                <mat-error *ngIf="shopForm.get('ownerEmail')?.hasError('required')">
                  Owner email is required
                </mat-error>
                <mat-error *ngIf="shopForm.get('ownerEmail')?.hasError('email')">
                  Invalid email format
                </mat-error>
              </mat-form-field>

              <mat-form-field>
                <mat-label>Owner Phone</mat-label>
                <input matInput formControlName="ownerPhone" placeholder="Enter owner phone">
                <mat-error *ngIf="shopForm.get('ownerPhone')?.hasError('required')">
                  Owner phone is required
                </mat-error>
              </mat-form-field>
            </div>
          </mat-card-content>
        </mat-card>

        <mat-card class="form-section">
          <mat-card-header>
            <mat-card-title>Address Information</mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <div class="form-grid">
              <mat-form-field class="full-width">
                <mat-label>Address Line 1</mat-label>
                <input matInput formControlName="addressLine1" placeholder="Enter street address">
                <mat-error *ngIf="shopForm.get('addressLine1')?.hasError('required')">
                  Address is required
                </mat-error>
              </mat-form-field>

              <mat-form-field>
                <mat-label>City</mat-label>
                <input matInput formControlName="city" placeholder="Enter city">
                <mat-error *ngIf="shopForm.get('city')?.hasError('required')">
                  City is required
                </mat-error>
              </mat-form-field>

              <mat-form-field>
                <mat-label>State</mat-label>
                <input matInput formControlName="state" placeholder="Enter state">
                <mat-error *ngIf="shopForm.get('state')?.hasError('required')">
                  State is required
                </mat-error>
              </mat-form-field>

              <mat-form-field>
                <mat-label>Postal Code</mat-label>
                <input matInput formControlName="postalCode" placeholder="Enter postal code">
                <mat-error *ngIf="shopForm.get('postalCode')?.hasError('required')">
                  Postal code is required
                </mat-error>
              </mat-form-field>

              <mat-form-field>
                <mat-label>Country</mat-label>
                <input matInput formControlName="country" placeholder="Enter country">
                <mat-error *ngIf="shopForm.get('country')?.hasError('required')">
                  Country is required
                </mat-error>
              </mat-form-field>
            </div>
          </mat-card-content>
        </mat-card>

        <mat-card class="form-section">
          <mat-card-header>
            <mat-card-title>Business Settings</mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <div class="form-grid">
              <mat-form-field>
                <mat-label>Minimum Order Amount</mat-label>
                <input matInput type="number" formControlName="minOrderAmount" placeholder="0">
                <span matTextPrefix>₹&nbsp;</span>
              </mat-form-field>


              <mat-form-field>
                <mat-label>Delivery Radius</mat-label>
                <input matInput type="number" formControlName="deliveryRadius" placeholder="5">
                <span matTextSuffix>&nbsp;km</span>
              </mat-form-field>

              <mat-form-field>
                <mat-label>Free Delivery Above</mat-label>
                <input matInput type="number" formControlName="freeDeliveryAbove" placeholder="500">
                <span matTextPrefix>₹&nbsp;</span>
              </mat-form-field>

              <mat-form-field>
                <mat-label>Commission Rate</mat-label>
                <input matInput type="number" formControlName="commissionRate" placeholder="15">
                <span matTextSuffix>&nbsp;%</span>
              </mat-form-field>
            </div>
          </mat-card-content>
        </mat-card>

        <div class="form-actions">
          <button mat-button type="button" (click)="goBack()">Cancel</button>
          <button mat-raised-button color="primary" type="submit" [disabled]="shopForm.invalid || loading">
            <mat-icon *ngIf="loading">refresh</mat-icon>
            {{isEdit ? 'Update Shop' : 'Create Shop'}}
          </button>
        </div>
      </form>
    </div>
  `,
  styles: [`
    .shop-form-container {
      padding: 20px;
      max-width: 1000px;
      margin: 0 auto;
    }

    .header {
      display: flex;
      align-items: center;
      gap: 20px;
      margin-bottom: 30px;
    }

    .header h1 {
      margin: 0;
    }

    .form-section {
      margin-bottom: 20px;
    }

    .form-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
      gap: 20px;
      margin-top: 20px;
    }

    .full-width {
      grid-column: 1 / -1;
    }

    .form-actions {
      display: flex;
      justify-content: flex-end;
      gap: 15px;
      margin-top: 30px;
      padding: 20px 0;
    }

    mat-form-field {
      width: 100%;
    }
  `]
})
export class ShopFormComponent implements OnInit {
  shopForm: FormGroup;
  isEdit = false;
  loading = false;
  shopId: number | null = null;

  constructor(
    private fb: FormBuilder,
    private route: ActivatedRoute,
    private router: Router,
    private shopService: ShopService
  ) {
    this.shopForm = this.createForm();
  }

  ngOnInit() {
    const id = this.route.snapshot.paramMap.get('id');
    if (id && id !== 'new') {
      this.isEdit = true;
      this.shopId = +id;
      this.loadShop(this.shopId);
    }
  }

  createForm(): FormGroup {
    return this.fb.group({
      name: ['', Validators.required],
      description: [''],
      businessName: ['', Validators.required],
      businessType: ['', Validators.required],
      ownerName: ['', Validators.required],
      ownerEmail: ['', [Validators.required, Validators.email]],
      ownerPhone: ['', Validators.required],
      addressLine1: ['', Validators.required],
      city: ['', Validators.required],
      state: ['', Validators.required],
      postalCode: ['', Validators.required],
      country: ['India'],
      minOrderAmount: [0],
      deliveryRadius: [5],
      freeDeliveryAbove: [500],
      commissionRate: [15]
    });
  }

  loadShop(id: number) {
    this.loading = true;
    this.shopService.getShop(id).subscribe({
      next: (shop) => {
        this.shopForm.patchValue(shop);
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading shop:', error);
        this.loading = false;
        this.goBack();
      }
    });
  }

  onSubmit() {
    if (this.shopForm.valid) {
      this.loading = true;
      const shopData = this.shopForm.value;

      if (this.isEdit && this.shopId) {
        this.shopService.updateShop(this.shopId, shopData).subscribe({
          next: (shop) => {
            this.loading = false;
            this.router.navigate(['/shops', shop.id]);
          },
          error: (error) => {
            console.error('Error updating shop:', error);
            this.loading = false;
          }
        });
      } else {
        this.shopService.createShop(shopData).subscribe({
          next: (shop) => {
            this.loading = false;
            this.router.navigate(['/shops', shop.id]);
          },
          error: (error) => {
            console.error('Error creating shop:', error);
            this.loading = false;
          }
        });
      }
    }
  }

  goBack() {
    this.router.navigate(['/shops']);
  }
}