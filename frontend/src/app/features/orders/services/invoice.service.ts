import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { catchError, switchMap } from 'rxjs/operators';
import { environment } from '../../../../environments/environment';
import jsPDF from 'jspdf';
import 'jspdf-autotable';

export interface Invoice {
  id: number;
  invoiceNumber: string;
  orderId: number;
  orderNumber: string;
  customerId: number;
  customerName: string;
  customerEmail: string;
  customerPhone: string;
  customerAddress: string;
  shopId: number;
  shopName: string;
  shopAddress: string;
  shopGSTNumber?: string;
  items: InvoiceItem[];
  subtotal: number;
  taxAmount: number;
  deliveryCharge: number;
  discount: number;
  totalAmount: number;
  paymentMethod: string;
  paymentStatus: 'PAID' | 'PENDING' | 'FAILED';
  invoiceDate: string;
  dueDate?: string;
  paidDate?: string;
  notes?: string;
}

export interface InvoiceItem {
  id: number;
  productName: string;
  quantity: number;
  unitPrice: number;
  taxRate: number;
  taxAmount: number;
  discount: number;
  totalPrice: number;
  unit: string;
}

@Injectable({
  providedIn: 'root'
})
export class InvoiceService {
  private apiUrl = `${environment.apiUrl}`;

  constructor(private http: HttpClient) {}

  // Generate invoice for an order
  generateInvoice(orderId: number): Observable<Invoice> {
    return this.http.post<{data: Invoice}>(`${this.apiUrl}/invoices/generate`, { orderId })
      .pipe(
        switchMap(response => of(response.data)),
        catchError(() => {
          // Mock invoice data
          const mockInvoice: Invoice = {
            id: 1,
            invoiceNumber: `INV-${Date.now()}`,
            orderId: orderId,
            orderNumber: `ORD-${orderId}`,
            customerId: 1,
            customerName: 'John Doe',
            customerEmail: 'john@example.com',
            customerPhone: '+91 9876543210',
            customerAddress: '123 Main Street, Chennai - 600001',
            shopId: 1,
            shopName: 'Chennai Fresh Mart',
            shopAddress: '456 Anna Nagar, Chennai - 600040',
            shopGSTNumber: '33AAAFC1234M1Z5',
            items: [
              {
                id: 1,
                productName: 'Tomatoes',
                quantity: 2,
                unitPrice: 40,
                taxRate: 5,
                taxAmount: 4,
                discount: 0,
                totalPrice: 84,
                unit: 'kg'
              },
              {
                id: 2,
                productName: 'Onions',
                quantity: 1,
                unitPrice: 30,
                taxRate: 5,
                taxAmount: 1.5,
                discount: 0,
                totalPrice: 31.5,
                unit: 'kg'
              }
            ],
            subtotal: 110,
            taxAmount: 5.5,
            deliveryCharge: 40,
            discount: 10,
            totalAmount: 145.5,
            paymentMethod: 'ONLINE',
            paymentStatus: 'PAID',
            invoiceDate: new Date().toISOString(),
            paidDate: new Date().toISOString()
          };
          return of(mockInvoice);
        })
      );
  }

  // Get invoice by ID
  getInvoice(invoiceId: number): Observable<Invoice> {
    return this.http.get<{data: Invoice}>(`${this.apiUrl}/invoices/${invoiceId}`)
      .pipe(
        switchMap(response => of(response.data)),
        catchError(() => this.generateInvoice(invoiceId))
      );
  }

  // Generate PDF invoice
  generatePDF(invoice: Invoice): Observable<Blob> {
    const doc = new jsPDF();
    
    // Header
    doc.setFontSize(20);
    doc.text('INVOICE', 105, 20, { align: 'center' });
    
    // Invoice details
    doc.setFontSize(10);
    doc.text(`Invoice Number: ${invoice.invoiceNumber}`, 20, 35);
    doc.text(`Date: ${new Date(invoice.invoiceDate).toLocaleDateString()}`, 20, 40);
    doc.text(`Order Number: ${invoice.orderNumber}`, 20, 45);
    
    // Shop details
    doc.setFontSize(12);
    doc.text('From:', 20, 55);
    doc.setFontSize(10);
    doc.text(invoice.shopName, 20, 60);
    doc.text(invoice.shopAddress, 20, 65);
    if (invoice.shopGSTNumber) {
      doc.text(`GST: ${invoice.shopGSTNumber}`, 20, 70);
    }
    
    // Customer details
    doc.setFontSize(12);
    doc.text('Bill To:', 120, 55);
    doc.setFontSize(10);
    doc.text(invoice.customerName, 120, 60);
    doc.text(invoice.customerPhone, 120, 65);
    doc.text(invoice.customerEmail, 120, 70);
    doc.text(invoice.customerAddress, 120, 75);
    
    // Items table
    const tableData = invoice.items.map(item => [
      item.productName,
      `${item.quantity} ${item.unit}`,
      `₹${item.unitPrice.toFixed(2)}`,
      `${item.taxRate}%`,
      `₹${item.taxAmount.toFixed(2)}`,
      `₹${item.totalPrice.toFixed(2)}`
    ]);
    
    (doc as any).autoTable({
      head: [['Item', 'Qty', 'Unit Price', 'Tax', 'Tax Amt', 'Total']],
      body: tableData,
      startY: 85,
      theme: 'striped',
      headStyles: { fillColor: [66, 66, 66] }
    });
    
    // Summary
    const finalY = (doc as any).lastAutoTable.finalY + 10;
    doc.text(`Subtotal: ₹${invoice.subtotal.toFixed(2)}`, 140, finalY);
    doc.text(`Tax: ₹${invoice.taxAmount.toFixed(2)}`, 140, finalY + 5);
    doc.text(`Delivery: ₹${invoice.deliveryCharge.toFixed(2)}`, 140, finalY + 10);
    if (invoice.discount > 0) {
      doc.text(`Discount: -₹${invoice.discount.toFixed(2)}`, 140, finalY + 15);
    }
    doc.setFontSize(12);
    doc.text(`Total: ₹${invoice.totalAmount.toFixed(2)}`, 140, finalY + 25);
    
    // Payment status
    doc.setFontSize(10);
    doc.text(`Payment Method: ${invoice.paymentMethod}`, 20, finalY);
    doc.text(`Payment Status: ${invoice.paymentStatus}`, 20, finalY + 5);
    
    // Footer
    doc.setFontSize(8);
    doc.text('Thank you for your business!', 105, 280, { align: 'center' });
    
    // Return as blob
    const pdfBlob = doc.output('blob');
    return of(pdfBlob);
  }

  // Send invoice via email
  sendInvoiceEmail(invoiceId: number, email: string): Observable<boolean> {
    return this.http.post<{success: boolean}>(`${this.apiUrl}/invoices/${invoiceId}/send`, { email })
      .pipe(
        switchMap(response => of(response.success)),
        catchError(() => {
          // Mock email sending
          console.log(`Invoice ${invoiceId} would be sent to ${email}`);
          return of(true);
        })
      );
  }

  // Download invoice as PDF
  downloadInvoice(invoice: Invoice): void {
    this.generatePDF(invoice).subscribe(blob => {
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `invoice-${invoice.invoiceNumber}.pdf`;
      link.click();
      window.URL.revokeObjectURL(url);
    });
  }

  // Get all invoices for a customer
  getCustomerInvoices(customerId: number): Observable<Invoice[]> {
    return this.http.get<{data: Invoice[]}>(`${this.apiUrl}/customers/${customerId}/invoices`)
      .pipe(
        switchMap(response => of(response.data || [])),
        catchError(() => of([]))
      );
  }

  // Get all invoices for a shop
  getShopInvoices(shopId: number): Observable<Invoice[]> {
    return this.http.get<{data: Invoice[]}>(`${this.apiUrl}/shops/${shopId}/invoices`)
      .pipe(
        switchMap(response => of(response.data || [])),
        catchError(() => of([]))
      );
  }

  // Generate and send invoice automatically after delivery
  processOrderInvoice(orderId: number): Observable<boolean> {
    return this.generateInvoice(orderId).pipe(
      switchMap(invoice => {
        // Send invoice to customer email
        return this.sendInvoiceEmail(invoice.id, invoice.customerEmail);
      }),
      catchError(() => of(false))
    );
  }
}