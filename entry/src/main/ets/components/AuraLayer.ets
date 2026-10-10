class AuraOrb {
  baseX: number = 0;
  baseY: number = 0;
  amplitudeX: number = 0;
  amplitudeY: number = 0;
  radius: number = 0;
  speed: number = 0;
  phase: number = 0;
  color: string = '';

  constructor(baseX: number, baseY: number, amplitudeX: number, amplitudeY: number,
    radius: number, speed: number, phase: number, color: string) {
    this.baseX = baseX;
    this.baseY = baseY;
    this.amplitudeX = amplitudeX;
    this.amplitudeY = amplitudeY;
    this.radius = radius;
    this.speed = speed;
    this.phase = phase;
    this.color = color;
  }
}

@Component
export struct AuraLayer {
  @Prop motionSpeed: number = 1;
  @Prop blurRadius: number = 34;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private timerId: number = -1;
  private startedAt: number = 0;
  private isReady: boolean = false;
  private orbs: AuraOrb[] = [
    new AuraOrb(0.23, 0.25, 0.12, 0.08, 0.46, 0.00019, 0.2, '96, 75, 255'),
    new AuraOrb(0.76, 0.42, 0.10, 0.13, 0.42, 0.00015, 2.1, '15, 181, 255'),
    new AuraOrb(0.49, 0.78, 0.15, 0.07, 0.48, 0.00012, 4.2, '255, 70, 178')
  ];

  aboutToAppear(): void {
    this.startedAt = Date.now();
  }

  aboutToDisappear(): void {
    this.stopAnimation();
  }

  private startAnimation(): void {
    if (this.timerId >= 0) {
      return;
    }
    this.drawFrame();
    this.timerId = setInterval(() => {
      this.drawFrame();
    }, 33);
  }

  private stopAnimation(): void {
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private drawFrame(): void {
    if (!this.isReady || this.context.width <= 0 || this.context.height <= 0) {
      return;
    }

    const width: number = this.context.width;
    const height: number = this.context.height;
    const shortest: number = Math.min(width, height);
    const elapsed: number = (Date.now() - this.startedAt) * this.motionSpeed;

    this.context.clearRect(0, 0, width, height);
    this.context.fillStyle = '#070713';
    this.context.fillRect(0, 0, width, height);
    this.context.globalCompositeOperation = 'screen';
    this.context.filter = `blur(${this.blurRadius}px)`;

    this.orbs.forEach((orb: AuraOrb) => {
      const x: number = (orb.baseX + Math.sin(elapsed * orb.speed + orb.phase) * orb.amplitudeX) * width;
      const y: number = (orb.baseY + Math.cos(elapsed * orb.speed * 0.83 + orb.phase) * orb.amplitudeY) * height;
      const pulse: number = 0.92 + Math.cos(elapsed * orb.speed * 1.17 + orb.phase) * 0.08;
      const radius: number = shortest * orb.radius * pulse;
      const alpha: number = 0.22 + Math.cos(elapsed * orb.speed + orb.phase) * 0.045;
      const gradient: CanvasGradient = this.context.createRadialGradient(x, y, 0, x, y, radius);
      gradient.addColorStop(0, `rgba(${orb.color}, ${alpha})`);
      gradient.addColorStop(0.48, `rgba(${orb.color}, ${alpha * 0.44})`);
      gradient.addColorStop(1, `rgba(${orb.color}, 0)`);
      this.context.fillStyle = gradient;
      this.context.beginPath();
      this.context.arc(x, y, radius, 0, Math.PI * 2);
      this.context.fill();
    });

    this.context.filter = 'none';
    this.context.globalCompositeOperation = 'source-over';
  }

  build() {
    Canvas(this.context)
      .width('100%')
      .height('100%')
      .onReady(() => {
        this.isReady = true;
        this.startAnimation();
      })
      .onVisibleAreaChange([0.0, 1.0], (isVisible: boolean, currentRatio: number) => {
        if (isVisible && currentRatio > 0) {
          this.startAnimation();
        } else {
          this.stopAnimation();
        }
      })
      .hitTestBehavior(HitTestMode.None)
  }
}
