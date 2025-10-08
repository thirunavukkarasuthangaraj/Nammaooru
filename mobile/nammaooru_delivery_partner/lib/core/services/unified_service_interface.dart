import 'dart:async';
import '../models/simple_order_model.dart';
import 'enhanced_navigation_service.dart';
import 'location_service.dart';

/// Abstract interface for all transportation and delivery services
/// Designed to support delivery, ride-hailing, and logistics services
abstract class ServiceInterface {
  String get serviceType; // 'delivery', 'ride', 'logistics'
  String get serviceName; // 'food_delivery', 'bike_taxi', 'package_courier'
  String get displayName; // Human-readable service name

  // Core service methods
  Future<ServiceRequest> createRequest(Map<String, dynamic> data);
  Future<bool> acceptRequest(String requestId);
  Future<bool> startService(String requestId);
  Future<bool> completeService(String requestId, Map<String, dynamic> completionData);
  Future<bool> cancelService(String requestId, String reason);

  // Navigation and tracking
  Future<NavigationSession> startNavigation(ServiceRequest request, NavigationPhase phase);
  LocationTrackingConfig getLocationTrackingConfig();

  // Payment handling
  Future<PaymentResult> processPayment(PaymentRequest request);
  List<PaymentMethod> getSupportedPaymentMethods();

  // Service-specific configurations
  ServiceUIConfig getUIConfiguration();
  List<ServiceAction> getAvailableActions(ServiceRequest request);
  Map<String, dynamic> getServiceMetadata();
}

/// Base service request class - extensible for different service types
abstract class ServiceRequest {
  final String id;
  final String customerId;
  final String partnerId;
  final ServiceType serviceType;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime? scheduledTime;

  // Location data
  final LocationPoint pickupLocation;
  final LocationPoint destinationLocation;

  // Financial data
  final double? estimatedCost;
  final double? actualCost;
  final PaymentMethodType paymentMethod;

  // Common metadata
  final String? customerName;
  final String? customerPhone;
  final String? specialInstructions;
  final Map<String, dynamic>? metadata;

  ServiceRequest({
    required this.id,
    required this.customerId,
    required this.partnerId,
    required this.serviceType,
    required this.status,
    required this.createdAt,
    this.scheduledTime,
    required this.pickupLocation,
    required this.destinationLocation,
    this.estimatedCost,
    this.actualCost,
    required this.paymentMethod,
    this.customerName,
    this.customerPhone,
    this.specialInstructions,
    this.metadata,
  });

  // Convert to existing OrderModel for backward compatibility
  OrderModel toOrderModel();

  // Service-specific data accessor
  T getServiceData<T>();
}

/// Navigation phases for different service types
enum NavigationPhase {
  toPickup,      // Navigate to pickup location (shop/customer)
  toDestination, // Navigate to destination (customer/drop-off)
  returning,     // Return journey (for round trips)
}

/// Service types supported by the platform
enum ServiceType {
  delivery('delivery'),
  ride('ride'),
  logistics('logistics');

  const ServiceType(this.value);
  final String value;
}

/// Request status lifecycle
enum RequestStatus {
  available,    // Available for partners to accept
  accepted,     // Accepted by partner
  started,      // Service started (picked up / ride started)
  inProgress,   // In progress (en route to destination)
  completed,    // Successfully completed
  cancelled,    // Cancelled by customer or partner
  expired,      // Expired due to no acceptance
}

/// Location point with additional metadata
class LocationPoint {
  final double latitude;
  final double longitude;
  final String address;
  final String? landmark;
  final String? contactPerson;
  final String? contactPhone;
  final Map<String, dynamic>? additionalInfo;

  LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.landmark,
    this.contactPerson,
    this.contactPhone,
    this.additionalInfo,
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      address: json['address'] ?? '',
      landmark: json['landmark'],
      contactPerson: json['contactPerson'],
      contactPhone: json['contactPhone'],
      additionalInfo: json['additionalInfo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      if (landmark != null) 'landmark': landmark,
      if (contactPerson != null) 'contactPerson': contactPerson,
      if (contactPhone != null) 'contactPhone': contactPhone,
      if (additionalInfo != null) 'additionalInfo': additionalInfo,
    };
  }
}

/// Location tracking configuration for different services
class LocationTrackingConfig {
  final int idleIntervalSeconds;
  final int activeIntervalSeconds;
  final int highFrequencyIntervalSeconds; // For rides/real-time tracking
  final bool requiresHighAccuracy;
  final bool enableBackgroundTracking;
  final int maxLocationAge;

  LocationTrackingConfig({
    required this.idleIntervalSeconds,
    required this.activeIntervalSeconds,
    this.highFrequencyIntervalSeconds = 10,
    this.requiresHighAccuracy = true,
    this.enableBackgroundTracking = true,
    this.maxLocationAge = 30,
  });
}

/// Service UI configuration
class ServiceUIConfig {
  final String? pickupScreenWidget;
  final String? completionScreenWidget;
  final String? trackingScreenWidget;
  final bool requiresOTP;
  final bool requiresPhotos;
  final List<String> requiredPhotoTypes;
  final bool showEstimatedTime;
  final bool showRealTimeTracking;
  final bool enableCustomerChat;
  final Map<String, dynamic> customizations;

  ServiceUIConfig({
    this.pickupScreenWidget,
    this.completionScreenWidget,
    this.trackingScreenWidget,
    this.requiresOTP = false,
    this.requiresPhotos = false,
    this.requiredPhotoTypes = const [],
    this.showEstimatedTime = true,
    this.showRealTimeTracking = false,
    this.enableCustomerChat = false,
    this.customizations = const {},
  });
}

/// Available actions for a service request
class ServiceAction {
  final String id;
  final String label;
  final String icon;
  final bool isEnabled;
  final Map<String, dynamic>? parameters;

  ServiceAction({
    required this.id,
    required this.label,
    required this.icon,
    this.isEnabled = true,
    this.parameters,
  });
}

/// Payment-related classes
class PaymentRequest {
  final String serviceRequestId;
  final double amount;
  final PaymentMethodType method;
  final Map<String, dynamic>? additionalData;

  PaymentRequest({
    required this.serviceRequestId,
    required this.amount,
    required this.method,
    this.additionalData,
  });
}

class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? errorMessage;
  final Map<String, dynamic>? additionalData;

  PaymentResult({
    required this.success,
    this.transactionId,
    this.errorMessage,
    this.additionalData,
  });
}

enum PaymentMethodType {
  cash,
  online,
  cod,
  wallet,
  card,
}

/// Delivery service implementation (current system)
class DeliveryServiceImpl extends ServiceInterface {
  final String _serviceName;

  DeliveryServiceImpl(this._serviceName);

  @override
  String get serviceType => 'delivery';

  @override
  String get serviceName => _serviceName;

  @override
  String get displayName {
    switch (_serviceName) {
      case 'food_delivery':
        return 'Food Delivery';
      case 'grocery_delivery':
        return 'Grocery Delivery';
      case 'pharmacy_delivery':
        return 'Pharmacy Delivery';
      default:
        return 'Delivery Service';
    }
  }

  @override
  Future<ServiceRequest> createRequest(Map<String, dynamic> data) async {
    return DeliveryServiceRequest.fromJson(data);
  }

  @override
  Future<bool> acceptRequest(String requestId) async {
    // Implementation for accepting delivery request
    // This would call existing API methods
    return true;
  }

  @override
  Future<bool> startService(String requestId) async {
    // Implementation for starting delivery (going to shop)
    return true;
  }

  @override
  Future<bool> completeService(String requestId, Map<String, dynamic> completionData) async {
    // Implementation for completing delivery
    return true;
  }

  @override
  Future<bool> cancelService(String requestId, String reason) async {
    // Implementation for cancelling delivery
    return true;
  }

  @override
  Future<NavigationSession> startNavigation(ServiceRequest request, NavigationPhase phase) async {
    final deliveryRequest = request as DeliveryServiceRequest;

    switch (phase) {
      case NavigationPhase.toPickup:
        // Navigate to shop
        return await EnhancedNavigationService().startShopNavigation(
          deliveryRequest.toOrderModel(),
        );
      case NavigationPhase.toDestination:
        // Navigate to customer
        return await EnhancedNavigationService().startCustomerNavigation(
          deliveryRequest.toOrderModel(),
        );
      case NavigationPhase.returning:
        throw UnsupportedError('Return navigation not supported for delivery');
    }
  }

  @override
  LocationTrackingConfig getLocationTrackingConfig() {
    return LocationTrackingConfig(
      idleIntervalSeconds: 300, // 5 minutes
      activeIntervalSeconds: 30, // 30 seconds
      requiresHighAccuracy: true,
      enableBackgroundTracking: true,
    );
  }

  @override
  Future<PaymentResult> processPayment(PaymentRequest request) async {
    // Implementation for processing delivery payment
    return PaymentResult(success: true);
  }

  @override
  List<PaymentMethod> getSupportedPaymentMethods() {
    return [
      PaymentMethod(PaymentMethodType.cash, 'Cash on Delivery'),
      PaymentMethod(PaymentMethodType.online, 'Online Payment'),
      PaymentMethod(PaymentMethodType.cod, 'Cash on Delivery'),
    ];
  }

  @override
  ServiceUIConfig getUIConfiguration() {
    return ServiceUIConfig(
      pickupScreenWidget: 'EnhancedOTPHandoverScreen',
      completionScreenWidget: 'OrderCompletionScreen',
      requiresOTP: true,
      requiresPhotos: true,
      requiredPhotoTypes: ['pickup_confirmation', 'delivery_proof'],
      showEstimatedTime: true,
      showRealTimeTracking: false,
      enableCustomerChat: false,
    );
  }

  @override
  List<ServiceAction> getAvailableActions(ServiceRequest request) {
    final actions = <ServiceAction>[];

    switch (request.status) {
      case RequestStatus.available:
        actions.addAll([
          ServiceAction(id: 'accept', label: 'Accept Order', icon: 'check_circle'),
          ServiceAction(id: 'reject', label: 'Reject Order', icon: 'cancel'),
        ]);
        break;

      case RequestStatus.accepted:
        actions.addAll([
          ServiceAction(id: 'navigate_to_shop', label: 'Go to Shop', icon: 'navigation'),
          ServiceAction(id: 'call_shop', label: 'Call Shop', icon: 'phone'),
        ]);
        break;

      case RequestStatus.started:
        actions.addAll([
          ServiceAction(id: 'verify_pickup', label: 'Verify Pickup', icon: 'verified'),
          ServiceAction(id: 'navigate_to_customer', label: 'Go to Customer', icon: 'navigation'),
        ]);
        break;

      case RequestStatus.inProgress:
        actions.addAll([
          ServiceAction(id: 'call_customer', label: 'Call Customer', icon: 'phone'),
          ServiceAction(id: 'complete_delivery', label: 'Complete Delivery', icon: 'done'),
        ]);
        break;

      default:
        break;
    }

    return actions;
  }

  @override
  Map<String, dynamic> getServiceMetadata() {
    return {
      'category': 'delivery',
      'subcategory': _serviceName,
      'requires_vehicle': true,
      'supports_scheduling': true,
      'max_distance_km': 25,
      'average_completion_time_minutes': 45,
      'commission_rate': 0.15,
    };
  }
}

/// Delivery-specific service request
class DeliveryServiceRequest extends ServiceRequest {
  final String shopId;
  final String shopName;
  final String? shopAddress;
  final List<OrderItem> items;
  final String? otpCode;

  DeliveryServiceRequest({
    required super.id,
    required super.customerId,
    required super.partnerId,
    required super.status,
    required super.createdAt,
    required super.pickupLocation,
    required super.destinationLocation,
    required super.paymentMethod,
    required this.shopId,
    required this.shopName,
    this.shopAddress,
    required this.items,
    this.otpCode,
    super.scheduledTime,
    super.estimatedCost,
    super.actualCost,
    super.customerName,
    super.customerPhone,
    super.specialInstructions,
    super.metadata,
  }) : super(serviceType: ServiceType.delivery);

  factory DeliveryServiceRequest.fromJson(Map<String, dynamic> json) {
    return DeliveryServiceRequest(
      id: json['id']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      partnerId: json['partnerId']?.toString() ?? '',
      status: RequestStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => RequestStatus.available,
      ),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      scheduledTime: json['scheduledTime'] != null
          ? DateTime.tryParse(json['scheduledTime'])
          : null,
      pickupLocation: LocationPoint.fromJson(json['pickupLocation'] ?? {}),
      destinationLocation: LocationPoint.fromJson(json['destinationLocation'] ?? {}),
      estimatedCost: json['estimatedCost']?.toDouble(),
      actualCost: json['actualCost']?.toDouble(),
      paymentMethod: PaymentMethodType.values.firstWhere(
        (p) => p.name == json['paymentMethod'],
        orElse: () => PaymentMethodType.cash,
      ),
      customerName: json['customerName'],
      customerPhone: json['customerPhone'],
      specialInstructions: json['specialInstructions'],
      shopId: json['shopId']?.toString() ?? '',
      shopName: json['shopName'] ?? '',
      shopAddress: json['shopAddress'],
      items: (json['items'] as List?)
          ?.map((item) => OrderItem.fromJson(item))
          .toList() ?? [],
      otpCode: json['otpCode'],
      metadata: json['metadata'],
    );
  }

  @override
  OrderModel toOrderModel() {
    return OrderModel(
      id: id,
      customerName: customerName ?? '',
      customerPhone: customerPhone,
      shopName: shopName,
      shopAddress: shopAddress,
      deliveryAddress: destinationLocation.address,
      status: status.name,
      createdAt: createdAt,
      shopLatitude: pickupLocation.latitude,
      shopLongitude: pickupLocation.longitude,
      customerLatitude: destinationLocation.latitude,
      customerLongitude: destinationLocation.longitude,
      totalAmount: estimatedCost ?? actualCost,
      paymentMethod: paymentMethod.name,
      specialInstructions: specialInstructions,
      itemCount: items.length,
      scheduledDeliveryTime: scheduledTime,
    );
  }

  @override
  T getServiceData<T>() {
    return {
      'shopId': shopId,
      'shopName': shopName,
      'shopAddress': shopAddress,
      'items': items.map((item) => item.toJson()).toList(),
      'otpCode': otpCode,
    } as T;
  }
}

/// Order item model
class OrderItem {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final String? imageUrl;
  final Map<String, dynamic>? customizations;

  OrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.imageUrl,
    this.customizations,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      quantity: json['quantity']?.toInt() ?? 1,
      price: json['price']?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'],
      customizations: json['customizations'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'price': price,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (customizations != null) 'customizations': customizations,
    };
  }
}

/// Payment method details
class PaymentMethod {
  final PaymentMethodType type;
  final String displayName;
  final bool isEnabled;
  final Map<String, dynamic>? configuration;

  PaymentMethod(
    this.type,
    this.displayName, {
    this.isEnabled = true,
    this.configuration,
  });
}