import { Component } from '@angular/core';

@Component({
  selector: 'ah-root',
  template: `
<ah-nav></ah-nav>
<ah-layout>
  <router-outlet></router-outlet>
</ah-layout>
  `,
  styles: []
})
export class AppComponent { }
