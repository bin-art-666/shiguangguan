import { GalaxyCluster, StarPoint } from '../models/GalaxyModels';

export class GalaxySeedService {
  static createPreviewStars(count: number): StarPoint[] {
    const stars: StarPoint[] = [];
    const palette: string[] = ['#FFFFFF', '#D8D7FF', '#B8E9FF', '#FFD8F2', '#C9B8FF'];

    for (let index: number = 0; index < count; index++) {
      const angle: number = index * 2.399963;
      const distance: number = 0.07 + 0.43 * Math.sqrt((index + 1) / count);
      const wave: number = Math.sin(index * 1.73) * 0.035;
      const x: number = 0.5 + Math.cos(angle) * (distance + wave);
      const y: number = 0.51 + Math.sin(angle) * distance * 1.18;
      const radius: number = 0.8 + ((index * 17) % 23) / 10;
      const alpha: number = 0.34 + ((index * 31) % 61) / 100;
      const featured: boolean = index === 7 || index === 31 || index === 68;
      stars.push(new StarPoint(index, x, y, featured ? radius + 2.2 : radius,
        featured ? 1 : alpha, palette[index % palette.length], featured));
    }
    return stars;
  }

  static createPreviewClusters(): GalaxyCluster[] {
    return [
      new GalaxyCluster(2026, '此刻', 126, 0.72, 0.27),
      new GalaxyCluster(2025, '远行', 842, 0.29, 0.46),
      new GalaxyCluster(2024, '相聚', 615, 0.67, 0.69)
    ];
  }
}
