# Application Flows Documentation

Business logic and user workflow documentation for NammaOoru platform.

## 📄 Documents in this folder

### [COMPLETE_ORDER_FLOWS.md](COMPLETE_ORDER_FLOWS.md)
Comprehensive order workflow documentation
- Order placement flow
- Order acceptance flow
- Delivery assignment flow
- Pickup and delivery flow
- Payment collection flow
- Order cancellation flow
- State diagrams and transitions

### [SELF_PICKUP_ORDER_FEATURE.md](SELF_PICKUP_ORDER_FEATURE.md)
Self-pickup order feature documentation
- Feature overview
- User flows for self-pickup
- Shop owner acceptance
- Customer pickup process
- Payment handling
- Implementation details

## 🔄 Order State Machine

```
PENDING → CONFIRMED → PREPARING → READY_FOR_PICKUP
                                        ↓
                              (Delivery)  |  (Self Pickup)
                                        ↓          ↓
                                OUT_FOR_DELIVERY  READY_FOR_PICKUP
                                        ↓          ↓
                                   DELIVERED  →  COMPLETED
```

## 👥 User Roles

1. **Customer** - Places orders
2. **Shop Owner** - Accepts and prepares orders
3. **Delivery Partner** - Picks up and delivers orders
4. **Admin** - System management

## 📞 Support

For questions about order flows, review the complete documentation files in this folder.
