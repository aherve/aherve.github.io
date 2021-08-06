import { Component } from '@angular/core';
import { MatDialog } from '@angular/material/dialog';
import { ContactDialogComponent } from 'src/app/components/contact-dialog/contact-dialog.component';

@Component({
  selector: 'ah-nav',
  templateUrl: './nav.component.html',
  styleUrls: ['./nav.component.scss']
})
export class NavComponent {

  constructor(
    private dialog: MatDialog,
  ) { }

  public showEmail () {
    this.dialog.open(ContactDialogComponent)
  }

}
