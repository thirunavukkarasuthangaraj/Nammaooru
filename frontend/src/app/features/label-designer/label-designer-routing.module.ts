import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { LabelDesignerComponent } from './components/label-designer/label-designer.component';

const routes: Routes = [
  { path: '', component: LabelDesignerComponent, data: { title: 'Barcode Label Designer' } }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class LabelDesignerRoutingModule {}
