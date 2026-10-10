import { GalaxyCluster, StarPoint } from '../models/GalaxyModels';
import { GalaxySeedService } from '../services/GalaxySeedService';
import { PhotoRecord } from '../models/PhotoRecord';

@Component
export struct GalaxyCanvas {
  @Prop @Watch('onPhotosChanged') photos: PhotoRecord[] = [];
  onPhotoSelected: (photo: PhotoRecord) => void = (photo: PhotoRecord): void => {};
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private stars: StarPoint[] = GalaxySeedService.createPreviewStars(118);
  private clusters: GalaxyCluster[] = GalaxySeedService.createPreviewClusters();
  private isReady: boolean = false;
  @State private viewScale: number = 1;
  @State private offsetX: number = 0;
  @State private offsetY: number = 0;
  private panStartX: number = 0;
  private panStartY: number = 0;
  private pinchStartScale: number = 1;

  private onPhotosChanged(): void {
    this.redraw();
  }

  private redraw(): void {
    if (!this.isReady || this.context.width <= 0 || this.context.height <= 0) {
      return;
    }
    const width: number = this.context.width;
    const height: number = this.context.height;
    this.context.clearRect(0, 0, width, height);
    if (this.photos.length === 0) {
      this.drawConstellationLines(width, height);
      this.stars.forEach((star: StarPoint) => {
        this.drawStar(star, width, height);
      });
      this.clusters.forEach((cluster: GalaxyCluster) => {
        this.drawClusterLabel(cluster, width, height);
      });
    } else {
      this.photos.forEach((photo: PhotoRecord) => {
        this.drawPhotoAnchor(photo, width, height);
      });
    }
  }

  private screenX(normalizedX: number, width: number): number {
    return normalizedX * width;
  }

  private screenY(normalizedY: number, height: number): number {
    return normalizedY * height;
  }

  private drawConstellationLines(width: number, height: number): void {
    this.context.strokeStyle = 'rgba(210, 220, 255, 0.075)';
    this.context.lineWidth = 0.7;
    this.context.beginPath();
    for (let index: number = 1; index < this.stars.length; index += 9) {
      const previous: StarPoint = this.stars[index - 1];
      const current: StarPoint = this.stars[index];
      this.context.moveTo(this.screenX(previous.x, width), this.screenY(previous.y, height));
      this.context.lineTo(this.screenX(current.x, width), this.screenY(current.y, height));
    }
    this.context.stroke();
  }

  private drawStar(star: StarPoint, width: number, height: number): void {
    const x: number = this.screenX(star.x, width);
    const y: number = this.screenY(star.y, height);
    const radius: number = star.radius;

    if (x < -20 || x > width + 20 || y < -20 || y > height + 20) {
      return;
    }
    if (star.featured) {
      const halo: CanvasGradient = this.context.createRadialGradient(x, y, 0, x, y, radius * 5.5);
      halo.addColorStop(0, 'rgba(255, 235, 189, 0.52)');
      halo.addColorStop(1, 'rgba(255, 235, 189, 0)');
      this.context.fillStyle = halo;
      this.context.beginPath();
      this.context.arc(x, y, radius * 5.5, 0, Math.PI * 2);
      this.context.fill();
    }

    this.context.globalAlpha = star.alpha;
    this.context.fillStyle = star.color;
    this.context.beginPath();
    this.context.arc(x, y, radius, 0, Math.PI * 2);
    this.context.fill();
    this.context.globalAlpha = 1;
  }

  private drawPhotoAnchor(photo: PhotoRecord, width: number, height: number): void {
    const x: number = this.screenX(photo.layoutX, width);
    const y: number = this.screenY(photo.layoutY, height);
    const radius: number = photo.featured ? 5.5 : 2.2;
    if (photo.featured) {
      const halo: CanvasGradient = this.context.createRadialGradient(x, y, 0, x, y, 26);
      halo.addColorStop(0, 'rgba(255, 226, 164, 0.58)');
      halo.addColorStop(1, 'rgba(255, 226, 164, 0)');
      this.context.fillStyle = halo;
      this.context.beginPath();
      this.context.arc(x, y, 26, 0, Math.PI * 2);
      this.context.fill();
    }
    this.context.fillStyle = photo.featured ? '#FFF0C7' : 'rgba(225, 229, 255, 0.76)';
    this.context.beginPath();
    this.context.arc(x, y, radius, 0, Math.PI * 2);
    this.context.fill();
  }

  private visiblePhotos(): PhotoRecord[] {
    const limit: number = this.viewScale >= 1.8 ? 160 : this.viewScale >= 1.25 ? 96 : 48;
    return this.photos.slice(0, Math.min(limit, this.photos.length));
  }

  private drawClusterLabel(cluster: GalaxyCluster, width: number, height: number): void {
    const x: number = this.screenX(cluster.x, width);
    const y: number = this.screenY(cluster.y, height);
    this.context.textAlign = 'center';
    this.context.fillStyle = 'rgba(255, 255, 255, 0.88)';
    this.context.font = '500 15vp sans-serif';
    this.context.fillText(`${cluster.year}`, x, y);
    this.context.fillStyle = 'rgba(226, 228, 245, 0.5)';
    this.context.font = '11vp sans-serif';
    this.context.fillText(`${cluster.label} · ${cluster.count}`, x, y + 18);
  }

  build() {
    Stack() {
      Stack() {
        Canvas(this.context)
          .width('100%')
          .height('100%')
          .onReady(() => {
            this.isReady = true;
            this.redraw();
          })
          .hitTestBehavior(HitTestMode.None)

        ForEach(this.visiblePhotos(), (photo: PhotoRecord) => {
          Image(photo.uri)
            .width(photo.featured ? 48 : 38)
            .height(photo.featured ? 48 : 38)
            .objectFit(ImageFit.Cover)
            .borderRadius(24)
            .borderWidth(photo.featured ? 2 : 1)
            .borderColor(photo.featured ? '#FFE5A8' : 'rgba(255, 255, 255, 0.44)')
            .opacity(this.viewScale < 0.82 ? 0.35 : 0.94)
            .shadow({
              radius: photo.featured ? 18 : 8,
              color: photo.featured ? 'rgba(255, 211, 122, 0.55)' : 'rgba(128, 112, 255, 0.28)'
            })
            .position({ x: `${photo.layoutX * 100}%`, y: `${photo.layoutY * 100}%` })
            .translate({ x: photo.featured ? -24 : -19, y: photo.featured ? -24 : -19 })
            .onClick(() => {
              this.onPhotoSelected(photo);
            })
        }, (photo: PhotoRecord) => photo.assetId)
      }
      .width('100%')
      .height('100%')
      .scale({ x: this.viewScale, y: this.viewScale })
      .translate({ x: this.offsetX, y: this.offsetY })
    }
    .width('100%')
    .height('100%')
    .gesture(
      GestureGroup(GestureMode.Parallel,
        PanGesture()
          .onActionStart(() => {
            this.panStartX = this.offsetX;
            this.panStartY = this.offsetY;
          })
          .onActionUpdate((event: GestureEvent) => {
            this.offsetX = this.panStartX + event.offsetX;
            this.offsetY = this.panStartY + event.offsetY;
          }),
        PinchGesture()
          .onActionStart(() => {
            this.pinchStartScale = this.viewScale;
          })
          .onActionUpdate((event: GestureEvent) => {
            this.viewScale = Math.max(0.72, Math.min(2.8, this.pinchStartScale * event.scale));
          })
        )
    )
  }
}
