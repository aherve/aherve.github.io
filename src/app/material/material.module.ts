import { NgModule } from '@angular/core';
import { MatToolbarModule, MatTabsModule, MatButtonModule, MatListModule, MatDialogModule, MatMenuModule } from '@angular/material'
import { MatIconModule } from '@angular/material/icon'

@NgModule({
  declarations: [],
  imports: [
    MatMenuModule,
    MatDialogModule,
    MatButtonModule,
    MatIconModule,
    MatListModule,
    MatTabsModule,
    MatToolbarModule,
  ],
  exports: [
    MatMenuModule,
    MatDialogModule,
    MatButtonModule,
    MatIconModule,
    MatListModule,
    MatTabsModule,
    MatToolbarModule,
  ]
})
export class MaterialModule { }
