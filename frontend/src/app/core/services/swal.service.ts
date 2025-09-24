import { Injectable } from '@angular/core';
import Swal, { SweetAlertResult, SweetAlertOptions } from 'sweetalert2';

@Injectable({
  providedIn: 'root'
})
export class SwalService {

  constructor() { }

  // Success alert
  success(title: string, text?: string): Promise<SweetAlertResult> {
    return Swal.fire({
      title: title,
      text: text,
      icon: 'success',
      confirmButtonText: 'OK',
      confirmButtonColor: '#667eea',
      timer: 3000,
      timerProgressBar: true
    });
  }

  // Error alert
  error(title: string, text?: string): Promise<SweetAlertResult> {
    return Swal.fire({
      title: title,
      text: text,
      icon: 'error',
      confirmButtonText: 'OK',
      confirmButtonColor: '#ef4444'
    });
  }

  // Warning alert
  warning(title: string, text?: string): Promise<SweetAlertResult> {
    return Swal.fire({
      title: title,
      text: text,
      icon: 'warning',
      confirmButtonText: 'OK',
      confirmButtonColor: '#f59e0b'
    });
  }

  // Info alert
  info(title: string, text?: string): Promise<SweetAlertResult> {
    return Swal.fire({
      title: title,
      text: text,
      icon: 'info',
      confirmButtonText: 'OK',
      confirmButtonColor: '#3b82f6'
    });
  }

  // Confirmation dialog
  confirm(title: string, text?: string, confirmButtonText: string = 'Yes', cancelButtonText: string = 'Cancel'): Promise<SweetAlertResult> {
    return Swal.fire({
      title: title,
      text: text,
      icon: 'question',
      showCancelButton: true,
      confirmButtonText: confirmButtonText,
      cancelButtonText: cancelButtonText,
      confirmButtonColor: '#667eea',
      cancelButtonColor: '#6b7280',
      reverseButtons: true
    });
  }

  // Delete confirmation
  confirmDelete(itemName?: string): Promise<SweetAlertResult> {
    return Swal.fire({
      title: 'Are you sure?',
      text: itemName ? `You are about to delete "${itemName}". This action cannot be undone!` : 'This action cannot be undone!',
      icon: 'warning',
      showCancelButton: true,
      confirmButtonText: 'Yes, delete it!',
      cancelButtonText: 'Cancel',
      confirmButtonColor: '#ef4444',
      cancelButtonColor: '#6b7280',
      reverseButtons: true
    });
  }

  // Loading/Processing alert
  loading(title: string = 'Processing...', text?: string): void {
    Swal.fire({
      title: title,
      text: text,
      allowOutsideClick: false,
      allowEscapeKey: false,
      showConfirmButton: false,
      didOpen: () => {
        Swal.showLoading();
      }
    });
  }

  // Close any open alert
  close(): void {
    Swal.close();
  }

  // Custom alert with all options
  custom(options: SweetAlertOptions): Promise<SweetAlertResult> {
    return Swal.fire(options);
  }

  // Toast notification
  toast(title: string, icon: 'success' | 'error' | 'warning' | 'info' = 'success'): void {
    const Toast = Swal.mixin({
      toast: true,
      position: 'top-end',
      showConfirmButton: false,
      timer: 3000,
      timerProgressBar: true,
      didOpen: (toast) => {
        toast.addEventListener('mouseenter', Swal.stopTimer);
        toast.addEventListener('mouseleave', Swal.resumeTimer);
      }
    });

    Toast.fire({
      icon: icon,
      title: title
    });
  }
}