import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MatSnackBar } from '@angular/material/snack-bar';
import { PostLimitsService, UserPostLimit } from '../../services/post-limits.service';

@Component({
  selector: 'app-post-limits',
  templateUrl: './post-limits.component.html',
  styleUrls: ['./post-limits.component.scss']
})
export class PostLimitsComponent implements OnInit {
  limits: UserPostLimit[] = [];
  isLoading = true;
  showForm = false;
  limitForm!: FormGroup;

  featureNames = [
    { value: 'PARCEL_SERVICE', label: 'Parcel Service' },
    { value: 'MARKETPLACE', label: 'Marketplace' },
    { value: 'LABOURS', label: 'Labours' },
    { value: 'FARM_PRODUCTS', label: 'Farm Products' },
    { value: 'TRAVELS', label: 'Travels' }
  ];

  displayedColumns: string[] = ['userId', 'featureName', 'maxPosts', 'createdAt', 'actions'];

  constructor(
    private postLimitsService: PostLimitsService,
    private fb: FormBuilder,
    private snackBar: MatSnackBar
  ) {}

  ngOnInit(): void {
    this.initForm();
    this.loadLimits();
  }

  initForm(): void {
    this.limitForm = this.fb.group({
      userId: [null, [Validators.required, Validators.min(1)]],
      featureName: ['', Validators.required],
      maxPosts: [5, [Validators.required, Validators.min(0)]]
    });
  }

  loadLimits(): void {
    this.isLoading = true;
    this.postLimitsService.getAllLimits().subscribe({
      next: (response: any) => {
        this.limits = response.data || [];
        this.isLoading = false;
      },
      error: () => {
        this.snackBar.open('Failed to load post limits', 'Close', { duration: 3000 });
        this.isLoading = false;
      }
    });
  }

  openAddForm(): void {
    this.limitForm.reset({ maxPosts: 5 });
    this.showForm = true;
  }

  cancelForm(): void {
    this.showForm = false;
  }

  saveLimit(): void {
    if (this.limitForm.invalid) return;

    const limit: UserPostLimit = this.limitForm.value;
    this.postLimitsService.createOrUpdate(limit).subscribe({
      next: () => {
        this.snackBar.open('Post limit saved successfully', 'Close', { duration: 3000 });
        this.showForm = false;
        this.loadLimits();
      },
      error: () => this.snackBar.open('Failed to save post limit', 'Close', { duration: 3000 })
    });
  }

  deleteLimit(limit: UserPostLimit): void {
    if (!confirm(`Delete post limit for user ${limit.userId} on ${limit.featureName}?`)) return;

    this.postLimitsService.deleteLimit(limit.id!).subscribe({
      next: () => {
        this.snackBar.open('Post limit deleted', 'Close', { duration: 3000 });
        this.loadLimits();
      },
      error: () => this.snackBar.open('Failed to delete post limit', 'Close', { duration: 3000 })
    });
  }

  getFeatureLabel(featureName: string): string {
    const feature = this.featureNames.find(f => f.value === featureName);
    return feature ? feature.label : featureName;
  }
}
