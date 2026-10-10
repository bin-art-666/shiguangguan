import { Context } from '@kit.AbilityKit';
import { relationalStore, ValueType } from '@kit.ArkData';
import { PhotoRecord } from '../models/PhotoRecord';

export class PhotoIndexDatabase {
  private static store: relationalStore.RdbStore | null = null;
  private static readonly DATABASE_NAME: string = 'aurora_index.db';

  static async initialize(context: Context): Promise<void> {
    if (PhotoIndexDatabase.store !== null) {
      return;
    }
    const config: relationalStore.StoreConfig = {
      name: PhotoIndexDatabase.DATABASE_NAME,
      securityLevel: relationalStore.SecurityLevel.S1,
      encrypt: false
    };
    try {
      PhotoIndexDatabase.store = await relationalStore.getRdbStore(context, config);
      await PhotoIndexDatabase.store.executeSql(
        'CREATE TABLE IF NOT EXISTS photos (' +
        'asset_id TEXT PRIMARY KEY, uri TEXT NOT NULL, display_name TEXT NOT NULL, ' +
        'date_taken INTEGER NOT NULL, width INTEGER NOT NULL, height INTEGER NOT NULL, ' +
        'layout_x REAL NOT NULL DEFAULT 0, layout_y REAL NOT NULL DEFAULT 0, ' +
        'layout_z REAL NOT NULL DEFAULT 0, featured INTEGER NOT NULL DEFAULT 0, ' +
        'layout_version INTEGER NOT NULL DEFAULT 1, indexed_at INTEGER NOT NULL)'
      );
      await PhotoIndexDatabase.store.executeSql(
        'CREATE INDEX IF NOT EXISTS idx_photos_date_taken ON photos(date_taken DESC)'
      );
      await PhotoIndexDatabase.store.executeSql(
        'CREATE INDEX IF NOT EXISTS idx_photos_featured ON photos(featured)'
      );
    } catch (error) {
      PhotoIndexDatabase.store = null;
      throw new Error('无法初始化本地照片索引');
    }
  }

  static async upsertPhotos(records: PhotoRecord[]): Promise<void> {
    const store: relationalStore.RdbStore | null = PhotoIndexDatabase.store;
    if (store === null) {
      throw new Error('照片索引数据库尚未初始化');
    }
    try {
      const indexedAt: number = Date.now();
      await store.executeSql('BEGIN TRANSACTION');
      for (const record of records) {
        const args: ValueType[] = [
          record.assetId,
          record.uri,
          record.displayName,
          record.dateTaken,
          record.width,
          record.height,
          record.layoutX,
          record.layoutY,
          record.layoutZ,
          record.featured ? 1 : 0,
          record.layoutVersion,
          indexedAt
        ];
        await store.executeSql(
          'INSERT OR REPLACE INTO photos (' +
          'asset_id, uri, display_name, date_taken, width, height, layout_x, layout_y, layout_z, ' +
          'featured, layout_version, indexed_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          args
        );
      }
      await store.executeSql('COMMIT');
    } catch (error) {
      try {
        await store.executeSql('ROLLBACK');
      } catch (rollbackError) {
        console.error('Failed to roll back photo index transaction');
      }
      throw new Error('照片索引写入失败');
    }
  }

  static async loadPhotos(limit: number = 500): Promise<PhotoRecord[]> {
    const store: relationalStore.RdbStore | null = PhotoIndexDatabase.store;
    if (store === null) {
      throw new Error('照片索引数据库尚未初始化');
    }
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(
        'SELECT asset_id, uri, display_name, date_taken, width, height, layout_x, layout_y, ' +
        'layout_z, featured, layout_version FROM photos ORDER BY date_taken DESC LIMIT ?',
        [Math.max(1, limit)]
      );
      const records: PhotoRecord[] = [];
      while (resultSet.goToNextRow()) {
        const record: PhotoRecord = new PhotoRecord(
          resultSet.getString(resultSet.getColumnIndex('asset_id')),
          resultSet.getString(resultSet.getColumnIndex('uri')),
          resultSet.getString(resultSet.getColumnIndex('display_name')),
          resultSet.getLong(resultSet.getColumnIndex('date_taken'))
        );
        record.width = resultSet.getLong(resultSet.getColumnIndex('width'));
        record.height = resultSet.getLong(resultSet.getColumnIndex('height'));
        record.layoutX = resultSet.getDouble(resultSet.getColumnIndex('layout_x'));
        record.layoutY = resultSet.getDouble(resultSet.getColumnIndex('layout_y'));
        record.layoutZ = resultSet.getDouble(resultSet.getColumnIndex('layout_z'));
        record.featured = resultSet.getLong(resultSet.getColumnIndex('featured')) === 1;
        record.layoutVersion = resultSet.getLong(resultSet.getColumnIndex('layout_version'));
        records.push(record);
      }
      return records;
    } catch (error) {
      throw new Error('无法读取照片索引');
    } finally {
      if (resultSet !== null) {
        try {
          resultSet.close();
        } catch (closeError) {
          console.error('Failed to close photo index result set');
        }
      }
    }
  }

  static async setFeatured(assetId: string, featured: boolean): Promise<void> {
    const store: relationalStore.RdbStore | null = PhotoIndexDatabase.store;
    if (store === null) {
      throw new Error('照片索引数据库尚未初始化');
    }
    try {
      await store.executeSql('UPDATE photos SET featured = ? WHERE asset_id = ?',
        [featured ? 1 : 0, assetId]);
    } catch (error) {
      throw new Error('无法更新镇馆之宝状态');
    }
  }
}
