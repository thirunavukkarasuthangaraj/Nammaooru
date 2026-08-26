import { Component, OnInit, ViewChild, AfterViewInit } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { SwalService } from '../../../../core/services/swal.service';
import { AuthService } from '@core/services/auth.service';
import { PosSyncService } from '@core/services/pos-sync.service';

interface ShopCustomer {
  customerId: number;
  name: string;
  phone: string;
  totalOrders: number;
  totalSpent: number;
  averageOrderValue: number;
  lastOrderDate: Date | null;
}

interface CustomerOrder {
  orderId: number;
  orderNumber: string;
  createdAt: Date | null;
  status: string;
  paymentMethod: string;
  totalAmount: number;
  items: { productName: string; quantity: number; unitPrice: number; totalPrice: number }[];
}

@Component({
  selector: 'app-customer-management',
  template: `
    <div class="customer-management-container">
      <!-- Header -->
      <div class="page-header">
        <div class="header-content">
          <h1 class="page-title">Customers</h1>
          <p class="page-subtitle">Everyone you have billed at your shop</p>
        </div>
        <div class="header-actions">
          <button mat-stroked-button (click)="exportCustomers()">
            <mat-icon>download</mat-icon>
            Export Data
          </button>
        </div>
      </div>

      <!-- Stats Cards -->
      <div class="stats-cards">
        <mat-card class="stat-card">
          <mat-card-content>
            <div class="stat-content">
              <div class="stat-icon total">
                <mat-icon>people</mat-icon>
              </div>
              <div class="stat-details">
                <h3>{{ getTotalCustomers() }}</h3>
                <p>Total Customers</p>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <mat-card class="stat-card">
          <mat-card-content>
            <div class="stat-content">
              <div class="stat-icon active">
                <mat-icon>receipt_long</mat-icon>
              </div>
              <div class="stat-details">
                <h3>{{ getTotalBills() }}</h3>
                <p>Total Bills</p>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <mat-card class="stat-card">
          <mat-card-content>
            <div class="stat-content">
              <div class="stat-icon revenue">
                <mat-icon>monetization_on</mat-icon>
              </div>
              <div class="stat-details">
                <h3>{{ getAverageOrderValue() | currency:'INR':'symbol':'1.0-0' }}</h3>
                <p>Avg Order Value</p>
              </div>
            </div>
          </mat-card-content>
        </mat-card>

        <mat-card class="stat-card">
          <mat-card-content>
            <div class="stat-content">
              <div class="stat-icon loyal">
                <mat-icon>loyalty</mat-icon>
              </div>
              <div class="stat-details">
                <h3>{{ getLoyalCustomers() }}</h3>
                <p>Loyal Customers (10+ bills)</p>
              </div>
            </div>
          </mat-card-content>
        </mat-card>
      </div>

      <!-- Loading State -->
      <div *ngIf="loading" class="loading-container">
        <mat-spinner></mat-spinner>
        <p>Loading customer data...</p>
      </div>

      <!-- Customers Table -->
      <mat-card class="customers-table-card" *ngIf="!loading">
        <mat-card-content>
          <div class="table-toolbar">
            <mat-form-field appearance="outline" class="search-field">
              <mat-label>Search by name or mobile number</mat-label>
              <input matInput [(ngModel)]="searchText" (input)="applyFilter()" placeholder="e.g. 8144 or thiru">
              <mat-icon matSuffix>search</mat-icon>
            </mat-form-field>
            <mat-form-field appearance="outline" class="filter-field">
              <mat-label>Show</mat-label>
              <mat-select [(ngModel)]="inactiveDays" (selectionChange)="applyInactiveFilter()">
                <mat-option [value]="0">All customers</mat-option>
                <mat-option [value]="30">Not visited in 30 days</mat-option>
                <mat-option [value]="60">Not visited in 60 days</mat-option>
                <mat-option [value]="90">Not visited in 90 days</mat-option>
              </mat-select>
            </mat-form-field>
          </div>

          <!-- WhatsApp Offer Campaign -->
          <div class="offer-panel" *ngIf="realSelectedCount() > 0">
            <div class="offer-panel-header">
              <div class="offer-title">
                <mat-icon>campaign</mat-icon>
                <span>WhatsApp Offer</span>
              </div>
              <div class="offer-meta">
                <span class="offer-chip">{{ realSelectedCount() }} customer{{ realSelectedCount() === 1 ? '' : 's' }}</span>
                <span class="offer-chip cost">~{{ realSelectedCount() * 0.9 | currency:'INR':'symbol':'1.0-0' }}</span>
              </div>
            </div>
            <mat-form-field appearance="outline" class="offer-field">
              <mat-label>Offer message</mat-label>
              <textarea matInput [(ngModel)]="offerText" maxlength="300" rows="2"
                        placeholder="e.g. 10% off on all groceries this week!"></textarea>
              <mat-hint align="end">{{ offerText.length }}/300</mat-hint>
            </mat-form-field>
            <div class="offer-actions">
              <input type="file" #offerImageInput hidden accept="image/jpeg,image/png"
                     (change)="onOfferImageSelected($event)">
              <button mat-stroked-button (click)="offerImageInput.click()" *ngIf="!offerImagePreview">
                <mat-icon>add_photo_alternate</mat-icon>
                Add image (optional)
              </button>
              <div class="offer-image-chip" *ngIf="offerImagePreview">
                <img [src]="offerImagePreview" alt="Offer image">
                <span>{{ offerImageFile?.name }}</span>
                <button mat-icon-button (click)="removeOfferImage()" aria-label="Remove image">
                  <mat-icon>close</mat-icon>
                </button>
              </div>
              <span class="offer-spacer"></span>
              <button mat-raised-button color="primary"
                      [disabled]="sendingOffer || !offerText.trim()"
                      (click)="openOfferPreview()">
                <mat-icon>visibility</mat-icon>
                Preview & Send
              </button>
            </div>
          </div>

          <!-- Offer preview + double confirmation modal -->
          <div class="offer-modal-backdrop" *ngIf="showOfferPreview" (click)="closeOfferPreview()">
            <div class="offer-modal" (click)="$event.stopPropagation()">
              <div class="offer-modal-header">
                <mat-icon>preview</mat-icon>
                <span>Customers will see it like this</span>
                <button mat-icon-button (click)="closeOfferPreview()" [disabled]="sendingOffer" aria-label="Close preview">
                  <mat-icon>close</mat-icon>
                </button>
              </div>

              <div class="wa-chat">
                <div class="wa-bubble">
                  <img *ngIf="offerImagePreview" [src]="offerImagePreview" class="wa-image" alt="Offer image">
                  <p class="wa-text">Hi <b>{{ previewCustomerName() }}</b>, {{ shopDisplayName() }} has an offer for you: {{ offerText.trim() }}</p>
                  <span class="wa-time">{{ now | date:'shortTime' }}</span>
                </div>
                <p class="wa-note">Each customer sees their own name. Sent from your business number.</p>
              </div>

              <div class="offer-confirm">
                <p>
                  Send this offer to <b>{{ realSelectedCount() }} customer{{ realSelectedCount() === 1 ? '' : 's' }}</b>
                  (approx cost {{ realSelectedCount() * 0.9 | currency:'INR':'symbol':'1.0-0' }})?
                </p>
                <div class="offer-confirm-actions">
                  <button mat-stroked-button (click)="closeOfferPreview()" [disabled]="sendingOffer">Cancel</button>
                  <button mat-raised-button color="primary" (click)="confirmSendOffer()" [disabled]="sendingOffer">
                    <mat-icon>send</mat-icon>
                    {{ sendingOffer ? 'Sending...' : 'Yes, Send Now' }}
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- Edit customer modal -->
          <div class="offer-modal-backdrop" *ngIf="editingCustomer" (click)="closeEdit()">
            <div class="offer-modal" (click)="$event.stopPropagation()">
              <div class="offer-modal-header">
                <mat-icon class="edit-icon">edit</mat-icon>
                <span>Edit Customer</span>
                <button mat-icon-button (click)="closeEdit()" [disabled]="savingEdit" aria-label="Close edit">
                  <mat-icon>close</mat-icon>
                </button>
              </div>
              <div class="edit-form">
                <mat-form-field appearance="outline">
                  <mat-label>Customer name</mat-label>
                  <input matInput [(ngModel)]="editName" maxlength="100">
                </mat-form-field>
                <mat-form-field appearance="outline">
                  <mat-label>Mobile number</mat-label>
                  <input matInput [(ngModel)]="editPhone" maxlength="10" inputmode="numeric"
                         placeholder="10-digit mobile number">
                </mat-form-field>
                <div class="offer-confirm-actions">
                  <button mat-stroked-button (click)="closeEdit()" [disabled]="savingEdit">Cancel</button>
                  <button mat-raised-button color="primary" (click)="saveEdit()" [disabled]="savingEdit">
                    <mat-icon>save</mat-icon>
                    {{ savingEdit ? 'Saving...' : 'Save' }}
                  </button>
                </div>
              </div>
            </div>
          </div>

          <div *ngIf="!loading && dataSource.data.length === 0" class="empty-state">
            <mat-icon>person_search</mat-icon>
            <p>No customers yet. Customers appear here automatically when you add their phone number on a bill.</p>
          </div>

          <div class="table-container" *ngIf="dataSource.data.length > 0">
            <table mat-table [dataSource]="dataSource" matSort class="customers-table">
              <!-- Select Column -->
              <ng-container matColumnDef="select">
                <th mat-header-cell *matHeaderCellDef>
                  <mat-checkbox (change)="toggleSelectAll($event.checked)"
                                [checked]="allVisibleSelected()"
                                [indeterminate]="selectedIds.size > 0 && !allVisibleSelected()">
                  </mat-checkbox>
                </th>
                <td mat-cell *matCellDef="let customer" (click)="$event.stopPropagation()">
                  <mat-checkbox [checked]="selectedIds.has(customer.customerId)"
                                [disabled]="isWalkIn(customer)"
                                [matTooltip]="isWalkIn(customer) ? 'Walk-in customers have no real number' : ''"
                                (change)="toggleSelect(customer)">
                  </mat-checkbox>
                </td>
              </ng-container>

              <!-- Name Column -->
              <ng-container matColumnDef="name">
                <th mat-header-cell *matHeaderCellDef mat-sort-header>Customer Name</th>
                <td mat-cell *matCellDef="let customer">
                  <span class="customer-name">{{ customer.name || 'Customer' }}</span>
                </td>
              </ng-container>

              <!-- Phone Column -->
              <ng-container matColumnDef="phone">
                <th mat-header-cell *matHeaderCellDef>Mobile Number</th>
                <td mat-cell *matCellDef="let customer">
                  <span *ngIf="!isWalkIn(customer)">{{ customer.phone }}</span>
                  <span *ngIf="isWalkIn(customer)" class="no-orders">Walk-in (no number)</span>
                </td>
              </ng-container>

              <!-- Orders Column -->
              <ng-container matColumnDef="totalOrders">
                <th mat-header-cell *matHeaderCellDef mat-sort-header>Bills</th>
                <td mat-cell *matCellDef="let customer">{{ customer.totalOrders }}</td>
              </ng-container>

              <!-- Spent Column -->
              <ng-container matColumnDef="totalSpent">
                <th mat-header-cell *matHeaderCellDef mat-sort-header>Total Spent</th>
                <td mat-cell *matCellDef="let customer">{{ customer.totalSpent | currency:'INR':'symbol':'1.0-0' }}</td>
              </ng-container>

              <!-- Average Order Value Column -->
              <ng-container matColumnDef="averageOrderValue">
                <th mat-header-cell *matHeaderCellDef>Avg Bill</th>
                <td mat-cell *matCellDef="let customer">{{ customer.averageOrderValue | currency:'INR':'symbol':'1.0-0' }}</td>
              </ng-container>

              <!-- Last Order Column -->
              <ng-container matColumnDef="lastOrderDate">
                <th mat-header-cell *matHeaderCellDef mat-sort-header>Last Visit</th>
                <td mat-cell *matCellDef="let customer">
                  <span *ngIf="customer.lastOrderDate">{{ customer.lastOrderDate | date:'mediumDate' }}</span>
                  <span *ngIf="!customer.lastOrderDate" class="no-orders">-</span>
                </td>
              </ng-container>

              <!-- Actions Column -->
              <ng-container matColumnDef="actions">
                <th mat-header-cell *matHeaderCellDef></th>
                <td mat-cell *matCellDef="let customer" (click)="$event.stopPropagation()">
                  <button mat-icon-button *ngIf="!isWalkIn(customer)"
                          matTooltip="Edit name / number"
                          (click)="openEdit(customer)">
                    <mat-icon>edit</mat-icon>
                  </button>
                </td>
              </ng-container>

              <tr mat-header-row *matHeaderRowDef="displayedColumns"></tr>
              <tr mat-row *matRowDef="let row; columns: displayedColumns;"
                  class="customer-row"
                  [class.selected]="selectedCustomer?.customerId === row.customerId"
                  (click)="viewHistory(row)"></tr>
            </table>

            <mat-paginator #paginator
                          [pageSizeOptions]="[10, 25, 50]"
                          [pageSize]="10"
                          showFirstLastButtons>
            </mat-paginator>
          </div>
        </mat-card-content>
      </mat-card>

      <!-- Purchase History Panel -->
      <mat-card class="history-card" *ngIf="selectedCustomer">
        <mat-card-content>
          <div class="history-header">
            <div>
              <h2 class="history-title">
                {{ selectedCustomer.name || 'Customer' }} - Purchase History
              </h2>
              <p class="history-subtitle">{{ selectedCustomer.phone }} | {{ customerOrders.length }} bill{{ customerOrders.length === 1 ? '' : 's' }}</p>
            </div>
            <button mat-icon-button (click)="closeHistory()" aria-label="Close history">
              <mat-icon>close</mat-icon>
            </button>
          </div>

          <div *ngIf="loadingHistory" class="loading-container">
            <mat-spinner diameter="36"></mat-spinner>
            <p>Loading purchase history...</p>
          </div>

          <div *ngIf="!loadingHistory && customerOrders.length === 0" class="empty-state">
            <p>No bills found for this customer.</p>
          </div>

          <div *ngIf="!loadingHistory" class="history-orders">
            <div class="history-order" *ngFor="let order of customerOrders">
              <div class="order-summary">
                <div class="order-meta">
                  <span class="order-number">{{ order.orderNumber }}</span>
                  <span class="order-date">{{ order.createdAt | date:'medium' }}</span>
                </div>
                <div class="order-right">
                  <span class="order-payment" *ngIf="order.paymentMethod">{{ order.paymentMethod.replace('_', ' ') | titlecase }}</span>
                  <span class="order-total">{{ order.totalAmount | currency:'INR':'symbol':'1.0-2' }}</span>
                </div>
              </div>
              <table class="order-items" *ngIf="order.items.length > 0">
                <tr *ngFor="let item of order.items">
                  <td class="item-name">{{ item.productName }}</td>
                  <td class="item-qty">{{ item.quantity }} x {{ item.unitPrice | currency:'INR':'symbol':'1.0-2' }}</td>
                  <td class="item-total">{{ item.totalPrice | currency:'INR':'symbol':'1.0-2' }}</td>
                </tr>
              </table>
            </div>
          </div>
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styles: [`
    .customer-management-container {
      padding: 24px;
      background-color: #f5f5f5;
      min-height: calc(100vh - 64px);
    }

    .page-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 24px;
    }

    .page-title {
      font-size: 2rem;
      font-weight: 600;
      margin: 0 0 4px 0;
      color: #1f2937;
    }

    .page-subtitle {
      color: #6b7280;
      margin: 0;
    }

    .header-actions {
      display: flex;
      gap: 12px;
    }

    .stats-cards {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 16px;
      margin-bottom: 24px;
    }

    .stat-card {
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }

    .stat-content {
      display: flex;
      align-items: center;
      gap: 16px;
    }

    .stat-icon {
      width: 48px;
      height: 48px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      color: white;
    }

    .stat-icon.total { background: #3b82f6; }
    .stat-icon.active { background: #10b981; }
    .stat-icon.revenue { background: #f59e0b; }
    .stat-icon.loyal { background: #8b5cf6; }

    .stat-details h3 {
      font-size: 1.5rem;
      font-weight: 600;
      margin: 0 0 4px 0;
      color: #1f2937;
    }

    .stat-details p {
      color: #6b7280;
      margin: 0;
      font-size: 0.9rem;
    }

    .loading-container {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      height: 200px;
    }

    .customers-table-card {
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }

    .table-toolbar {
      display: flex;
      justify-content: flex-start;
      gap: 16px;
      flex-wrap: wrap;
      padding-top: 8px;
    }

    .search-field {
      width: 100%;
      max-width: 400px;
    }

    .filter-field {
      width: 100%;
      max-width: 240px;
    }

    .offer-panel {
      border: 1px solid #e5e7eb;
      border-left: 4px solid #25d366;
      background: #ffffff;
      border-radius: 12px;
      padding: 16px 20px;
      margin-bottom: 16px;
      box-shadow: 0 1px 4px rgba(0,0,0,0.06);
    }

    .offer-panel-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 12px;
      flex-wrap: wrap;
      gap: 8px;
    }

    .offer-title {
      display: flex;
      align-items: center;
      gap: 8px;
      font-weight: 600;
      color: #1f2937;
      font-size: 1.05rem;

      mat-icon { color: #25d366; }
    }

    .offer-meta {
      display: flex;
      gap: 8px;
    }

    .offer-chip {
      background: #f3f4f6;
      color: #374151;
      border-radius: 999px;
      padding: 4px 12px;
      font-size: 0.85rem;
      font-weight: 500;
    }

    .offer-chip.cost {
      background: #ecfdf5;
      color: #065f46;
    }

    .offer-field {
      width: 100%;
    }

    .offer-actions {
      display: flex;
      align-items: center;
      gap: 12px;
      flex-wrap: wrap;
    }

    .offer-spacer { flex: 1; }

    .offer-image-chip {
      display: flex;
      align-items: center;
      gap: 8px;
      border: 1px solid #e5e7eb;
      border-radius: 8px;
      padding: 4px 4px 4px 4px;
      background: #f9fafb;
      max-width: 320px;

      img {
        width: 40px;
        height: 40px;
        object-fit: cover;
        border-radius: 6px;
      }

      span {
        font-size: 0.85rem;
        color: #374151;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
      }
    }

    .offer-modal-backdrop {
      position: fixed;
      inset: 0;
      background: rgba(17, 24, 39, 0.55);
      z-index: 1000;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 16px;
    }

    .offer-modal {
      background: #ffffff;
      border-radius: 16px;
      width: 100%;
      max-width: 480px;
      max-height: 90vh;
      overflow-y: auto;
      box-shadow: 0 20px 50px rgba(0,0,0,0.3);
    }

    .offer-modal-header {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 16px 8px 16px 20px;
      border-bottom: 1px solid #e5e7eb;
      font-weight: 600;
      color: #1f2937;

      mat-icon { color: #25d366; }
      span { flex: 1; }
    }

    .wa-chat {
      background: #ece5dd;
      padding: 20px;
    }

    .wa-bubble {
      background: #ffffff;
      border-radius: 10px;
      border-top-left-radius: 2px;
      padding: 8px;
      max-width: 85%;
      box-shadow: 0 1px 1px rgba(0,0,0,0.12);
      position: relative;
    }

    .wa-image {
      width: 100%;
      max-height: 220px;
      object-fit: cover;
      border-radius: 8px;
      margin-bottom: 6px;
      display: block;
    }

    .wa-text {
      margin: 0 6px 14px 6px;
      color: #111827;
      font-size: 0.95rem;
      line-height: 1.45;
      word-break: break-word;
    }

    .wa-time {
      position: absolute;
      right: 10px;
      bottom: 6px;
      font-size: 0.7rem;
      color: #6b7280;
    }

    .wa-note {
      margin: 12px 0 0 0;
      font-size: 0.8rem;
      color: #4b5563;
      text-align: center;
    }

    .offer-confirm {
      padding: 16px 20px 20px 20px;

      p {
        margin: 0 0 16px 0;
        color: #374151;
        text-align: center;
      }
    }

    .offer-confirm-actions {
      display: flex;
      justify-content: center;
      gap: 12px;
    }

    .edit-icon {
      color: #3b82f6 !important;
    }

    .edit-form {
      padding: 20px;
      display: flex;
      flex-direction: column;
      gap: 4px;

      mat-form-field { width: 100%; }
    }

    .empty-state {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 12px;
      padding: 48px 24px;
      color: #6b7280;
      text-align: center;

      mat-icon {
        font-size: 48px;
        width: 48px;
        height: 48px;
        color: #9ca3af;
      }
    }

    .table-container {
      width: 100%;
      overflow-x: auto;
    }

    .customers-table {
      width: 100%;
    }

    .customer-name {
      font-weight: 500;
      color: #1f2937;
    }

    .no-orders {
      color: #9ca3af;
      font-style: italic;
    }

    .customer-row {
      cursor: pointer;
    }

    .customer-row:hover {
      background: #f9fafb;
    }

    .customer-row.selected {
      background: #ecfdf5;
    }

    .history-card {
      margin-top: 24px;
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }

    .history-header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 12px;
    }

    .history-title {
      font-size: 1.25rem;
      font-weight: 600;
      margin: 0 0 2px 0;
      color: #1f2937;
    }

    .history-subtitle {
      color: #6b7280;
      margin: 0;
      font-size: 0.9rem;
    }

    .history-orders {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .history-order {
      border: 1px solid #e5e7eb;
      border-radius: 8px;
      padding: 12px 16px;
    }

    .order-summary {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
      flex-wrap: wrap;
    }

    .order-meta {
      display: flex;
      flex-direction: column;
    }

    .order-number {
      font-weight: 600;
      color: #1f2937;
    }

    .order-date {
      font-size: 0.85rem;
      color: #6b7280;
    }

    .order-right {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .order-payment {
      font-size: 0.8rem;
      color: #6b7280;
      background: #f3f4f6;
      border-radius: 10px;
      padding: 2px 10px;
    }

    .order-total {
      font-weight: 700;
      color: #059669;
      font-size: 1.05rem;
    }

    .order-items {
      margin-top: 8px;
      width: 100%;
      border-top: 1px dashed #e5e7eb;
      padding-top: 8px;
      font-size: 0.9rem;
      border-collapse: collapse;
    }

    .order-items td {
      padding: 3px 0;
    }

    .item-name {
      color: #374151;
    }

    .item-qty {
      color: #6b7280;
      text-align: right;
      padding-right: 16px !important;
      white-space: nowrap;
    }

    .item-total {
      text-align: right;
      color: #1f2937;
      white-space: nowrap;
    }

    @media (max-width: 768px) {
      .customer-management-container {
        padding: 16px;
      }

      .page-header {
        flex-direction: column;
        align-items: flex-start;
        gap: 16px;
      }

      .stats-cards {
        grid-template-columns: 1fr;
      }
    }
  `]
})
export class CustomerManagementComponent implements OnInit, AfterViewInit {
  @ViewChild(MatPaginator) paginator!: MatPaginator;
  @ViewChild(MatSort) sort!: MatSort;

  dataSource = new MatTableDataSource<ShopCustomer>();
  displayedColumns = ['select', 'name', 'phone', 'totalOrders', 'totalSpent', 'averageOrderValue', 'lastOrderDate', 'actions'];
  loading = false;
  searchText = '';
  inactiveDays = 0;

  // WhatsApp offer campaign
  selectedIds = new Set<number>();
  offerText = '';
  sendingOffer = false;
  offerImageFile: File | null = null;
  offerImagePreview: string | null = null;
  showOfferPreview = false;
  now = new Date();

  customers: ShopCustomer[] = [];

  // Edit customer modal
  editingCustomer: ShopCustomer | null = null;
  editName = '';
  editPhone = '';
  savingEdit = false;

  // Purchase history panel
  selectedCustomer: ShopCustomer | null = null;
  customerOrders: CustomerOrder[] = [];
  loadingHistory = false;

  constructor(
    private swal: SwalService,
    private authService: AuthService,
    private syncService: PosSyncService
  ) {}

  ngOnInit(): void {
    this.loadCustomers();
  }

  ngAfterViewInit(): void {
    this.dataSource.paginator = this.paginator;
    this.dataSource.sort = this.sort;
  }

  private resolveShopId(): number {
    const currentUser: any = this.authService.getCurrentUser();
    if (currentUser?.shopId) {
      return Number(currentUser.shopId);
    }
    const storedShopId = localStorage.getItem('current_shop_id');
    return storedShopId ? parseInt(storedShopId, 10) : 0;
  }

  async loadCustomers(): Promise<void> {
    const shopId = this.resolveShopId();
    if (!shopId) {
      this.swal.toast('Shop information not found', 'error');
      return;
    }

    this.loading = true;
    try {
      const results = await this.syncService.searchCustomers(shopId, '', 500);
      this.customers = (results || []).map((c: any) => {
        const totalOrders = Number(c.billCount) || 0;
        const totalSpent = Number(c.totalSpent) || 0;
        return {
          customerId: Number(c.customerId),
          name: c.customerName || '',
          phone: c.customerPhone || '',
          totalOrders,
          totalSpent,
          averageOrderValue: totalOrders > 0 ? totalSpent / totalOrders : 0,
          lastOrderDate: c.lastOrderDate ? new Date(c.lastOrderDate) : null
        };
      });
      this.dataSource.data = this.customers;
      // Re-attach paginator/sort after *ngIf re-renders the table
      setTimeout(() => {
        this.dataSource.paginator = this.paginator;
        this.dataSource.sort = this.sort;
      });
    } catch (error) {
      console.error('Error loading customers:', error);
      this.swal.toast('Failed to load customers', 'error');
    } finally {
      this.loading = false;
    }
  }

  applyFilter(): void {
    this.dataSource.filter = this.searchText.trim().toLowerCase();
  }

  applyInactiveFilter(): void {
    this.selectedIds.clear();
    if (!this.inactiveDays) {
      this.dataSource.data = this.customers;
      return;
    }
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - this.inactiveDays);
    this.dataSource.data = this.customers.filter(
      c => !c.lastOrderDate || c.lastOrderDate < cutoff
    );
  }

  /** Shared per-shop walk-in placeholder (90000 + shop id) is not a real mobile number */
  isWalkIn(customer: ShopCustomer): boolean {
    return /^90000\d{5}$/.test(customer.phone || '');
  }

  /** Selected customers excluding walk-in placeholders */
  realSelectedCount(): number {
    return this.customers.filter(c => this.selectedIds.has(c.customerId) && !this.isWalkIn(c)).length;
  }

  toggleSelect(customer: ShopCustomer): void {
    if (this.isWalkIn(customer)) {
      return;
    }
    if (this.selectedIds.has(customer.customerId)) {
      this.selectedIds.delete(customer.customerId);
    } else {
      this.selectedIds.add(customer.customerId);
    }
  }

  allVisibleSelected(): boolean {
    const visible = this.dataSource.filteredData.filter(c => !this.isWalkIn(c));
    return visible.length > 0 && visible.every(c => this.selectedIds.has(c.customerId));
  }

  toggleSelectAll(checked: boolean): void {
    if (checked) {
      this.dataSource.filteredData.filter(c => !this.isWalkIn(c))
        .forEach(c => this.selectedIds.add(c.customerId));
    } else {
      this.selectedIds.clear();
    }
  }

  onOfferImageSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files && input.files[0];
    input.value = '';
    if (!file) {
      return;
    }
    if (!['image/jpeg', 'image/png'].includes(file.type)) {
      this.swal.toast('Only JPEG or PNG images are supported', 'warning');
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      this.swal.toast('Image too large (max 5MB)', 'warning');
      return;
    }
    this.offerImageFile = file;
    const reader = new FileReader();
    reader.onload = () => this.offerImagePreview = reader.result as string;
    reader.readAsDataURL(file);
  }

  removeOfferImage(): void {
    this.offerImageFile = null;
    this.offerImagePreview = null;
  }

  shopDisplayName(): string {
    const currentUser: any = this.authService.getCurrentUser();
    return currentUser?.shopName || currentUser?.businessName || 'Your shop';
  }

  /** Name of the first selected customer, used to make the preview concrete */
  previewCustomerName(): string {
    const first = this.customers.find(c => this.selectedIds.has(c.customerId) && !this.isWalkIn(c));
    return first?.name || 'Customer';
  }

  openOfferPreview(): void {
    if (!this.offerText.trim() || this.realSelectedCount() === 0) {
      return;
    }
    this.now = new Date();
    this.showOfferPreview = true;
  }

  closeOfferPreview(): void {
    if (!this.sendingOffer) {
      this.showOfferPreview = false;
    }
  }

  async confirmSendOffer(): Promise<void> {
    const text = this.offerText.trim();
    const ids = this.customers
      .filter(c => this.selectedIds.has(c.customerId) && !this.isWalkIn(c))
      .map(c => c.customerId);
    if (!text || ids.length === 0 || this.sendingOffer) {
      return;
    }
    this.sendingOffer = true;
    try {
      const shopId = this.resolveShopId();
      let imageUrl: string | undefined;
      if (this.offerImageFile) {
        imageUrl = await this.syncService.uploadOfferImage(shopId, this.offerImageFile);
        if (!imageUrl) {
          throw new Error('Image upload failed');
        }
      }
      const result = await this.syncService.sendOfferToCustomers(shopId, ids, text, imageUrl);
      const sent = result.sent ?? 0;
      const failed = result.failed ?? 0;
      this.swal.toast(
        failed > 0 ? `Offer sent to ${sent} customers (${failed} failed)` : `Offer sent to ${sent} customers`,
        failed > 0 ? 'warning' : 'success'
      );
      if (sent > 0) {
        this.selectedIds.clear();
        this.offerText = '';
        this.removeOfferImage();
      }
      this.showOfferPreview = false;
    } catch (error: any) {
      console.error('Error sending offer:', error);
      const message = error?.error?.message || error?.message || 'Failed to send offer messages';
      this.swal.toast(message, 'error');
    } finally {
      this.sendingOffer = false;
    }
  }

  openEdit(customer: ShopCustomer): void {
    if (this.isWalkIn(customer)) {
      return;
    }
    this.editingCustomer = customer;
    this.editName = customer.name || '';
    this.editPhone = customer.phone || '';
  }

  closeEdit(): void {
    if (!this.savingEdit) {
      this.editingCustomer = null;
    }
  }

  async saveEdit(): Promise<void> {
    if (!this.editingCustomer || this.savingEdit) {
      return;
    }
    const name = this.editName.trim();
    const phone = this.editPhone.trim();
    if (!name) {
      this.swal.toast('Customer name is required', 'warning');
      return;
    }
    if (!/^[6-9]\d{9}$/.test(phone)) {
      this.swal.toast('Enter a valid 10-digit mobile number', 'warning');
      return;
    }
    this.savingEdit = true;
    try {
      const shopId = this.resolveShopId();
      const result = await this.syncService.updateCustomer(
        shopId, this.editingCustomer.customerId, name, phone
      );
      // Rows in the table reference the same objects as this.customers
      this.editingCustomer.name = result.customerName || name;
      this.editingCustomer.phone = result.customerPhone || phone;
      this.editingCustomer = null;
      this.swal.toast('Customer updated', 'success');
    } catch (error: any) {
      console.error('Error updating customer:', error);
      const message = error?.error?.message || 'Failed to update customer';
      this.swal.toast(message, 'error');
    } finally {
      this.savingEdit = false;
    }
  }

  async viewHistory(customer: ShopCustomer): Promise<void> {
    if (this.selectedCustomer?.customerId === customer.customerId) {
      this.closeHistory();
      return;
    }
    this.selectedCustomer = customer;
    this.customerOrders = [];
    this.loadingHistory = true;
    try {
      const shopId = this.resolveShopId();
      const orders = await this.syncService.getCustomerOrders(shopId, customer.customerId);
      this.customerOrders = (orders || []).map((o: any) => ({
        orderId: o.orderId,
        orderNumber: o.orderNumber,
        createdAt: o.createdAt ? new Date(o.createdAt) : null,
        status: o.status || '',
        paymentMethod: o.paymentMethod || '',
        totalAmount: Number(o.totalAmount) || 0,
        items: (o.items || []).map((i: any) => ({
          productName: i.productName || '',
          quantity: Number(i.quantity) || 0,
          unitPrice: Number(i.unitPrice) || 0,
          totalPrice: Number(i.totalPrice) || 0
        }))
      }));
    } catch (error) {
      console.error('Error loading purchase history:', error);
      this.swal.toast('Failed to load purchase history', 'error');
    } finally {
      this.loadingHistory = false;
    }
  }

  closeHistory(): void {
    this.selectedCustomer = null;
    this.customerOrders = [];
  }

  getTotalCustomers(): number {
    // Walk-in placeholder rows are bill buckets, not real customers
    return this.customers.filter(c => !this.isWalkIn(c)).length;
  }

  getTotalBills(): number {
    return this.customers.reduce((sum, c) => sum + c.totalOrders, 0);
  }

  getAverageOrderValue(): number {
    const bills = this.getTotalBills();
    const spent = this.customers.reduce((sum, c) => sum + c.totalSpent, 0);
    return bills > 0 ? spent / bills : 0;
  }

  getLoyalCustomers(): number {
    return this.customers.filter(c => !this.isWalkIn(c) && c.totalOrders >= 10).length;
  }

  exportCustomers(): void {
    if (this.customers.length === 0) {
      this.swal.toast('No customers to export', 'warning');
      return;
    }
    const header = 'Name,Mobile Number,Bills,Total Spent,Last Visit';
    const rows = this.customers.map(c => [
      `"${(c.name || '').replace(/"/g, '""')}"`,
      c.phone,
      c.totalOrders,
      c.totalSpent,
      c.lastOrderDate ? c.lastOrderDate.toISOString().split('T')[0] : ''
    ].join(','));
    const blob = new Blob([[header, ...rows].join('\n')], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `customers-${new Date().toISOString().split('T')[0]}.csv`;
    link.click();
    window.URL.revokeObjectURL(url);

    this.swal.toast('Customer list exported', 'success');
  }
}
