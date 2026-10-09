import { Component, HostListener, Inject, OnInit } from '@angular/core';
import { MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { FormBuilder, FormGroup } from '@angular/forms';
import { CdkDragDrop, moveItemInArray } from '@angular/cdk/drag-drop';
import { getImageUrl } from '../../../../core/utils/image-url.util';

export type PostEditPostType = 'labour' | 'travel' | 'parcel' | 'marketplace' | 'farmer' | 'realEstate' | 'rental' | 'womensCorner';

export interface PostEditDialogData {
  postType: PostEditPostType;
  post: any;
}

/**
 * keepImageUrls is the FINAL ORDERED list of image slots. Each entry is either
 * an existing image URL (unchanged) or the token `NEW:<i>`, where <i> is the
 * zero-based index into newImages. The backend walks the list in order and
 * swaps every `NEW:<i>` for the uploaded URL of newImages[i]. With no tokens
 * present the behaviour is the old one (new files appended at the end).
 */
export interface MultiImageChanges {
  mode: 'multi';
  keepImageUrls: string[];
  newImages: File[];
}

export interface SingleImageChange {
  mode: 'single';
  removeExisting: boolean;
  newImage: File | null;
}

export interface PostEditDialogResult {
  fieldUpdates?: Record<string, any>;
  imageChanges?: MultiImageChanges | SingleImageChange;
}

interface FieldConfig {
  key: string;
  label: string;
  type: 'text' | 'textarea' | 'number' | 'select';
  options?: { value: string; label: string }[];
}

type ImageMode = 'multi' | 'single' | 'none';

/**
 * One tile in the multi-image grid. Existing and freshly picked images live in
 * the same ordered list so the admin can drag them among each other - the first
 * slot is the post thumbnail / profile photo.
 */
interface ImageSlot {
  kind: 'existing' | 'new';
  /** Existing: the stored image path. New: the preview object URL. */
  url: string;
  /** Only set for kind === 'new'. */
  file: File | null;
}

@Component({
  selector: 'app-post-edit-dialog',
  templateUrl: './post-edit-dialog.component.html',
  styleUrls: ['./post-edit-dialog.component.scss']
})
export class PostEditDialogComponent implements OnInit {
  form!: FormGroup;
  fields: FieldConfig[] = [];
  title = 'Edit Post';

  // Images (multi mode - labour/travel/parcel/farmer/realEstate/womensCorner/rental)
  imageMode: ImageMode = 'none';
  imageSlots: ImageSlot[] = [];

  // Images (single mode - marketplace)
  existingSingleImageUrl: string | null = null;
  singleImageRemoved = false;
  newSingleImageFile: File | null = null;
  newSingleImagePreview: string | null = null;

  private originalImageUrls: string[] = [];
  private originalSingleImageUrl: string | null = null;

  private fieldConfigs: Record<string, FieldConfig[]> = {
    labour: [
      { key: 'name', label: 'Name', type: 'text' },
      { key: 'phone', label: 'Phone', type: 'text' },
      { key: 'category', label: 'Category', type: 'select', options: [
        { value: 'PAINTER', label: 'Painter' },
        { value: 'CARPENTER', label: 'Carpenter' },
        { value: 'ELECTRICIAN', label: 'Electrician' },
        { value: 'PLUMBER', label: 'Plumber' },
        { value: 'CONTRACTOR', label: 'Contractor' },
        { value: 'MASON', label: 'Mason' },
        { value: 'DRIVER', label: 'Driver' },
        { value: 'WELDER', label: 'Welder' },
        { value: 'MECHANIC', label: 'Mechanic' },
        { value: 'TAILOR', label: 'Tailor' },
        { value: 'AC_TECHNICIAN', label: 'AC Technician' },
        { value: 'HELPER', label: 'Helper' },
        { value: 'BIKE_REPAIR', label: 'Bike Repair' },
        { value: 'CAR_REPAIR', label: 'Car Repair' },
        { value: 'TYRE_PUNCTURE', label: 'Tyre Puncture' },
        { value: 'GENERAL_LABOUR', label: 'General Labour' },
        { value: 'OTHER', label: 'Other' }
      ]},
      { key: 'experience', label: 'Experience', type: 'text' },
      { key: 'location', label: 'Location', type: 'text' },
      { key: 'description', label: 'Description', type: 'textarea' }
    ],
    travel: [
      { key: 'title', label: 'Title', type: 'text' },
      { key: 'phone', label: 'Phone', type: 'text' },
      { key: 'vehicleType', label: 'Vehicle Type', type: 'select', options: [
        { value: 'BUS', label: 'Bus' },
        { value: 'LORRY', label: 'Lorry' },
        { value: 'SMALL_BUS', label: 'Mini Bus' },
        { value: 'RENT', label: 'Rent' },
        { value: 'CAR', label: 'Car' },
        { value: 'PARCEL_SERVICE', label: 'Packers & Movers' }
      ]},
      { key: 'fromLocation', label: 'From Location', type: 'text' },
      { key: 'toLocation', label: 'To Location', type: 'text' },
      { key: 'price', label: 'Price', type: 'text' },
      { key: 'seatsAvailable', label: 'Seats Available', type: 'number' },
      { key: 'description', label: 'Description', type: 'textarea' }
    ],
    parcel: [
      { key: 'serviceName', label: 'Service Name', type: 'text' },
      { key: 'phone', label: 'Phone', type: 'text' },
      { key: 'serviceType', label: 'Service Type', type: 'select', options: [
        { value: 'DOOR_TO_DOOR', label: 'Door to Door' },
        { value: 'PICKUP_POINT', label: 'Pickup Point' },
        { value: 'BOTH', label: 'Both' }
      ]},
      { key: 'fromLocation', label: 'From Location', type: 'text' },
      { key: 'toLocation', label: 'To Location', type: 'text' },
      { key: 'priceInfo', label: 'Price Info', type: 'text' },
      { key: 'address', label: 'Address', type: 'text' },
      { key: 'timings', label: 'Timings', type: 'text' },
      { key: 'description', label: 'Description', type: 'textarea' }
    ],
    marketplace: [
      { key: 'title', label: 'Title', type: 'text' },
      { key: 'price', label: 'Price', type: 'number' },
      { key: 'category', label: 'Category', type: 'select', options: [
        { value: 'Electronics', label: 'Electronics' },
        { value: 'Furniture', label: 'Furniture' },
        { value: 'Vehicles', label: 'Vehicles' },
        { value: 'Agriculture', label: 'Agriculture' },
        { value: 'Clothing', label: 'Clothing' },
        { value: 'Food', label: 'Food' },
        { value: 'Finance', label: 'Finance' },
        { value: 'Other', label: 'Other' }
      ]},
      { key: 'location', label: 'Location', type: 'text' },
      { key: 'description', label: 'Description', type: 'textarea' }
    ],
    farmer: [
      { key: 'title', label: 'Title', type: 'text' },
      { key: 'price', label: 'Price', type: 'number' },
      { key: 'unit', label: 'Unit', type: 'text' },
      { key: 'category', label: 'Category', type: 'select', options: [
        { value: 'Vegetables', label: 'Vegetables' },
        { value: 'Fruits', label: 'Fruits' },
        { value: 'Grains & Pulses', label: 'Grains & Pulses' },
        { value: 'Dairy', label: 'Dairy' },
        { value: 'Spices', label: 'Spices' },
        { value: 'Flowers', label: 'Flowers' },
        { value: 'Organic', label: 'Organic' },
        { value: 'Seeds & Plants', label: 'Seeds & Plants' },
        { value: 'Honey & Jaggery', label: 'Honey & Jaggery' },
        { value: 'Other', label: 'Other' }
      ]},
      { key: 'location', label: 'Location', type: 'text' },
      { key: 'description', label: 'Description', type: 'textarea' }
    ],
    realEstate: [
      { key: 'title', label: 'Title', type: 'text' },
      { key: 'propertyType', label: 'Property Type', type: 'select', options: [
        { value: 'LAND', label: 'Land' },
        { value: 'HOUSE', label: 'House' },
        { value: 'APARTMENT', label: 'Apartment' },
        { value: 'VILLA', label: 'Villa' },
        { value: 'COMMERCIAL', label: 'Commercial' },
        { value: 'PLOT', label: 'Plot' },
        { value: 'FARM_LAND', label: 'Farm Land' },
        { value: 'PG_HOSTEL', label: 'PG/Hostel' }
      ]},
      { key: 'listingType', label: 'Listing Type', type: 'select', options: [
        { value: 'FOR_SALE', label: 'For Sale' },
        { value: 'FOR_RENT', label: 'For Rent' }
      ]},
      { key: 'price', label: 'Price', type: 'number' },
      { key: 'areaSqft', label: 'Area (sqft)', type: 'number' },
      { key: 'bedrooms', label: 'Bedrooms', type: 'number' },
      { key: 'bathrooms', label: 'Bathrooms', type: 'number' },
      { key: 'location', label: 'Location', type: 'text' },
      { key: 'description', label: 'Description', type: 'textarea' }
    ],
    rental: [
      { key: 'title', label: 'Title', type: 'text' },
      { key: 'category', label: 'Category', type: 'select', options: [
        { value: 'BIKE', label: 'Bike' }, { value: 'AUTO', label: 'Auto' }, { value: 'CAR', label: 'Car' },
        { value: 'SCOOTER', label: 'Scooter' }, { value: 'TRACTOR', label: 'Tractor' }, { value: 'LORRY', label: 'Lorry' },
        { value: 'VAN', label: 'Van' }, { value: 'CYCLE', label: 'Cycle' },
        { value: 'HOUSE', label: 'House' }, { value: 'SHOP', label: 'Shop' }, { value: 'LAND', label: 'Land' },
        { value: 'OFFICE', label: 'Office' }, { value: 'WAREHOUSE', label: 'Warehouse' }, { value: 'FARM_LAND', label: 'Farm Land' },
        { value: 'EQUIPMENT', label: 'Equipment' }, { value: 'FARM_EQUIPMENT', label: 'Farm Equipment' }, { value: 'GENERATOR', label: 'Generator' },
        { value: 'PUMP', label: 'Pump' }, { value: 'CRANE', label: 'Crane' }, { value: 'COMPRESSOR', label: 'Compressor' },
        { value: 'TENT', label: 'Tent' }, { value: 'CHAIRS', label: 'Chairs' }, { value: 'SOUND_SYSTEM', label: 'Sound System' }, { value: 'LIGHTS', label: 'Lights' },
        { value: 'CAMERA', label: 'Camera' }, { value: 'PROJECTOR', label: 'Projector' },
        { value: 'FURNITURE', label: 'Furniture' }
      ]},
      { key: 'location', label: 'Location', type: 'text' },
      { key: 'price', label: 'Price', type: 'number' },
      { key: 'priceUnit', label: 'Price Unit', type: 'text' },
      { key: 'description', label: 'Description', type: 'textarea' }
    ],
    womensCorner: [
      { key: 'title', label: 'Title', type: 'text' },
      { key: 'category', label: 'Category', type: 'text' },
      { key: 'price', label: 'Price', type: 'number' },
      { key: 'location', label: 'Location', type: 'text' },
      { key: 'description', label: 'Description', type: 'textarea' }
    ]
  };

  private titleMap: Record<string, string> = {
    labour: 'Edit Labour Post',
    travel: 'Edit Travel Post',
    parcel: 'Edit Packers & Movers Post',
    marketplace: 'Edit Marketplace Post',
    farmer: 'Edit Farmer Product',
    realEstate: 'Edit Real Estate Post',
    rental: 'Edit Rental Post',
    womensCorner: "Edit Women's Corner Post"
  };

  // Which post types support image editing, and how their images are stored.
  // Local Shops is deliberately left out - its edit dialog is untouched.
  private imageModeMap: Partial<Record<PostEditPostType, { mode: ImageMode; urlField: string }>> = {
    labour: { mode: 'multi', urlField: 'imageUrls' },
    travel: { mode: 'multi', urlField: 'imageUrls' },
    parcel: { mode: 'multi', urlField: 'imageUrls' },
    farmer: { mode: 'multi', urlField: 'imageUrls' },
    realEstate: { mode: 'multi', urlField: 'imageUrls' },
    rental: { mode: 'multi', urlField: 'imageUrls' },
    womensCorner: { mode: 'multi', urlField: 'imageUrls' },
    marketplace: { mode: 'single', urlField: 'imageUrl' }
  };

  constructor(
    private fb: FormBuilder,
    private dialogRef: MatDialogRef<PostEditDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: PostEditDialogData
  ) {}

  ngOnInit(): void {
    this.fields = this.fieldConfigs[this.data.postType] || [];
    this.title = this.titleMap[this.data.postType] || 'Edit Post';

    const formControls: Record<string, any> = {};
    this.fields.forEach(field => {
      formControls[field.key] = [this.data.post[field.key] ?? ''];
    });
    this.form = this.fb.group(formControls);

    const imageConfig = this.imageModeMap[this.data.postType];
    this.imageMode = imageConfig?.mode ?? 'none';

    if (this.imageMode === 'multi' && imageConfig) {
      const raw = (this.data.post[imageConfig.urlField] || '') as string;
      this.originalImageUrls = raw.split(',').map(u => u.trim()).filter(u => !!u);
      this.imageSlots = this.originalImageUrls.map(url => ({ kind: 'existing' as const, url, file: null }));
    } else if (this.imageMode === 'single' && imageConfig) {
      this.originalSingleImageUrl = (this.data.post[imageConfig.urlField] || null) || null;
      this.existingSingleImageUrl = this.originalSingleImageUrl;
    }
  }

  displayImageUrl(path: string): string {
    return getImageUrl(path);
  }

  /** Existing slots need the CDN/host prefix, new ones are already blob URLs. */
  slotImageUrl(slot: ImageSlot): string {
    return slot.kind === 'existing' ? getImageUrl(slot.url) : slot.url;
  }

  /** Drag-and-drop reorder of the merged image list. First slot = thumbnail. */
  onImageDrop(event: CdkDragDrop<ImageSlot[]>): void {
    if (event.previousIndex === event.currentIndex) return;
    moveItemInArray(this.imageSlots, event.previousIndex, event.currentIndex);
  }

  removeImageSlot(index: number): void {
    const slot = this.imageSlots[index];
    if (!slot) return;
    if (slot.kind === 'new') URL.revokeObjectURL(slot.url);
    this.imageSlots.splice(index, 1);
  }

  onFilesSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (!input.files || input.files.length === 0) return;
    this.addNewFiles(Array.from(input.files));
    input.value = '';
  }

  private addNewFiles(files: File[]): void {
    for (const file of files) {
      if (!file.type.startsWith('image/')) continue;
      if (this.imageMode === 'multi') {
        this.imageSlots.push({ kind: 'new', url: URL.createObjectURL(file), file });
      } else if (this.imageMode === 'single') {
        if (this.newSingleImagePreview) URL.revokeObjectURL(this.newSingleImagePreview);
        this.newSingleImageFile = file;
        this.newSingleImagePreview = URL.createObjectURL(file);
      }
    }
  }

  removeNewSingleImage(): void {
    if (this.newSingleImagePreview) URL.revokeObjectURL(this.newSingleImagePreview);
    this.newSingleImageFile = null;
    this.newSingleImagePreview = null;
  }

  removeSingleImage(): void {
    this.existingSingleImageUrl = null;
    this.singleImageRemoved = true;
  }

  // Lets an admin paste a screenshot/copied image straight from the
  // clipboard instead of having to save it to disk first and browse to it.
  @HostListener('document:paste', ['$event'])
  onPaste(event: ClipboardEvent): void {
    if (this.imageMode === 'none') return;
    const items = event.clipboardData?.items;
    if (!items) return;
    const files: File[] = [];
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      if (item.type.startsWith('image/')) {
        const file = item.getAsFile();
        if (file) files.push(file);
      }
    }
    if (files.length > 0) {
      event.preventDefault();
      this.addNewFiles(files);
    }
  }

  private hasImageChanges(): boolean {
    if (this.imageMode === 'multi') {
      // A new file is always a change. Otherwise compare the resulting order
      // against the original one, so a pure drag-and-drop reorder still saves.
      if (this.imageSlots.some(slot => slot.kind === 'new')) return true;
      if (this.imageSlots.length !== this.originalImageUrls.length) return true;
      return this.imageSlots.some((slot, i) => slot.url !== this.originalImageUrls[i]);
    }
    if (this.imageMode === 'single') {
      return !!this.newSingleImageFile || this.singleImageRemoved;
    }
    return false;
  }

  private buildImageChanges(): MultiImageChanges | SingleImageChange | undefined {
    if (!this.hasImageChanges()) return undefined;
    if (this.imageMode === 'multi') {
      // Walk the merged list once so the NEW:<i> tokens and the newImages array
      // are built from the same pass and can never drift apart.
      const keepImageUrls: string[] = [];
      const newImages: File[] = [];
      for (const slot of this.imageSlots) {
        if (slot.kind === 'new' && slot.file) {
          keepImageUrls.push(`NEW:${newImages.length}`);
          newImages.push(slot.file);
        } else {
          keepImageUrls.push(slot.url);
        }
      }
      return { mode: 'multi', keepImageUrls, newImages };
    }
    if (this.imageMode === 'single') {
      return {
        mode: 'single',
        removeExisting: this.singleImageRemoved,
        newImage: this.newSingleImageFile
      };
    }
    return undefined;
  }

  onSave(): void {
    if (!this.form.valid) return;

    const fieldUpdates: Record<string, any> = {};
    this.fields.forEach(field => {
      const val = this.form.get(field.key)?.value;
      if (val !== this.data.post[field.key]) {
        fieldUpdates[field.key] = val;
      }
    });

    const imageChanges = this.buildImageChanges();
    const result: PostEditDialogResult = {};
    if (Object.keys(fieldUpdates).length > 0) result.fieldUpdates = fieldUpdates;
    if (imageChanges) result.imageChanges = imageChanges;

    this.dialogRef.close((result.fieldUpdates || result.imageChanges) ? result : undefined);
  }

  onCancel(): void {
    this.dialogRef.close();
  }
}
