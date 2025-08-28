import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class WebAudioService {
  private audioContext: AudioContext | null = null;

  constructor() {
    // Initialize AudioContext on first user interaction
    if (typeof window !== 'undefined' && window.AudioContext) {
      this.audioContext = new AudioContext();
    }
  }

  /**
   * Play a simple beep sound using Web Audio API
   * @param frequency - Frequency of the beep (default 800Hz)
   * @param duration - Duration in milliseconds (default 200ms)
   * @param volume - Volume from 0 to 1 (default 0.3)
   */
  playBeep(frequency: number = 800, duration: number = 200, volume: number = 0.3): void {
    if (!this.audioContext) {
      console.warn('AudioContext not available');
      return;
    }

    try {
      // Create oscillator and gain nodes
      const oscillator = this.audioContext.createOscillator();
      const gainNode = this.audioContext.createGain();

      // Connect nodes
      oscillator.connect(gainNode);
      gainNode.connect(this.audioContext.destination);

      // Set properties
      oscillator.frequency.value = frequency;
      oscillator.type = 'sine';
      
      // Set volume
      gainNode.gain.value = volume;
      
      // Fade out
      gainNode.gain.exponentialRampToValueAtTime(
        0.01, 
        this.audioContext.currentTime + duration / 1000
      );

      // Start and stop
      oscillator.start(this.audioContext.currentTime);
      oscillator.stop(this.audioContext.currentTime + duration / 1000);
    } catch (error) {
      console.error('Error playing beep:', error);
    }
  }

  /**
   * Play success sound (two quick beeps)
   */
  playSuccess(): void {
    this.playBeep(600, 100, 0.3);
    setTimeout(() => this.playBeep(800, 150, 0.3), 120);
  }

  /**
   * Play error sound (low frequency beep)
   */
  playError(): void {
    this.playBeep(300, 300, 0.3);
  }

  /**
   * Play notification sound (three ascending beeps)
   */
  playNotification(): void {
    this.playBeep(400, 100, 0.2);
    setTimeout(() => this.playBeep(500, 100, 0.2), 110);
    setTimeout(() => this.playBeep(600, 150, 0.3), 220);
  }

  /**
   * Play order alert sound (attention-getting pattern)
   */
  playOrderAlert(): void {
    // Play a more noticeable pattern for new orders
    this.playBeep(800, 150, 0.4);
    setTimeout(() => this.playBeep(800, 150, 0.4), 200);
    setTimeout(() => this.playBeep(800, 150, 0.4), 400);
  }

  /**
   * Resume audio context if suspended (needed for some browsers)
   */
  async resumeAudioContext(): Promise<void> {
    if (this.audioContext && this.audioContext.state === 'suspended') {
      try {
        await this.audioContext.resume();
      } catch (error) {
        console.error('Error resuming audio context:', error);
      }
    }
  }
}