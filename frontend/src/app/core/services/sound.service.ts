import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class SoundService {
  private soundEnabled = true;
  private audioContext: AudioContext | null = null;
  private volume = 0.4;

  constructor() {
    this.loadSoundPreference();
  }

  private getAudioContext(): AudioContext | null {
    if (!this.audioContext && typeof window !== 'undefined') {
      const AC = window.AudioContext || (window as any).webkitAudioContext;
      if (AC) this.audioContext = new AC();
    }
    if (this.audioContext?.state === 'suspended') {
      this.audioContext.resume();
    }
    return this.audioContext;
  }

  private playTone(frequency: number, duration: number, vol: number, startDelay = 0): void {
    const ctx = this.getAudioContext();
    if (!ctx) return;

    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.connect(gain);
    gain.connect(ctx.destination);

    osc.frequency.value = frequency;
    osc.type = 'sine';

    const start = ctx.currentTime + startDelay;
    gain.gain.setValueAtTime(0, start);
    gain.gain.linearRampToValueAtTime(vol, start + 0.02);
    gain.gain.linearRampToValueAtTime(0, start + duration);

    osc.start(start);
    osc.stop(start + duration);
  }

  playOrderNotification(): void {
    if (!this.soundEnabled) return;
    try {
      // Three ascending digital chimes
      this.playTone(660, 0.15, this.volume, 0);
      this.playTone(880, 0.15, this.volume, 0.18);
      this.playTone(1100, 0.2, this.volume, 0.36);
    } catch (e) {
      console.warn('Error playing order notification:', e);
    }
  }

  playSuccessSound(): void {
    if (!this.soundEnabled) return;
    try {
      // Two quick rising tones
      this.playTone(520, 0.1, this.volume * 0.8, 0);
      this.playTone(780, 0.15, this.volume * 0.8, 0.12);
    } catch (e) {
      console.warn('Error playing success sound:', e);
    }
  }

  playAlertSound(): void {
    if (!this.soundEnabled) return;
    try {
      // Attention-getting double beep
      this.playTone(880, 0.12, this.volume, 0);
      this.playTone(880, 0.12, this.volume, 0.2);
    } catch (e) {
      console.warn('Error playing alert sound:', e);
    }
  }

  playMessageSound(): void {
    if (!this.soundEnabled) return;
    try {
      // Soft single chime
      this.playTone(700, 0.2, this.volume * 0.6, 0);
    } catch (e) {
      console.warn('Error playing message sound:', e);
    }
  }

  playNotificationSound(): void {
    this.playOrderNotification();
  }

  playSound(soundName: string): void {
    if (!this.soundEnabled) return;
    switch (soundName) {
      case 'order': this.playOrderNotification(); break;
      case 'success': this.playSuccessSound(); break;
      case 'alert': this.playAlertSound(); break;
      case 'message': this.playMessageSound(); break;
      default: this.playOrderNotification(); break;
    }
  }

  toggleSound(): boolean {
    this.soundEnabled = !this.soundEnabled;
    localStorage.setItem('soundEnabled', this.soundEnabled.toString());
    return this.soundEnabled;
  }

  isSoundEnabled(): boolean {
    return this.soundEnabled;
  }

  setSoundEnabled(enabled: boolean): void {
    this.soundEnabled = enabled;
    localStorage.setItem('soundEnabled', enabled.toString());
  }

  private loadSoundPreference(): void {
    const saved = localStorage.getItem('soundEnabled');
    if (saved !== null) {
      this.soundEnabled = saved === 'true';
    }
  }

  setVolume(volume: number): void {
    this.volume = Math.max(0, Math.min(1, volume));
  }
}
