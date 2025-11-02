// Browser notification handler for shop owner app

let soundInterval = null;

function playNotificationSound() {
  // Stop any existing sound first
  stopNotificationSound();

  // Create repeating beep sound for 15 seconds
  const audioContext = new (window.AudioContext || window.webkitAudioContext)();
  let beepCount = 0;
  const maxBeeps = 15; // 15 beeps over 15 seconds

  function playBeep() {
    if (beepCount >= maxBeeps) {
      stopNotificationSound();
      return;
    }

    const oscillator = audioContext.createOscillator();
    const gainNode = audioContext.createGain();

    oscillator.connect(gainNode);
    gainNode.connect(audioContext.destination);

    oscillator.frequency.value = 880; // Frequency in Hz (higher pitch)
    oscillator.type = 'sine';

    gainNode.gain.setValueAtTime(0.5, audioContext.currentTime);
    gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.3);

    oscillator.start(audioContext.currentTime);
    oscillator.stop(audioContext.currentTime + 0.3);

    beepCount++;
  }

  // Play first beep immediately
  playBeep();

  // Then play a beep every 1 second for 15 seconds
  soundInterval = setInterval(playBeep, 1000);
}

function stopNotificationSound() {
  if (soundInterval) {
    clearInterval(soundInterval);
    soundInterval = null;
  }
}

function showBrowserNotification(title, body) {
  if (!("Notification" in window)) {
    console.log("This browser does not support notifications");
    return;
  }

  if (Notification.permission === "granted") {
    playNotificationSound();
    new Notification(title, {
      body: body,
      icon: '/favicon.png',
      badge: '/favicon.png',
      requireInteraction: true,
      tag: 'new-order'
    });
  } else if (Notification.permission !== "denied") {
    Notification.requestPermission().then(function (permission) {
      if (permission === "granted") {
        playNotificationSound();
        new Notification(title, {
          body: body,
          icon: '/favicon.png',
          badge: '/favicon.png',
          requireInteraction: true,
          tag: 'new-order'
        });
      }
    });
  }
}

// Make functions available globally
window.playNotificationSound = playNotificationSound;
window.stopNotificationSound = stopNotificationSound;
window.showBrowserNotification = showBrowserNotification;
