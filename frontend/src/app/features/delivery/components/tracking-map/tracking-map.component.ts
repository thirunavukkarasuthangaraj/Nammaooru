import { Component, Input, OnInit } from '@angular/core';

@Component({
  selector: 'app-tracking-map',
  templateUrl: './tracking-map.component.html',
  styleUrls: ['./tracking-map.component.scss']
})
export class TrackingMapComponent implements OnInit {
  @Input() partnerId?: number;
  @Input() orderId?: number;

  constructor() {}

  ngOnInit(): void {}
}