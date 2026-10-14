import 'package:flutter/material.dart';
import '../../../bookings/presentation/pages/booking_payment_page.dart';
import '../../domain/entities/pooja_entities.dart';

// Preserve the released route and its arguments while sharing checkout across services.
class CustomerPoojaPaymentPage extends StatelessWidget {
  const CustomerPoojaPaymentPage({required this.booking, super.key});
  final PoojaBooking booking;
  @override
  Widget build(BuildContext context) =>
      BookingPaymentPage(bookingId: booking.id);
}
