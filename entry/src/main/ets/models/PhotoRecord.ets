export class PhotoRecord {
  assetId: string = '';
  uri: string = '';
  displayName: string = '';
  dateTaken: number = 0;
  width: number = 0;
  height: number = 0;
  layoutX: number = 0;
  layoutY: number = 0;
  layoutZ: number = 0;
  featured: boolean = false;
  layoutVersion: number = 1;

  constructor(assetId: string, uri: string, displayName: string, dateTaken: number) {
    this.assetId = assetId;
    this.uri = uri;
    this.displayName = displayName;
    this.dateTaken = dateTaken;
  }

  copyWithFeatured(featured: boolean): PhotoRecord {
    const copy: PhotoRecord = new PhotoRecord(this.assetId, this.uri, this.displayName, this.dateTaken);
    copy.width = this.width;
    copy.height = this.height;
    copy.layoutX = this.layoutX;
    copy.layoutY = this.layoutY;
    copy.layoutZ = this.layoutZ;
    copy.featured = featured;
    copy.layoutVersion = this.layoutVersion;
    return copy;
  }
}
