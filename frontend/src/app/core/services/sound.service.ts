import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class SoundService {
  private sounds: Map<string, HTMLAudioElement> = new Map();
  private soundEnabled = true;

  constructor() {
    this.initializeSounds();
    this.loadSoundPreference();
  }

  private initializeSounds(): void {
    // Initialize common notification sounds
    this.registerSound('order', 'https://www.soundjay.com/misc/sounds/bell-ringing-05.mp3');
    this.registerSound('success', 'https://www.soundjay.com/misc/sounds/bell-ringing-01.mp3');
    this.registerSound('alert', 'https://www.soundjay.com/misc/sounds/bell-ringing-04.mp3');
    this.registerSound('message', 'https://notificationsounds.com/storage/sounds/file-sounds-1150-pristine.mp3');
    
    // Use a data URI for a simple beep sound as fallback
    const beepSound = 'data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBSuBzvLZiTYIG2m98OScTgwOUqzn77VgGAU7k9n1y3kpBSh+zPLaizsIGGS38+OeTw0NUKzl77RgGQU9k9n1y3kpBCl+zPDaizsIGGS38+OeTw0NUKzl77RgGQU9k9n1y3kpBCl+zPDaizsIGGS38+OeTw0NUKzl77RgGQU9k9n1y3kpBCl+zPDaizsIGGS38+OeTw0NUKzl77RgGQU9k9n1y3kpBCl+zPDaizsIGGS38+OeTw0NUKzl77RgGQU9k9n1y3kpBCl+zPDaizsIGGS38+OeTw0NUKzl77RgGQU9k9n1y3kpBCl+zPDaizsIGGS38+OeTw0NUKzl77RgGQU9k9n1y3kpBCl+zPLaizsIGGS38+OeTw0NUKzl77RgGQU9k9n1y3kpBCl+zPLaizsIGGS38+OeTw0NUKzl77RgGQU9k9n1y3kpBCl+zPLaizsIGGS38+OeTw0NUKzl77RgGQU9k9n1y3kpBCl+zPLaizsIGGS38+OeTw0NUKzl77RgGQU9k9n1y3kpBCl+zPLaizsIGGS38+OeTw0NUKzl77RgGQU9k9n1y3kpBCl+zPLaizsIGGS38+OeTw0NUKzl77RgGQU9k9n1y3kpBCl+zPLaizsIGGS38+OeTw0NUKzl77RgGQU9k9n1y3kpBCl+zPLaizsIGGS38+OeTw0NUKzl77RgGQU9k9n1y3kpBCl+zPLaizsIGGS38+OeTw0NUKzl77RgGQU9k9n1y3kpBCl+zPLaizsIGGS38+OeTw0NUKzl77RgGQU9k9n1y3kpBCl+zPLaizsIGGS38+OeTw0NUKzl77RgGQU9k9n1y3kpBCl+zPLaizsIGGS38+OeTw0NUKzl77RgGQU9k9n1y3kpBSh+zPDaizsIGGS38+OeTw0NUKzl77RgGQU9k9n1y3kpBSh+zPDaizsIGGS38+OeTw0NUKzl77RgGQU9k9n1y3kpBSh+zPDaizsIGGS38+OeTw0NUKzl77RgGQU9k9n1y3kpBSh+zPDaizsIGGS38+OeTw0NUKzl77RgGQU9k9n1y3kpBSh+zPDaizsIGGS38+OeTw0NUKzl77RgGQU9k9n1y3kpBSh+zPDaizsIGGS38+OeTw0NUKzl77RgGQU9k9n1y3kpBSh+zPDaizsIGGS38+OeTw0NUKzl77RgGQU9k9n1y3kpBSh+zPDaizsIGGS38+OeTw0NUKzl77RgGQU9k9n1y3kpBSh+zPDaizsIGGS38+OeTw0NUKzl77RgGQU9k9n1y3kpBSh+zPDaizsIGGS38+OeTw0NUKzl77RgGAU7k9n1y3kpBSh+zPDaizsIGGS38+OeTw0NUKzl77RgGAU7k9n1y3kpBSh+zPDaizsIGGS38+OeTw0NUKzl77RgGAU7k9n1y3kpBSh+zPDaizsIGGS38+OeTw0NUKzl77RgGAU7k9n1y3kpBSh+zPDaizsIGGS38+OeTw0NUKzl77RgGAU7k9n1y3kpBSh+zPDaizsIGGS38+OeTw0NUKzl77RgGAU7k9n1y3kpBSh+zPDaizsIGGS38+OeTw0NUKzl77RgGAU7k9n1y3kpBSh+zPDaizsIGGS38+OeTw0NUKzl77RgGAU7k9n1y3kpBSh+zPDaizsIGGS38+OeTw0NUKzl77RgGAU7k9n1y3kpBSh+zPDaizsIGGS38+OeTw0NUKzl77RgGAU7k9n1y3kpBSl+zO7aizsIGGS38+OeTw0NUKzl77RgGAU7k9n1y3kpBSl+zO7aizsIGGS38+OeTw0NUKzl77RgGAU7k9n1y3kpBSl+zO7aizsIGGS38+OeTw0NUKzl77RgGAU7k9n1y3kpBSl+zO7aizsIGGS38+OeTw0NUKzl77RgGAU7k9n1y3kpBSl+zO7aizsIGGS38+OeTw0NUKzl77RgGAU7k9n1y3kpBSl+zO7aizsIGGS38+OeTw0NUKzl77RgGAU7k9n1y3kpBSl+zO7aizsIGGS38+OeTw0NUKzl77RgGAU7k9n1y3kpBSl+zO7aizsIGGS38+OeTw0NUKzl77RgGAU7k9n1y3kpBSl+zO7aizsIGGS38+OeTw0NUKzl77RgGAU7k9n1y3kpBSl+zO7aizsIGGS38+OeTw0NUKzl77RgGAU7k9n1y3kpBSl+zO7aizsIGGS38+OeTw0NUKzl77RgGAU7k9n1y3kpBSl+zO7aizsIGGS38+OeTw0NUKzl77RgGAU7k9n1y3kpBSl+zO7aizsIGGS38+OeTw0NUKzl77RgGAU7k9n1y3kpBSl+zO7aizsIGGS38+OeTw==';
    this.registerSound('beep', beepSound);
  }

  private registerSound(name: string, url: string): void {
    const audio = new Audio(url);
    audio.preload = 'auto';
    audio.volume = 0.5;
    this.sounds.set(name, audio);
  }

  playSound(soundName: string): void {
    if (!this.soundEnabled) return;
    
    const sound = this.sounds.get(soundName) || this.sounds.get('beep');
    if (sound) {
      sound.currentTime = 0;
      sound.play().catch(error => {
        console.warn('Error playing sound:', error);
      });
    }
  }

  playOrderNotification(): void {
    this.playSound('order');
  }

  playSuccessSound(): void {
    this.playSound('success');
  }

  playAlertSound(): void {
    this.playSound('alert');
  }

  playMessageSound(): void {
    this.playSound('message');
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
    const normalizedVolume = Math.max(0, Math.min(1, volume));
    this.sounds.forEach(sound => {
      sound.volume = normalizedVolume;
    });
  }
}