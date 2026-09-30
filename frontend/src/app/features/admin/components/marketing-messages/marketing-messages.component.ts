import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MarketingService, MarketingMessageResponse, TemplateInfo, MarketingStats } from '../../services/marketing.service';
import { SwalService } from '../../../../core/services/swal.service';

@Component({
  selector: 'app-marketing-messages',
  templateUrl: './marketing-messages.component.html',
  styleUrls: ['./marketing-messages.component.scss']
})
export class MarketingMessagesComponent implements OnInit {
  marketingForm!: FormGroup;
  templates: TemplateInfo[] = [];
  stats: MarketingStats | null = null;
  isLoading = false;
  isSending = false;
  lastResult: MarketingMessageResponse | null = null;

  targetAudienceOptions = [
    { value: 'ALL_CUSTOMERS', label: 'All Active Customers' }
  ];

  // Image upload (used by marketingmsg and shop_offer templates)
  selectedFile: File | null = null;
  imagePreview: string | null = null;
  uploadedImageUrl: string | null = null;
  uploading = false;

  constructor(
    private fb: FormBuilder,
    private marketingService: MarketingService,
    private swal: SwalService
  ) {
    this.initializeForm();
  }

  ngOnInit(): void {
    this.loadTemplates();
    this.loadStats();
  }

  private initializeForm(): void {
    this.marketingForm = this.fb.group({
      templateName: ['', Validators.required],
      messageParam: ['', [Validators.required, Validators.maxLength(500)]],
      messageParam2: [''], // Second parameter for templates that need it
      imageUrl: [''], // Image URL for templates with image headers
      targetAudience: ['ALL_CUSTOMERS', Validators.required]
    });

    // Watch for template changes to update field validators
    this.marketingForm.get('templateName')?.valueChanges.subscribe(templateName => {
      this.updateFormValidators(templateName);
    });
  }

  private updateFormValidators(templateName: string): void {
    const messageParam2Control = this.marketingForm.get('messageParam2');
    const imageUrlControl = this.marketingForm.get('imageUrl');

    // Reset validators
    messageParam2Control?.clearValidators();
    imageUrlControl?.clearValidators();

    // Add validators based on template
    if (templateName === 'marketingmsg') {
      // marketingmsg template requires image URL and 2 parameters
      imageUrlControl?.setValidators([Validators.required]);
      messageParam2Control?.setValidators([Validators.required, Validators.maxLength(500)]);
    } else if (templateName === 'shop_offer') {
      // shop_offer always needs a shop name; the image is optional — sendShopOffer
      // picks shop_offer_image automatically when one is uploaded.
      messageParam2Control?.setValidators([Validators.required, Validators.maxLength(500)]);
    }

    // Update validity
    messageParam2Control?.updateValueAndValidity();
    imageUrlControl?.updateValueAndValidity();

    // Clear any image left over from a previous template selection
    this.removeImage();
  }

  isMarketingMsgTemplate(): boolean {
    return this.marketingForm.get('templateName')?.value === 'marketingmsg';
  }

  isShopOfferTemplate(): boolean {
    return this.marketingForm.get('templateName')?.value === 'shop_offer';
  }

  usesImageUpload(): boolean {
    return this.isMarketingMsgTemplate() || this.isShopOfferTemplate();
  }

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (!input.files || !input.files[0]) return;
    const file = input.files[0];

    if (!file.type.startsWith('image/')) {
      this.swal.toast('Please select an image file', 'error');
      return;
    }
    if (file.size > 2 * 1024 * 1024) {
      this.swal.toast('Image size must be less than 2MB', 'error');
      return;
    }

    this.selectedFile = file;

    const reader = new FileReader();
    reader.onload = () => {
      this.imagePreview = reader.result as string;
    };
    reader.readAsDataURL(file);

    this.uploadImage(file);
  }

  uploadImage(file: File): void {
    this.uploading = true;
    this.marketingService.uploadMarketingImage(file).subscribe({
      next: (response) => {
        this.uploading = false;
        this.uploadedImageUrl = response.url;
        this.marketingForm.patchValue({ imageUrl: response.url });
        this.swal.toast('Image uploaded successfully', 'success');
      },
      error: (error) => {
        this.uploading = false;
        console.error('Image upload failed:', error);
        this.swal.toast('Failed to upload image', 'error');
        this.removeImage();
      }
    });
  }

  removeImage(): void {
    this.selectedFile = null;
    this.imagePreview = null;
    this.uploadedImageUrl = null;
    this.marketingForm.patchValue({ imageUrl: '' });
  }

  loadTemplates(): void {
    this.isLoading = true;
    this.marketingService.getAvailableTemplates().subscribe({
      next: (templates) => {
        this.templates = templates;
        this.isLoading = false;

        // Set default template if available
        if (templates.length > 0) {
          this.marketingForm.patchValue({
            templateName: templates[0].templateName
          });
        }
      },
      error: (error) => {
        console.error('Error loading templates:', error);
        this.swal.toast('Failed to load templates', 'error');
        this.isLoading = false;
      }
    });
  }

  loadStats(): void {
    this.marketingService.getMarketingStats().subscribe({
      next: (stats) => {
        this.stats = stats;
      },
      error: (error) => {
        console.error('Error loading stats:', error);
      }
    });
  }

  getSelectedTemplate(): TemplateInfo | undefined {
    const templateName = this.marketingForm.get('templateName')?.value;
    return this.templates.find(t => t.templateName === templateName);
  }

  onSendMessages(): void {
    if (this.marketingForm.invalid) {
      this.swal.toast('Please fill in all required fields', 'warning');
      return;
    }

    if (this.uploading) {
      this.swal.toast('Please wait for the image upload to complete', 'warning');
      return;
    }

    const formValue = this.marketingForm.value;
    const eligibleCount = this.stats?.eligibleForMarketing || 0;

    // Confirmation dialog
    const confirmed = confirm(
      `Are you sure you want to send marketing messages to ${eligibleCount} customers?\n\n` +
      `Template: ${this.getSelectedTemplate()?.displayName}\n` +
      `Message: ${formValue.messageParam}\n\n` +
      `This action cannot be undone.`
    );

    if (!confirmed) {
      return;
    }

    this.isSending = true;
    this.lastResult = null;

    this.marketingService.sendBulkMarketingMessage(formValue).subscribe({
      next: (response) => {
        this.isSending = false;
        this.lastResult = response;

        if (response.success) {
          this.swal.toast(`Successfully sent ${response.successCount} messages!`, 'success');

          // Reset form after successful send
          this.marketingForm.patchValue({
            messageParam: '',
            messageParam2: ''
          });
          this.removeImage();

          // Reload stats
          this.loadStats();
        } else {
          this.swal.toast(`Failed to send messages: ${response.message}`, 'error');
        }
      },
      error: (error) => {
        console.error('Error sending marketing messages:', error);
        this.isSending = false;

        this.swal.toast('Failed to send marketing messages. Please try again.', 'error');
      }
    });
  }

  getSuccessRate(): number {
    if (!this.lastResult || this.lastResult.totalCustomers === 0) {
      return 0;
    }
    return (this.lastResult.successCount / this.lastResult.totalCustomers) * 100;
  }

  onReset(): void {
    this.marketingForm.reset({
      templateName: this.templates.length > 0 ? this.templates[0].templateName : '',
      targetAudience: 'ALL_CUSTOMERS'
    });
    this.removeImage();
    this.lastResult = null;
  }
}
