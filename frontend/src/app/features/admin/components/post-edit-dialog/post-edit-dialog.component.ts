import { Component, Inject, OnInit } from '@angular/core';
import { MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { FormBuilder, FormGroup } from '@angular/forms';

export interface PostEditDialogData {
  postType: 'labour' | 'travel' | 'parcel' | 'marketplace' | 'farmer' | 'realEstate';
  post: any;
}

interface FieldConfig {
  key: string;
  label: string;
  type: 'text' | 'textarea' | 'number' | 'select';
  options?: { value: string; label: string }[];
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
        { value: 'CAR', label: 'Car' },
        { value: 'SMALL_BUS', label: 'Small Bus' },
        { value: 'BUS', label: 'Bus' }
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
    ]
  };

  private titleMap: Record<string, string> = {
    labour: 'Edit Labour Post',
    travel: 'Edit Travel Post',
    parcel: 'Edit Parcel Service Post',
    marketplace: 'Edit Marketplace Post',
    farmer: 'Edit Farmer Product',
    realEstate: 'Edit Real Estate Post'
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
  }

  onSave(): void {
    if (this.form.valid) {
      const updates: Record<string, any> = {};
      this.fields.forEach(field => {
        const val = this.form.get(field.key)?.value;
        if (val !== this.data.post[field.key]) {
          updates[field.key] = val;
        }
      });
      if (Object.keys(updates).length > 0) {
        this.dialogRef.close(updates);
      } else {
        this.dialogRef.close();
      }
    }
  }

  onCancel(): void {
    this.dialogRef.close();
  }
}
