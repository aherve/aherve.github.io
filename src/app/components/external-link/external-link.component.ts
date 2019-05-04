import { Component, Input } from '@angular/core';

@Component({
  selector: 'ah-external-link',
  templateUrl: './external-link.component.html',
  styleUrls: ['./external-link.component.scss']
})
export class ExternalLinkComponent {
  @Input() public url: string

  constructor() { }

}
