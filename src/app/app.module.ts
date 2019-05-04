import { BrowserModule } from '@angular/platform-browser';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { NgModule } from '@angular/core';

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { HomeComponent } from './components/home/home.component';
import { CommonModule } from '@angular/common';
import { NavComponent } from './components/nav/nav.component';
import { MaterialModule } from 'src/app/material/material.module';
import { FlexLayoutModule } from '@angular/flex-layout';
import { ResearchComponent } from './components/research/research.component';
import { BlogComponent } from './components/blog/blog.component';
import { LayoutComponent } from './components/layout/layout.component';
import { ExternalLinkComponent } from './components/external-link/external-link.component';
import { FooterComponent } from './components/footer/footer.component';
import { ContactDialogComponent } from './components/contact-dialog/contact-dialog.component';

@NgModule({
  declarations: [
    AppComponent,
    HomeComponent,
    NavComponent,
    ResearchComponent,
    BlogComponent,
    LayoutComponent,
    ExternalLinkComponent,
    FooterComponent,
    ContactDialogComponent
  ],
  imports: [
    FlexLayoutModule,
    AppRoutingModule,
    BrowserAnimationsModule,
    BrowserModule,
    CommonModule,
    MaterialModule,
  ],
  providers: [],
  bootstrap: [AppComponent],
  entryComponents: [
    ContactDialogComponent,
  ]
  
})
export class AppModule { }
