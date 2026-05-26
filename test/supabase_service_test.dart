import 'package:flutter_test/flutter_test.dart';
import 'package:app/services/order_service.dart';

void main() {
  group('OrderService Pure Utilities', () {
    test('formatPrice handles various inputs correctly', () {
      expect(OrderService.formatPrice(null), "₹0");
      expect(OrderService.formatPrice(1500), "₹15");
      expect(OrderService.formatPrice("1200.50"), "₹1200.50");
      expect(OrderService.formatPrice("Custom Cake"), "₹0");
    });

    test('formatPhone applies Indian country code prefix', () {
      expect(OrderService.formatPhone("9876543210"), "+919876543210");
      expect(OrderService.formatPhone("919876543210"), "+919876543210");
      expect(OrderService.formatPhone(null), "Contact hidden");
    });
  });
}
