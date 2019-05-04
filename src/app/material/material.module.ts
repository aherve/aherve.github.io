import { NgModule } from '@angular/core';
import { MatToolbarModule, MatTabsModule, MatButtonModule, MatListModule, MatDialogModule } from '@angular/material'
import { MatIconModule } from '@angular/material/icon'

@NgModule({
  declarations: [],
  imports: [
    MatDialogModule,
    MatButtonModule,
    MatIconModule,
    MatListModule,
    MatTabsModule,
    MatToolbarModule,
  ],
  exports: [
    MatDialogModule,
    MatButtonModule,
    MatIconModule,
    MatListModule,
    MatTabsModule,
    MatToolbarModule,
  ]
})
export class MaterialModule { }
