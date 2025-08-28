import { Component, EventEmitter, Output, ViewChild, ElementRef } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../../../environments/environment';
import { MatSnackBar } from '@angular/material/snack-bar';

@Component({
  selector: 'app-barcode-scanner',
  templateUrl: './barcode-scanner.component.html',
  styleUrls: ['./barcode-scanner.component.scss']
})
export class BarcodeScannerComponent {
  @Output() productFound = new EventEmitter<any>();
  @ViewChild('barcodeInput') barcodeInput!: ElementRef;
  
  isScanning = false;
  barcodeValue = '';
  lastScannedCode = '';
  scannerBuffer = '';
  lastKeyTime = 0;
  
  // For camera scanning (if using ZXing)
  availableDevices: MediaDeviceInfo[] = [];
  currentDevice?: MediaDeviceInfo;
  hasPermission = false;
  
  private apiUrl = environment.apiUrl;

  constructor(
    private http: HttpClient,
    private snackBar: MatSnackBar
  ) {
    this.setupBarcodeListener();
  }

  // Listen for USB/Bluetooth scanner input
  private setupBarcodeListener(): void {
    document.addEventListener('keypress', (event: KeyboardEvent) => {
      const currentTime = Date.now();
      
      // Barcode scanners type very fast (< 50ms between keystrokes)
      if (currentTime - this.lastKeyTime < 50) {
        this.scannerBuffer += event.key;
      } else {
        this.scannerBuffer = event.key;
      }
      
      this.lastKeyTime = currentTime;
      
      // Most scanners send Enter after barcode
      if (event.key === 'Enter' && this.scannerBuffer.length > 0) {
        this.processBarcode(this.scannerBuffer.replace('Enter', ''));
        this.scannerBuffer = '';
      }
    });
  }

  // Manual barcode input
  onManualBarcodeSubmit(): void {
    if (this.barcodeValue.trim()) {
      this.processBarcode(this.barcodeValue.trim());
    }
  }

  // Process scanned or entered barcode
  private processBarcode(barcode: string): void {
    if (barcode === this.lastScannedCode) {
      this.snackBar.open('Product already scanned', 'Close', { duration: 2000 });
      return;
    }

    this.lastScannedCode = barcode;
    console.log('Processing barcode:', barcode);
    
    // Search product by barcode
    this.searchProductByBarcode(barcode);
  }

  // Search product in database
  private searchProductByBarcode(barcode: string): void {
    // First try shop products
    this.http.get<any>(`${this.apiUrl}/shop-products/barcode/${barcode}`)
      .subscribe({
        next: (product) => {
          this.handleProductFound(product);
        },
        error: (error) => {
          // If not found in shop, try master products
          this.searchMasterProductByBarcode(barcode);
        }
      });
  }

  private searchMasterProductByBarcode(barcode: string): void {
    this.http.get<any>(`${this.apiUrl}/products/barcode/${barcode}`)
      .subscribe({
        next: (product) => {
          this.handleProductFound(product);
        },
        error: (error) => {
          this.snackBar.open('Product not found', 'Close', { duration: 3000 });
          this.playErrorSound();
        }
      });
  }

  private handleProductFound(product: any): void {
    console.log('Product found:', product);
    this.productFound.emit(product);
    this.playSuccessSound();
    
    // Show product details
    this.snackBar.open(
      `Found: ${product.name} - ₹${product.price}`, 
      'Add to Cart', 
      { duration: 5000 }
    ).onAction().subscribe(() => {
      // Add to cart or order
      this.addToCurrentOrder(product);
    });
    
    // Clear input for next scan
    this.barcodeValue = '';
    if (this.barcodeInput) {
      this.barcodeInput.nativeElement.focus();
    }
  }

  private addToCurrentOrder(product: any): void {
    // Implement add to order logic
    console.log('Adding to order:', product);
  }

  // Sound feedback
  private playSuccessSound(): void {
    const audio = new Audio('assets/sounds/beep-success.mp3');
    audio.play().catch(e => console.log('Could not play sound'));
  }

  private playErrorSound(): void {
    const audio = new Audio('assets/sounds/beep-error.mp3');
    audio.play().catch(e => console.log('Could not play sound'));
  }

  // Camera scanning methods (if implementing)
  onCamerasFound(devices: MediaDeviceInfo[]): void {
    this.availableDevices = devices;
    if (devices && devices.length > 0) {
      this.currentDevice = devices[0];
    }
  }

  onCodeResult(resultString: string): void {
    this.processBarcode(resultString);
  }

  // Generate sample barcodes for testing
  generateTestBarcodes(): void {
    const testBarcodes = [
      { code: '1234567890123', name: 'Samsung Galaxy S24' },
      { code: '2345678901234', name: 'Nike Air Max 270' },
      { code: '3456789012345', name: 'Organic Green Tea' },
      { code: '5678901234567', name: "Levi's Jeans 501" },
      { code: '6789012345678', name: 'Coffee Beans Arabica' }
    ];
    
    console.log('Test Barcodes:', testBarcodes);
    this.snackBar.open('Check console for test barcodes', 'Close', { duration: 3000 });
  }
}