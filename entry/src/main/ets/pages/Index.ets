import { AuraLayer } from '../components/AuraLayer';
import { GalaxyCanvas } from '../components/GalaxyCanvas';
import { common } from '@kit.AbilityKit';
import { PhotoIndexDatabase } from '../services/PhotoIndexDatabase';
import { PhotoLibraryService, PhotoLibrarySnapshot } from '../services/PhotoLibraryService';
import { PhotoRecord } from '../models/PhotoRecord';

@Entry
@Component
struct Index {
  @State isHintVisible: boolean = true;
  @State libraryStatus: string = '尚未建立照片索引';
  @State isScanning: boolean = false;
  @State photos: PhotoRecord[] = [];
  @State selectedPhoto: PhotoRecord | null = null;

  onPageShow(): void {
    this.restorePhotoIndex();
  }

  private getHostContext(): common.UIAbilityContext {
    const hostContext: common.Context | undefined = this.getUIContext().getHostContext();
    if (hostContext === undefined) {
      throw new Error('无法获取应用上下文');
    }
    return hostContext as common.UIAbilityContext;
  }

  private async restorePhotoIndex(): Promise<void> {
    try {
      const context: common.UIAbilityContext = this.getHostContext();
      await PhotoIndexDatabase.initialize(context);
      this.photos = await PhotoIndexDatabase.loadPhotos(500);
      if (this.photos.length > 0) {
        this.libraryStatus = `已收藏 ${this.photos.length} 段时光 · 仅保存在本机`;
        this.isHintVisible = false;
      }
    } catch (error) {
      this.libraryStatus = '本地索引暂时不可用';
    }
  }

  private async scanPhotoLibrary(): Promise<void> {
    if (this.isScanning) {
      return;
    }
    this.isScanning = true;
    this.libraryStatus = '正在读取记忆…';
    try {
      const context: common.UIAbilityContext = this.getHostContext();
      const snapshot: PhotoLibrarySnapshot = await PhotoLibraryService.selectPhotos(500);
      await PhotoIndexDatabase.initialize(context);
      await PhotoIndexDatabase.upsertPhotos(snapshot.previewRecords);
      this.photos = await PhotoIndexDatabase.loadPhotos(500);
      this.libraryStatus = `已导入 ${snapshot.totalCount} 张 · 共收藏 ${this.photos.length} 张`;
      this.isHintVisible = false;
    } catch (error) {
      this.libraryStatus = error instanceof Error ? error.message : '照片读取失败，请稍后重试';
    } finally {
      this.isScanning = false;
    }
  }

  private async toggleFeatured(): Promise<void> {
    const photo: PhotoRecord | null = this.selectedPhoto;
    if (photo === null) {
      return;
    }
    const nextFeatured: boolean = !photo.featured;
    try {
      await PhotoIndexDatabase.setFeatured(photo.assetId, nextFeatured);
      const updated: PhotoRecord = photo.copyWithFeatured(nextFeatured);
      this.photos = this.photos.map((item: PhotoRecord) =>
        item.assetId === updated.assetId ? updated : item);
      this.selectedPhoto = updated;
    } catch (error) {
      this.libraryStatus = '收藏状态保存失败';
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      AuraLayer({ motionSpeed: 1, blurRadius: 34 })
      GalaxyCanvas({
        photos: this.photos,
        onPhotoSelected: (photo: PhotoRecord) => {
          this.selectedPhoto = photo;
        }
      })

      Column() {
        Row() {
          Column({ space: 2 }) {
            Text('拾光馆')
              .fontSize(24)
              .fontWeight(FontWeight.Medium)
              .fontColor('#F7F4FF')
              .letterSpacing(2)
            Text('PROJECT AURORA')
              .fontSize(9)
              .fontColor('rgba(232, 228, 255, 0.46)')
              .letterSpacing(2.2)
            Text(this.libraryStatus)
              .fontSize(10)
              .fontColor('rgba(232, 228, 255, 0.42)')
              .margin({ top: 5 })
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          Button(this.isScanning ? '…' : '＋')
            .width(42)
            .height(42)
            .fontSize(23)
            .fontColor('#F5F1FF')
            .backgroundColor('rgba(255, 255, 255, 0.10)')
            .borderWidth(1)
            .borderColor('rgba(255, 255, 255, 0.16)')
            .enabled(!this.isScanning)
            .onClick(() => {
              this.scanPhotoLibrary();
            })
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 18 })

        Blank()

        if (this.isHintVisible) {
          Row({ space: 9 }) {
            Text('✦')
              .fontSize(13)
              .fontColor('#DDD3FF')
            Text('双指缩放，漫游你的记忆宇宙')
              .fontSize(12)
              .fontColor('rgba(244, 242, 255, 0.68)')
          }
          .padding({ left: 16, right: 16, top: 10, bottom: 10 })
          .backgroundColor('rgba(13, 12, 31, 0.50)')
          .borderRadius(22)
          .borderWidth(1)
          .borderColor('rgba(255, 255, 255, 0.12)')
          .margin({ bottom: 22 })
          .onClick(() => {
            this.isHintVisible = false;
          })
        }

        Row() {
          this.NavigationItem('宇宙', true)
          this.NavigationItem('展厅', false)
          this.NavigationItem('珍藏', false)
        }
        .width('86%')
        .height(58)
        .padding(5)
        .backgroundColor('rgba(15, 14, 35, 0.72)')
        .borderRadius(30)
        .borderWidth(1)
        .borderColor('rgba(255, 255, 255, 0.13)')
        .backdropBlur(18)
        .margin({ bottom: 12 })
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
      .hitTestBehavior(HitTestMode.Transparent)

      if (this.selectedPhoto !== null) {
        this.ExhibitViewer(this.selectedPhoto)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#070713')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  ExhibitViewer(photo: PhotoRecord) {
    Stack({ alignContent: Alignment.Center }) {
      Image(photo.uri)
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Contain)

      Column() {
        Row() {
          Button('‹')
            .width(44)
            .height(44)
            .fontSize(30)
            .fontColor('#FFFFFF')
            .backgroundColor('rgba(12, 12, 24, 0.58)')
            .onClick(() => {
              this.selectedPhoto = null;
            })
          Blank()
          Button(photo.featured ? '★' : '☆')
            .width(44)
            .height(44)
            .fontSize(23)
            .fontColor(photo.featured ? '#FFE4A3' : '#FFFFFF')
            .backgroundColor('rgba(12, 12, 24, 0.58)')
            .onClick(() => {
              this.toggleFeatured();
            })
        }
        .width('100%')
        .padding({ left: 18, right: 18, top: 18 })

        Blank()

        Column({ space: 5 }) {
          Text(photo.featured ? '镇馆之宝' : '记忆展品')
            .fontSize(12)
            .fontColor(photo.featured ? '#FFE4A3' : 'rgba(255, 255, 255, 0.62)')
          Text(photo.displayName)
            .fontSize(15)
            .fontColor('#FFFFFF')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ left: 24, right: 24, top: 18, bottom: 24 })
        .backgroundColor('rgba(7, 7, 19, 0.62)')
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#05050B')
  }

  @Builder
  NavigationItem(label: string, selected: boolean) {
    Column({ space: 3 }) {
      Text(selected ? '✦' : '·')
        .fontSize(selected ? 15 : 18)
        .fontColor(selected ? '#F1E9FF' : 'rgba(255, 255, 255, 0.35)')
      Text(label)
        .fontSize(11)
        .fontWeight(selected ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(selected ? '#FFFFFF' : 'rgba(255, 255, 255, 0.48)')
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(selected ? 'rgba(130, 105, 255, 0.18)' : Color.Transparent)
    .borderRadius(24)
  }
}
