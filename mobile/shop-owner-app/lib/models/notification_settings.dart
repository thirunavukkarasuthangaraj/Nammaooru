class NotificationSettings {
  final bool newOrders;
  final bool orderUpdates;
  final bool payments;
  final bool promotions;
  final bool systemAlerts;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;

  NotificationSettings({
    this.newOrders = true,
    this.orderUpdates = true,
    this.payments = true,
    this.promotions = false,
    this.systemAlerts = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '08:00',
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      newOrders: json['newOrders'] ?? true,
      orderUpdates: json['orderUpdates'] ?? true,
      payments: json['payments'] ?? true,
      promotions: json['promotions'] ?? false,
      systemAlerts: json['systemAlerts'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      quietHoursStart: json['quietHoursStart'] ?? '22:00',
      quietHoursEnd: json['quietHoursEnd'] ?? '08:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'newOrders': newOrders,
      'orderUpdates': orderUpdates,
      'payments': payments,
      'promotions': promotions,
      'systemAlerts': systemAlerts,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
    };
  }

  NotificationSettings copyWith({
    bool? newOrders,
    bool? orderUpdates,
    bool? payments,
    bool? promotions,
    bool? systemAlerts,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) {
    return NotificationSettings(
      newOrders: newOrders ?? this.newOrders,
      orderUpdates: orderUpdates ?? this.orderUpdates,
      payments: payments ?? this.payments,
      promotions: promotions ?? this.promotions,
      systemAlerts: systemAlerts ?? this.systemAlerts,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }
}