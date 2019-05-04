import { NgModule } from '@angular/core';
import { MatToolbarModule, MatTabsModule, MatButtonModule, MatListModule } from '@angular/material'
import { MatIconModule } from '@angular/material/icon'

@NgModule({
  declarations: [],
  imports: [
    MatButtonModule,
    MatIconModule,
    MatListModule,
    MatTabsModule,
    MatToolbarModule,
  ],
  exports: [
    MatButtonModule,
    MatIconModule,
    MatListModule,
    MatTabsModule,
    MatToolbarModule,
  ]
})
export class MaterialModule { }
