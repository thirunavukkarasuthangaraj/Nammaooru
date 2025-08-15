import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';

// Angular Material
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';

// import { LocationPickerComponent } from './components/location-picker/location-picker.component'; // Disabled - Google Maps issues
import { UnauthorizedComponent } from './components/unauthorized/unauthorized.component';
import { TimeAgoPipe } from './pipes/time-ago.pipe';

@NgModule({
  declarations: [
    // LocationPickerComponent, // Disabled - Google Maps issues
    UnauthorizedComponent,
    TimeAgoPipe
  ],
  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterModule,
    
    // Angular Material
    MatProgressSpinnerModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatFormFieldModule,
    MatInputModule
  ],
  exports: [
    // LocationPickerComponent, // Disabled - Google Maps issues
    UnauthorizedComponent,
    TimeAgoPipe
  ]
})
export class SharedModule { }