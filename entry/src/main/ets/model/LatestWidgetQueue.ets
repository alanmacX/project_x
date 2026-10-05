/** Disk writes never wait for IPC; while one revision is delivering, retain only the newest pending scene. */
export class LatestWidgetQueue {
  private pending: string = '';
  private running: Promise<void> | null = null;
  private delivered: string = '';
  private publish: (json: string) => Promise<void>;
  constructor(publish: (json: string) => Promise<void>) { this.publish = publish; }
  submit(json: string): Promise<void> {
    if (json === this.delivered && this.running === null) return Promise.resolve();
    this.pending = json;
    if (this.running === null) this.running = this.drain().finally(() => { this.running = null; if (this.pending.length > 0) return this.submit(this.pending); return Promise.resolve(); });
    return this.running;
  }
  /** Binding changes invalidate byte-level acknowledgement after in-flight work settles. */
  waitForIdle(): Promise<void> { return this.running ?? Promise.resolve(); }
  invalidate(): void { this.delivered = ''; }
  private async drain(): Promise<void> {
    while (this.pending.length > 0) {
      const json = this.pending; this.pending = '';
      if (json === this.delivered) continue;
      await this.publish(json); this.delivered = json;
    }
  }
}
