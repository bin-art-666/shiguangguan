export class StarPoint {
  id: number = 0;
  x: number = 0;
  y: number = 0;
  radius: number = 1;
  alpha: number = 1;
  color: string = '#FFFFFF';
  featured: boolean = false;

  constructor(id: number, x: number, y: number, radius: number, alpha: number,
    color: string, featured: boolean = false) {
    this.id = id;
    this.x = x;
    this.y = y;
    this.radius = radius;
    this.alpha = alpha;
    this.color = color;
    this.featured = featured;
  }
}

export class GalaxyCluster {
  year: number = 0;
  label: string = '';
  count: number = 0;
  x: number = 0;
  y: number = 0;

  constructor(year: number, label: string, count: number, x: number, y: number) {
    this.year = year;
    this.label = label;
    this.count = count;
    this.x = x;
    this.y = y;
  }
}
