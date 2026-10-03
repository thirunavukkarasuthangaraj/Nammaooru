import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatSelectModule } from '@angular/material/select';
import { MatTableModule } from '@angular/material/table';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { MatTooltipModule } from '@angular/material/tooltip';

import { TransporterGuard } from '../../core/guards/transporter.guard';
import { TransportLoginComponent } from './components/transport-login.component';
import { TransportHomeComponent } from './components/transport-home.component';
import { TransportLayoutComponent } from './components/transport-layout.component';
import { TransportLiveComponent } from './components/transport-live.component';
import { TransportVehiclesComponent } from './components/transport-vehicles.component';
import { TransportDriversComponent } from './components/transport-drivers.component';
import { TransportRoutesComponent } from './components/transport-routes.component';
import { TransportTripsComponent } from './components/transport-trips.component';
import { TransportTimetableComponent } from './components/transport-timetable.component';
import { TransportDashboardComponent } from './components/transport-dashboard.component';
import { TransportReportsComponent } from './components/transport-reports.component';
import { TransportProfileComponent } from './components/transport-profile.component';

/**
 * /transport = public home (live public buses), /transport/login, and the owner portal
 * /transport/{live,vehicles,drivers,routes,trips}.
 * Own layout and OTP login; not part of the admin shell.
 */
@NgModule({
  declarations: [
    TransportHomeComponent,
    TransportLoginComponent,
    TransportLayoutComponent,
    TransportLiveComponent,
    TransportVehiclesComponent,
    TransportDriversComponent,
    TransportRoutesComponent,
    TransportTripsComponent,
    TransportTimetableComponent,
    TransportDashboardComponent,
    TransportReportsComponent,
    TransportProfileComponent,
  ],
  imports: [
    CommonModule,
    FormsModule,
    MatButtonModule,
    MatIconModule,
    MatInputModule,
    MatFormFieldModule,
    MatSelectModule,
    MatTableModule,
    MatProgressSpinnerModule,
    MatSlideToggleModule,
    MatTooltipModule,
    RouterModule.forChild([
      // Public home: what the service is + live public buses. No login.
      { path: '', component: TransportHomeComponent, pathMatch: 'full' },
      { path: 'login', component: TransportLoginComponent },
      {
        path: '',
        component: TransportLayoutComponent,
        canActivate: [TransporterGuard],
        children: [
          { path: 'dashboard', component: TransportDashboardComponent },
          { path: 'live', component: TransportLiveComponent },
          { path: 'vehicles', component: TransportVehiclesComponent },
          { path: 'drivers', component: TransportDriversComponent },
          { path: 'routes', component: TransportRoutesComponent },
          { path: 'timetable', component: TransportTimetableComponent },
          { path: 'trips', component: TransportTripsComponent },
          { path: 'reports', component: TransportReportsComponent },
          { path: 'profile', component: TransportProfileComponent },
        ]
      },
      { path: '**', redirectTo: '' }
    ])
  ]
})
export class TransportPortalModule {}
