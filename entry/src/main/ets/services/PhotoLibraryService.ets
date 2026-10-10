import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { PhotoRecord } from '../models/PhotoRecord';

export class PhotoLibrarySnapshot {
  totalCount: number = 0;
  previewRecords: PhotoRecord[] = [];

  constructor(totalCount: number, previewRecords: PhotoRecord[]) {
    this.totalCount = totalCount;
    this.previewRecords = previewRecords;
  }
}

export class PhotoLibraryService {
  static async selectPhotos(maxSelectNumber: number = 500): Promise<PhotoLibrarySnapshot> {
    const options: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = Math.max(1, Math.min(500, maxSelectNumber));
    options.isSearchSupported = true;

    const picker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
    let result: photoAccessHelper.PhotoSelectResult;
    try {
      result = await picker.select(options);
    } catch (error) {
      throw new Error('未能打开照片选择器');
    }
    const records: PhotoRecord[] = result.photoUris.map((uri: string, index: number) => {
      const displayName: string = PhotoLibraryService.getDisplayName(uri);
      const record: PhotoRecord = new PhotoRecord(uri, uri, displayName, Date.now() - index);
      record.layoutX = 0.5 + Math.cos(index * 2.399963) * 0.4 * Math.sqrt((index + 1) / result.photoUris.length);
      record.layoutY = 0.5 + Math.sin(index * 2.399963) * 0.4 * Math.sqrt((index + 1) / result.photoUris.length);
      return record;
    });
    return new PhotoLibrarySnapshot(records.length, records);
  }

  private static getDisplayName(uri: string): string {
    const separatorIndex: number = uri.lastIndexOf('/');
    if (separatorIndex < 0 || separatorIndex >= uri.length - 1) {
      return '未命名照片';
    }
    return uri.substring(separatorIndex + 1);
  }
}
