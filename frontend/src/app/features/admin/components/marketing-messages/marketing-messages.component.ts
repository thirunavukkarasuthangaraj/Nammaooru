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
    }

    // Update validity
    messageParam2Control?.updateValueAndValidity();
    imageUrlControl?.updateValueAndValidity();
  }

  isMarketingMsgTemplate(): boolean {
    return this.marketingForm.get('templateName')?.value === 'marketingmsg';
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
            messageParam: ''
          });

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
    this.lastResult = null;
  }
}
