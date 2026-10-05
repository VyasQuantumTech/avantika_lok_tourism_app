import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/di/injection.dart';
import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/widgets/app_ui.dart';
import '../domain/entities/marketplace_entities.dart';
import '../domain/usecases/marketplace_actions.dart';

class CustomerBookingsHubPage extends StatelessWidget {
  const CustomerBookingsHubPage({super.key});

  @override
  Widget build(BuildContext context) => AppPage(
        title: 'My Bookings',
        subtitle: 'All Avantika Lok services in one place',
        child: ListView(
          children: [
            _hubItem(context, 'Pooja bookings', Icons.temple_hindu_outlined, RouteNames.customerPoojaBookings),
            _hubItem(context, 'Accommodation bookings', Icons.hotel_outlined, RouteNames.customerAccommodationBookings),
            _hubItem(context, 'Transport bookings', Icons.directions_car_outlined, RouteNames.customerTransportBookings),
          ],
        ),
      );

  Widget _hubItem(BuildContext context, String label, IconData icon, String route) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppPanel(
          onTap: () => Navigator.of(context).pushNamed(route),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: AppTypography.label)),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      );
}

class CustomerMarketplaceListPage extends StatefulWidget {
  const CustomerMarketplaceListPage({required this.type, super.key});
  final MarketplaceType type;

  @override
  State<CustomerMarketplaceListPage> createState() => _CustomerMarketplaceListPageState();
}

class _CustomerMarketplaceListPageState extends State<CustomerMarketplaceListPage> {
  final search = TextEditingController();
  late Future<List<MarketplaceItem>> future;

  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() => future = getIt<MarketplaceActions>().browse(widget.type, query: search.text);

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPage(
        title: widget.type.plural,
        subtitle: widget.type == MarketplaceType.accommodation
            ? 'Approved stays with live room availability'
            : 'Approved transport services',
        actions: [
          IconButton(
            tooltip: 'My bookings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CustomerMarketplaceBookingsPage(type: widget.type)),
            ),
            icon: const Icon(Icons.receipt_long_outlined),
          ),
        ],
        child: Column(
          children: [
            TextField(
              controller: search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => setState(reload),
              decoration: InputDecoration(
                hintText: 'Search ${widget.type.plural.toLowerCase()}',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () => setState(reload),
                  icon: const Icon(Icons.refresh),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<MarketplaceItem>>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AppLoadingView(message: 'Loading services…');
                  }
                  if (snapshot.hasError) {
                    return AppErrorState(message: _err(snapshot.error), onRetry: () => setState(reload));
                  }
                  final items = snapshot.data ?? const <MarketplaceItem>[];
                  if (items.isEmpty) {
                    return AppEmptyState(
                      title: 'No ${widget.type.plural.toLowerCase()} available',
                      message: 'Approved provider services will appear here.',
                      icon: widget.type == MarketplaceType.accommodation ? Icons.hotel_outlined : Icons.directions_car_outlined,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(reload);
                      await future;
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, index) => _MarketplaceCustomerCard(
                        item: items[index],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CustomerMarketplaceDetailPage(
                              type: widget.type,
                              identifier: items[index].slug,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
}

class _MarketplaceCustomerCard extends StatelessWidget {
  const _MarketplaceCustomerCard({required this.item, required this.onTap});
  final MarketplaceItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = item.imageUrls.isEmpty ? null : item.imageUrls.first;
    return AppPanel(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 92,
              height: 92,
              child: image == null
                  ? Container(
                      color: AppColors.softSurface,
                      alignment: Alignment.center,
                      child: Icon(
                        item.type == MarketplaceType.accommodation ? Icons.hotel_outlined : Icons.directions_car_outlined,
                        color: AppColors.primary,
                      ),
                    )
                  : Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.softSurface,
                        alignment: Alignment.center,
                        child: Icon(Icons.image_not_supported_outlined, color: AppColors.primary),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppTypography.label),
                if (item.city.isNotEmpty || item.state.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text([item.city, item.state].where((e) => e.isNotEmpty).join(', '), style: AppTypography.caption),
                ],
                if (item.amenities.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(item.amenities.take(3).join(' • '), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption),
                ],
                if (item.price > 0) ...[
                  const SizedBox(height: 6),
                  Text('From ${_money(item.currency, item.price)}', style: AppTypography.label),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class CustomerMarketplaceDetailPage extends StatefulWidget {
  const CustomerMarketplaceDetailPage({required this.type, required this.identifier, super.key});
  final MarketplaceType type;
  final String identifier;

  @override
  State<CustomerMarketplaceDetailPage> createState() => _CustomerMarketplaceDetailPageState();
}

class _CustomerMarketplaceDetailPageState extends State<CustomerMarketplaceDetailPage> {
  late Future<MarketplaceItem> future;

  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() => future = getIt<MarketplaceActions>().detail(widget.type, widget.identifier);

  @override
  Widget build(BuildContext context) => AppPage(
        title: widget.type.title,
        child: FutureBuilder<MarketplaceItem>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoadingView(message: 'Loading details…');
            }
            if (snapshot.hasError || snapshot.data == null) {
              return AppErrorState(message: _err(snapshot.error), onRetry: () => setState(reload));
            }
            final item = snapshot.data!;
            if (widget.type == MarketplaceType.accommodation) {
              return _AccommodationCustomerDetail(item: item);
            }
            return _TransportCustomerDetail(item: item);
          },
        ),
      );
}

class _AccommodationCustomerDetail extends StatelessWidget {
  const _AccommodationCustomerDetail({required this.item});
  final MarketplaceItem item;

  @override
  Widget build(BuildContext context) {
    final units = item.units;
    return ListView(
      children: [
        if (item.imageUrls.isNotEmpty) _imageGallery(item.imageUrls),
        Text(item.name, style: AppTypography.titleLarge),
        if (item.propertyType.isNotEmpty) Text(item.propertyType, style: AppTypography.caption),
        if (item.city.isNotEmpty || item.address.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text([item.address, item.city, item.state].where((e) => e.isNotEmpty).join(', '), style: AppTypography.caption),
        ],
        if (item.description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(item.description, style: AppTypography.body),
        ],
        if (item.checkInTime.isNotEmpty || item.checkOutTime.isNotEmpty) ...[
          const SizedBox(height: 12),
          AppPanel(
            child: Row(
              children: [
                Expanded(child: _smallInfo('Check-in', item.checkInTime.isEmpty ? '—' : item.checkInTime)),
                const SizedBox(width: 12),
                Expanded(child: _smallInfo('Check-out', item.checkOutTime.isEmpty ? '—' : item.checkOutTime)),
              ],
            ),
          ),
        ],
        if (item.amenities.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Amenities', style: AppTypography.sectionTitle),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: item.amenities.map((e) => Chip(label: Text(e))).toList(),
          ),
        ],
        const SizedBox(height: 18),
        Text('Rooms / units', style: AppTypography.sectionTitle),
        const SizedBox(height: 8),
        if (units.isEmpty)
          const AppEmptyState(
            title: 'No room units available',
            message: 'This property has not published bookable units yet.',
            icon: Icons.bed_outlined,
          ),
        ...units.map((unit) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AccommodationUnitCard(
                unit: unit,
                onBook: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerMarketplaceBookingPage(
                      type: MarketplaceType.accommodation,
                      item: item,
                      option: unit,
                    ),
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Widget _smallInfo(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption),
          const SizedBox(height: 3),
          Text(value, style: AppTypography.label),
        ],
      );
}

class _AccommodationUnitCard extends StatelessWidget {
  const _AccommodationUnitCard({required this.unit, required this.onBook});
  final Map<String, dynamic> unit;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final name = _str(unit, ['name'], fallback: 'Room');
    final type = _str(unit, ['unit_type', 'unitType']);
    final guests = _num(unit, ['max_guests', 'maxGuests', 'max_adults', 'maxAdults']);
    final price = _num(unit, ['base_price', 'basePrice', 'amount', 'price']);
    final amenities = _listStrings(unit['amenities']);
    final images = _mediaUrls(unit);
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (images.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: Image.network(images.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(child: Text(name, style: AppTypography.sectionTitle)),
              if (price > 0) Text(_money(_str(unit, ['currency'], fallback: 'INR'), price.toDouble()), style: AppTypography.label),
            ],
          ),
          if (type.isNotEmpty || guests > 0) ...[
            const SizedBox(height: 4),
            Text([if (type.isNotEmpty) type, if (guests > 0) 'Up to $guests guests'].join(' • '), style: AppTypography.caption),
          ],
          if (amenities.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(amenities.take(5).join(' • '), style: AppTypography.caption),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onBook,
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('Check availability & book'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransportCustomerDetail extends StatelessWidget {
  const _TransportCustomerDetail({required this.item});
  final MarketplaceItem item;

  @override
  Widget build(BuildContext context) {
    final options = item.routes;
    return ListView(
      children: [
        if (item.imageUrls.isNotEmpty) _imageGallery(item.imageUrls),
        Text(item.name, style: AppTypography.titleLarge),
        if (item.city.isNotEmpty) Text(item.city, style: AppTypography.caption),
        if (item.description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(item.description, style: AppTypography.body),
        ],
        const SizedBox(height: 16),
        AppPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Book transport', style: AppTypography.sectionTitle),
              if (options.isEmpty) ...[
                Text('This vehicle can be booked without a fixed route.', style: AppTypography.caption),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomerMarketplaceBookingPage(
                          type: MarketplaceType.transport,
                          item: item,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.directions_car_outlined),
                    label: const Text('Book this vehicle'),
                  ),
                ),
              ] else ...[
                Text('Choose an available route.', style: AppTypography.caption),
              ],
              ...options.map(
                (option) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_str(option, ['name', 'route_name', 'routeName'], fallback: 'Route')),
                  subtitle: Text('${_str(option, ['origin'])} → ${_str(option, ['destination'])}'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomerMarketplaceBookingPage(
                        type: MarketplaceType.transport,
                        item: item,
                        option: option,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CustomerMarketplaceBookingPage extends StatefulWidget {
  const CustomerMarketplaceBookingPage({required this.type, required this.item, this.option, super.key});
  final MarketplaceType type;
  final MarketplaceItem item;
  final Map<String, dynamic>? option;

  @override
  State<CustomerMarketplaceBookingPage> createState() => _CustomerMarketplaceBookingPageState();
}

class _CustomerMarketplaceBookingPageState extends State<CustomerMarketplaceBookingPage> {
  final key = GlobalKey<FormState>();
  final checkIn = TextEditingController();
  final checkOut = TextEditingController();
  final units = TextEditingController(text: '1');
  final adults = TextEditingController(text: '2');
  final children = TextEditingController(text: '0');
  final startTime = TextEditingController(text: '09:00');
  final endTime = TextEditingController(text: '18:00');
  final passengers = TextEditingController(text: '1');
  final customerName = TextEditingController();
  final customerPhone = TextEditingController();
  final customerEmail = TextEditingController();
  final notes = TextEditingController();
  bool checking = false;
  bool saving = false;
  AccommodationAvailabilityQuote? quote;

  @override
  void initState() {
    super.initState();
    final start = DateTime.now().add(const Duration(days: 1));
    checkIn.text = _iso(start);
    checkOut.text = _iso(start.add(const Duration(days: 1)));
  }

  @override
  void dispose() {
    for (final controller in [checkIn, checkOut, units, adults, children, startTime, endTime, passengers, customerName, customerPhone, customerEmail, notes]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accommodation = widget.type == MarketplaceType.accommodation;
    return AppPage(
      title: 'Book ${widget.type.title}',
      subtitle: widget.item.name,
      child: Form(
        key: key,
        child: ListView(
          children: [
            if (accommodation) ...[
              _dateField(checkIn, 'Check-in date'),
              _dateField(checkOut, 'Check-out date'),
              Row(
                children: [
                  Expanded(child: _numberField(adults, 'Adults', minimum: 1)),
                  const SizedBox(width: 10),
                  Expanded(child: _numberField(children, 'Children', minimum: 0)),
                ],
              ),
              _numberField(units, 'Units / rooms', minimum: 1),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: checking ? null : _checkAvailability,
                icon: checking
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.event_available_outlined),
                label: Text(checking ? 'Checking…' : 'Check live availability'),
              ),
              if (quote != null) ...[
                const SizedBox(height: 10),
                AppPanel(
                  child: Row(
                    children: [
                      Icon(_selectedUnitAvailable ? Icons.check_circle_outline : Icons.error_outline, color: _selectedUnitAvailable ? AppColors.primary : Theme.of(context).colorScheme.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selectedUnitAvailable ? 'Selected room is available' : 'Selected room is not available', style: AppTypography.label),
                            if (_selectedUnitQuoteAmount > 0) Text('Quote: ${_money(quote!.currency, _selectedUnitQuoteAmount)}', style: AppTypography.caption),
                            if (quote!.message.isNotEmpty) Text(quote!.message, style: AppTypography.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              _dateField(checkIn, 'Service date'),
              _field(startTime, 'Start time', required: true),
              _field(endTime, 'End time'),
              _numberField(passengers, 'Passengers', minimum: 1),
            ],
            _field(customerName, accommodation ? 'Guest / customer name' : 'Passenger / customer name', required: true),
            _field(customerPhone, 'Contact phone', required: true),
            _field(customerEmail, 'Contact email'),
            _field(notes, 'Notes', lines: 3),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: saving ? null : _submit,
              icon: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check_circle_outline),
              label: Text(saving ? 'Creating booking…' : 'Confirm booking'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateField(TextEditingController controller, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          controller: controller,
          readOnly: true,
          validator: (value) => (value ?? '').trim().isEmpty ? 'Required' : null,
          decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.calendar_month_outlined)),
          onTap: () async {
            final initial = DateTime.tryParse(controller.text) ?? DateTime.now();
            final selected = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 730)),
            );
            if (selected != null) {
              controller.text = _iso(selected);
              setState(() => quote = null);
            }
          },
        ),
      );

  Widget _numberField(TextEditingController controller, String label, {required int minimum}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          validator: (value) {
            final parsed = int.tryParse((value ?? '').trim());
            return parsed == null || parsed < minimum ? 'Enter at least $minimum' : null;
          },
          decoration: InputDecoration(labelText: label),
          onChanged: (_) => setState(() => quote = null),
        ),
      );

  Future<void> _checkAvailability() async {
    final adultCount = int.tryParse(adults.text.trim());
    final childCount = int.tryParse(children.text.trim());
    final unitCount = int.tryParse(units.text.trim());
    final checkInDate = DateTime.tryParse(checkIn.text);
    final checkOutDate = DateTime.tryParse(checkOut.text);
    if (adultCount == null || adultCount < 1 || childCount == null || childCount < 0 || unitCount == null || unitCount < 1 || checkInDate == null || checkOutDate == null) {
      AppFeedback.error(context, 'Enter valid dates, guests and room count before checking availability.');
      return;
    }
    if (checkOutDate.isBefore(checkInDate.add(const Duration(days: 1)))) {
      AppFeedback.error(context, 'Check-out must be after check-in.');
      return;
    }
    setState(() => checking = true);
    try {
      final result = await getIt<MarketplaceActions>().checkAccommodationAvailability(
        identifier: widget.item.slug,
        checkIn: checkIn.text,
        checkOut: checkOut.text,
        adults: adultCount,
        children: childCount,
        units: unitCount,
      );
      if (mounted) setState(() => quote = result);
    } catch (error) {
      if (mounted) AppFeedback.error(context, _err(error));
    } finally {
      if (mounted) setState(() => checking = false);
    }
  }

  Future<void> _submit() async {
    if (!key.currentState!.validate()) return;
    if (widget.type == MarketplaceType.accommodation) {
      if (quote == null) {
        await _checkAvailability();
        if (!mounted || quote == null) return;
      }
      if (!_selectedUnitAvailable) {
        AppFeedback.error(context, 'The selected room is not available for these dates and occupancy.');
        return;
      }
    }

    setState(() => saving = true);
    try {
      final body = widget.type == MarketplaceType.accommodation ? _accommodationBookingBody() : _transportBookingBody();
      final booking = await getIt<MarketplaceActions>().book(widget.type, body);
      if (!mounted) return;
      AppFeedback.success(context, 'Booking ${booking.bookingNumber} created.');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerMarketplaceBookingDetailPage(type: widget.type, bookingId: booking.id),
        ),
      );
    } catch (error) {
      if (mounted) AppFeedback.error(context, _err(error));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  String get _selectedUnitId => _str(widget.option ?? const <String, dynamic>{}, ['id', 'unit_id', 'unitId']);
  bool get _selectedUnitAvailable => quote != null && quote!.isUnitAvailable(_selectedUnitId);
  double get _selectedUnitQuoteAmount => quote?.unitTotalAmount(_selectedUnitId) ?? 0;

  Map<String, dynamic> _accommodationBookingBody() {
    final option = widget.option ?? const <String, dynamic>{};
    final unitId = _str(option, ['id', 'unit_id', 'unitId']);
    if (unitId.isEmpty) throw const ApiException('No accommodation unit was returned for this property.');
    return <String, dynamic>{
      'accommodationUnitId': unitId,
      'serviceDate': checkIn.text,
      'endDate': checkOut.text,
      'units': int.parse(units.text),
      'adults': int.parse(adults.text),
      'children': int.parse(children.text),
      'customerName': customerName.text.trim(),
      'customerPhone': customerPhone.text.trim(),
      if (customerEmail.text.trim().isNotEmpty) 'customerEmail': customerEmail.text.trim(),
      if (notes.text.trim().isNotEmpty) 'notes': notes.text.trim(),
    };
  }

  Map<String, dynamic> _transportBookingBody() {
    final option = widget.option ?? const <String, dynamic>{};
    final routeId = _str(option, ['id', 'route_id', 'routeId']);
    if (widget.item.id.isEmpty) throw const ApiException('No bookable vehicle was returned.');
    return <String, dynamic>{
      'vehicleId': widget.item.id,
      if (routeId.isNotEmpty) 'routeId': routeId,
      'serviceDate': checkIn.text,
      'startTime': startTime.text.trim(),
      'endTime': endTime.text.trim(),
      'passengers': int.parse(passengers.text),
      'customerName': customerName.text.trim(),
      'customerPhone': customerPhone.text.trim(),
      if (customerEmail.text.trim().isNotEmpty) 'customerEmail': customerEmail.text.trim(),
      if (notes.text.trim().isNotEmpty) 'notes': notes.text.trim(),
    };
  }
}

class CustomerMarketplaceBookingsPage extends StatefulWidget {
  const CustomerMarketplaceBookingsPage({required this.type, super.key});
  final MarketplaceType type;

  @override
  State<CustomerMarketplaceBookingsPage> createState() => _CustomerMarketplaceBookingsPageState();
}

class _CustomerMarketplaceBookingsPageState extends State<CustomerMarketplaceBookingsPage> {
  late Future<List<MarketplaceBooking>> future;

  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() => future = getIt<MarketplaceActions>().myBookings(widget.type);

  @override
  Widget build(BuildContext context) => AppPage(
        title: 'My ${widget.type.title} Bookings',
        child: FutureBuilder<List<MarketplaceBooking>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoadingView(message: 'Loading bookings…');
            }
            if (snapshot.hasError) {
              return AppErrorState(message: _err(snapshot.error), onRetry: () => setState(reload));
            }
            final bookings = snapshot.data ?? const <MarketplaceBooking>[];
            if (bookings.isEmpty) {
              return const AppEmptyState(title: 'No bookings yet', message: 'Bookings will appear here.', icon: Icons.receipt_long_outlined);
            }
            return RefreshIndicator(
              onRefresh: () async {
                setState(reload);
                await future;
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: bookings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, index) {
                  final booking = bookings[index];
                  return AppPanel(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomerMarketplaceBookingDetailPage(type: widget.type, bookingId: booking.id),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(booking.displayName, style: AppTypography.label),
                              Text('${_dateOnly(booking.serviceDate)} • ${booking.bookingNumber}', style: AppTypography.caption),
                            ],
                          ),
                        ),
                        AppStatusChip(label: booking.status.isEmpty ? 'booked' : booking.status),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
}

class CustomerMarketplaceBookingDetailPage extends StatefulWidget {
  const CustomerMarketplaceBookingDetailPage({required this.type, required this.bookingId, super.key});
  final MarketplaceType type;
  final String bookingId;

  @override
  State<CustomerMarketplaceBookingDetailPage> createState() => _CustomerMarketplaceBookingDetailPageState();
}

class _CustomerMarketplaceBookingDetailPageState extends State<CustomerMarketplaceBookingDetailPage> {
  late Future<MarketplaceBooking> future;

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() => future = getIt<MarketplaceActions>().booking(widget.bookingId);

  @override
  Widget build(BuildContext context) => AppPage(
        title: 'Booking details',
        child: FutureBuilder<MarketplaceBooking>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoadingView(message: 'Loading booking…');
            }
            if (snapshot.hasError || snapshot.data == null) {
              return AppErrorState(message: _err(snapshot.error), onRetry: () => setState(load));
            }
            final booking = snapshot.data!;
            return ListView(
              children: [
                AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.displayName, style: AppTypography.sectionTitle),
                      _row('Booking', booking.bookingNumber),
                      _row('Status', booking.status),
                      if (booking.providerDecision.isNotEmpty) _row('Provider', booking.providerDecision),
                      _row('Date', _dateOnly(booking.serviceDate)),
                      if (booking.endDate.isNotEmpty) _row('End', _dateOnly(booking.endDate)),
                      if (booking.totalAmount > 0) _row('Amount', _money(booking.currency, booking.totalAmount)),
                      if (booking.startOtp.isNotEmpty) _row('Start OTP', booking.startOtp),
                      if (booking.endOtp.isNotEmpty) _row('End OTP', booking.endOtp),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (!booking.isCompleted && !booking.isCancelled)
                  OutlinedButton.icon(onPressed: _cancel, icon: const Icon(Icons.cancel_outlined), label: const Text('Cancel booking')),
                if (booking.isCompleted)
                  FilledButton.icon(onPressed: _review, icon: const Icon(Icons.star_outline), label: const Text('Write review')),
              ],
            );
          },
        ),
      );

  Future<void> _cancel() async {
    final reason = await _text(context, 'Cancel booking', 'Reason');
    if (reason == null || reason.isEmpty) return;
    try {
      await getIt<MarketplaceActions>().bookingAction(widget.bookingId, 'cancel', body: {'reason': reason});
      if (mounted) {
        AppFeedback.success(context, 'Booking cancelled.');
        setState(load);
      }
    } catch (error) {
      if (mounted) AppFeedback.error(context, _err(error));
    }
  }

  Future<void> _review() async {
    final comment = TextEditingController();
    final title = TextEditingController();
    var rating = 5;
    final submit = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(widget.type == MarketplaceType.accommodation ? 'Review your stay' : 'Review your ride'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: rating,
                items: [1, 2, 3, 4, 5].map((value) => DropdownMenuItem(value: value, child: Text('$value stars'))).toList(),
                onChanged: (value) => setDialog(() => rating = value ?? 5),
              ),
              const SizedBox(height: 10),
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 10),
              TextField(controller: comment, maxLines: 3, decoration: const InputDecoration(labelText: 'Comment')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
          ],
        ),
      ),
    );
    if (submit == true) {
      try {
        await getIt<MarketplaceActions>().review(widget.bookingId, rating, comment.text, title: title.text);
        if (mounted) AppFeedback.success(context, 'Review submitted.');
      } catch (error) {
        if (mounted) AppFeedback.error(context, _err(error));
      }
    }
    title.dispose();
    comment.dispose();
  }
}

class ProviderMarketplaceManagementPage extends StatefulWidget {
  const ProviderMarketplaceManagementPage({required this.type, super.key});
  final MarketplaceType type;

  @override
  State<ProviderMarketplaceManagementPage> createState() => _ProviderMarketplaceManagementPageState();
}

class _ProviderMarketplaceManagementPageState extends State<ProviderMarketplaceManagementPage> {
  late Future<List<MarketplaceItem>> future;

  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() => future = getIt<MarketplaceActions>().providerItems(widget.type);

  @override
  Widget build(BuildContext context) => AppPage(
        title: 'Manage ${widget.type.plural}',
        actions: [
          IconButton(
            tooltip: 'Bookings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProviderMarketplaceBookingsPage(type: widget.type)),
            ),
            icon: const Icon(Icons.receipt_long_outlined),
          ),
          if (widget.type == MarketplaceType.transport)
            IconButton(onPressed: _transportProfile, icon: const Icon(Icons.business_outlined)),
        ],
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _edit(null),
          icon: const Icon(Icons.add),
          label: Text(widget.type == MarketplaceType.accommodation ? 'Add property' : 'Add vehicle'),
        ),
        child: FutureBuilder<List<MarketplaceItem>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoadingView(message: 'Loading provider services…');
            }
            if (snapshot.hasError) {
              return AppErrorState(message: _err(snapshot.error), onRetry: () => setState(reload));
            }
            final items = snapshot.data ?? const <MarketplaceItem>[];
            if (items.isEmpty) {
              return AppEmptyState(
                title: 'No ${widget.type.plural.toLowerCase()} yet',
                message: 'Create your first service.',
                icon: widget.type == MarketplaceType.accommodation ? Icons.apartment_outlined : Icons.directions_car_outlined,
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                setState(reload);
                await future;
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 90),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, index) {
                  final item = items[index];
                  return AppPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(item.name, style: AppTypography.sectionTitle)),
                            AppStatusChip(label: item.status),
                          ],
                        ),
                        if (item.city.isNotEmpty) Text(item.city, style: AppTypography.caption),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(onPressed: () => _edit(item), icon: const Icon(Icons.edit_outlined), label: const Text('Edit')),
                            OutlinedButton.icon(
                              onPressed: () => _manage(item),
                              icon: const Icon(Icons.settings_outlined),
                              label: Text(widget.type == MarketplaceType.accommodation ? 'Rooms & availability' : 'Operations'),
                            ),
                            FilledButton.tonal(
                              onPressed: () => _submitForApproval(item),
                              child: const Text('Submit for approval'),
                            ),
                            IconButton(tooltip: 'Delete', onPressed: () => _remove(item), icon: const Icon(Icons.delete_outline)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      );

  Future<void> _edit(MarketplaceItem? item) async {
    if (widget.type == MarketplaceType.accommodation) {
      final changed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => _AccommodationFormPage(item: item)),
      );
      if (changed == true && mounted) setState(reload);
      return;
    }
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _VehicleFormPage(item: item)),
    );
    if (changed == true && mounted) setState(reload);
  }

  Future<void> _remove(MarketplaceItem item) async {
    if (!await _confirm(context, 'Delete ${item.name}?')) return;
    try {
      await getIt<MarketplaceActions>().providerCall(
        widget.type == MarketplaceType.accommodation ? 'deleteAccommodation' : 'deleteVehicle',
        id: item.id,
      );
      if (mounted) {
        AppFeedback.success(context, 'Deleted.');
        setState(reload);
      }
    } catch (error) {
      if (mounted) AppFeedback.error(context, _err(error));
    }
  }

  Future<void> _submitForApproval(MarketplaceItem item) async {
    try {
      await getIt<MarketplaceActions>().providerCall(
        widget.type == MarketplaceType.accommodation ? 'submitAccommodation' : 'submitVehicle',
        id: item.id,
      );
      if (mounted) {
        AppFeedback.success(context, '${widget.type.title} submitted for admin approval.');
        setState(reload);
      }
    } catch (error) {
      if (mounted) AppFeedback.error(context, _err(error));
    }
  }

  Future<void> _manage(MarketplaceItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProviderMarketplaceResourcesPage(type: widget.type, item: item)),
    );
    if (mounted) setState(reload);
  }

  Future<void> _transportProfile() async {
    try {
      final current = await getIt<MarketplaceActions>().providerCall('transportProfile') as Map<String, dynamic>;
      if (!mounted) return;
      final initial = <String, dynamic>{...current};
      initial['serviceAreas'] = _listStrings(current['serviceAreas'] ?? current['service_areas']).join(', ');
      final body = await _simpleForm(context, 'Transport profile', _transportProfileFields, initial);
      if (body != null) {
        final serviceAreas = body.remove('serviceAreas');
        if (serviceAreas is String) body['serviceAreas'] = _csv(serviceAreas);
        await getIt<MarketplaceActions>().providerCall('saveTransportProfile', body: body);
        if (mounted) AppFeedback.success(context, 'Transport profile saved.');
      }
    } catch (error) {
      if (mounted) AppFeedback.error(context, _err(error));
    }
  }
}

class _AccommodationFormPage extends StatefulWidget {
  const _AccommodationFormPage({this.item});
  final MarketplaceItem? item;

  @override
  State<_AccommodationFormPage> createState() => _AccommodationFormPageState();
}

class _AccommodationFormPageState extends State<_AccommodationFormPage> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController shortDescription;
  late final TextEditingController description;
  late final TextEditingController addressLine1;
  late final TextEditingController addressLine2;
  late final TextEditingController city;
  late final TextEditingController state;
  late final TextEditingController postalCode;
  late final TextEditingController countryCode;
  late final TextEditingController contactPhone;
  late final TextEditingController contactEmail;
  late final TextEditingController checkIn;
  late final TextEditingController checkOut;
  late final TextEditingController amenities;
  String accommodationType = 'hotel';
  final mediaIds = <String>[];
  bool saving = false;
  bool uploading = false;

  static const accommodationTypes = <String>[
    'hotel', 'guest_house', 'dharamshala', 'homestay', 'resort', 'hostel', 'other',
  ];

  @override
  void initState() {
    super.initState();
    final raw = widget.item?.raw ?? const <String, dynamic>{};
    final rawType = _str(raw, ['accommodationType', 'accommodation_type'], fallback: 'hotel');
    accommodationType = accommodationTypes.contains(rawType) ? rawType : 'hotel';
    name = TextEditingController(text: _str(raw, ['name']));
    shortDescription = TextEditingController(text: _str(raw, ['shortDescription', 'short_description']));
    description = TextEditingController(text: _str(raw, ['description']));
    addressLine1 = TextEditingController(text: _str(raw, ['addressLine1', 'address_line_1']));
    addressLine2 = TextEditingController(text: _str(raw, ['addressLine2', 'address_line_2']));
    city = TextEditingController(text: _str(raw, ['city']));
    state = TextEditingController(text: _str(raw, ['state']));
    postalCode = TextEditingController(text: _str(raw, ['postalCode', 'postal_code']));
    countryCode = TextEditingController(text: _str(raw, ['countryCode', 'country_code'], fallback: 'IN'));
    contactPhone = TextEditingController(text: _str(raw, ['contactPhone', 'contact_phone']));
    contactEmail = TextEditingController(text: _str(raw, ['contactEmail', 'contact_email']));
    checkIn = TextEditingController(text: _str(raw, ['checkInTime', 'check_in_time'], fallback: '12:00'));
    checkOut = TextEditingController(text: _str(raw, ['checkOutTime', 'check_out_time'], fallback: '10:00'));
    amenities = TextEditingController(text: _listStrings(raw['amenities']).join(', '));
    mediaIds.addAll(_mediaIds(raw));
  }

  @override
  void dispose() {
    for (final controller in [
      name, shortDescription, description, addressLine1, addressLine2, city, state,
      postalCode, countryCode, contactPhone, contactEmail, checkIn, checkOut, amenities,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPage(
        title: widget.item == null ? 'Create accommodation' : 'Edit accommodation',
        child: Form(
          key: formKey,
          child: ListView(
            children: [
              _field(name, 'Property name', required: true),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DropdownButtonFormField<String>(
                  value: accommodationType,
                  decoration: const InputDecoration(labelText: 'Accommodation type'),
                  items: accommodationTypes
                      .map((value) => DropdownMenuItem(value: value, child: Text(value.replaceAll('_', ' '))))
                      .toList(),
                  onChanged: (value) => setState(() => accommodationType = value ?? 'hotel'),
                ),
              ),
              _field(shortDescription, 'Short description', lines: 2),
              _field(description, 'Description', lines: 4),
              _field(addressLine1, 'Address line 1', required: true),
              _field(addressLine2, 'Address line 2'),
              Row(children: [
                Expanded(child: _field(city, 'City', required: true)),
                const SizedBox(width: 10),
                Expanded(child: _field(state, 'State', required: true)),
              ]),
              Row(children: [
                Expanded(child: _field(postalCode, 'Postal code')),
                const SizedBox(width: 10),
                Expanded(child: _field(countryCode, 'Country code', required: true)),
              ]),
              Row(children: [
                Expanded(child: _field(contactPhone, 'Contact phone')),
                const SizedBox(width: 10),
                Expanded(child: _field(contactEmail, 'Contact email')),
              ]),
              Row(children: [
                Expanded(child: _field(checkIn, 'Check-in time')),
                const SizedBox(width: 10),
                Expanded(child: _field(checkOut, 'Check-out time')),
              ]),
              _field(amenities, 'Amenities (comma separated)', lines: 2),
              const SizedBox(height: 4),
              Text('Property images', style: AppTypography.sectionTitle),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: uploading ? null : _pickImages,
                icon: uploading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add_photo_alternate_outlined),
                label: Text(uploading ? 'Uploading images…' : 'Add multiple images'),
              ),
              if (mediaIds.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                    mediaIds.length,
                    (index) => InputChip(
                      label: Text('Image ${index + 1}'),
                      onDeleted: () => setState(() => mediaIds.removeAt(index)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: saving || uploading ? null : _save,
                icon: saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: Text(saving ? 'Saving…' : 'Save accommodation'),
              ),
            ],
          ),
        ),
      );

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 88);
    if (picked.isEmpty) return;
    setState(() => uploading = true);
    try {
      for (final image in picked) {
        final id = await getIt<MarketplaceActions>().upload(
          await image.readAsBytes(), image.name, _mimeFromName(image.name),
        );
        if (mounted && !mediaIds.contains(id)) setState(() => mediaIds.add(id));
      }
      if (mounted) AppFeedback.success(context, '${picked.length} image(s) uploaded.');
    } catch (error) {
      if (mounted) AppFeedback.error(context, _err(error));
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      final oldMetadata = widget.item?.raw['metadata'];
      final metadata = oldMetadata is Map
          ? oldMetadata.map((key, value) => MapEntry('$key', value))
          : <String, dynamic>{};
      metadata['imageMediaAssetIds'] = List<String>.from(mediaIds);

      await getIt<MarketplaceActions>().providerCall(
        'saveAccommodation',
        id: widget.item?.id,
        body: <String, dynamic>{
          'name': name.text.trim(),
          'accommodationType': accommodationType,
          if (shortDescription.text.trim().isNotEmpty) 'shortDescription': shortDescription.text.trim(),
          if (description.text.trim().isNotEmpty) 'description': description.text.trim(),
          'addressLine1': addressLine1.text.trim(),
          if (addressLine2.text.trim().isNotEmpty) 'addressLine2': addressLine2.text.trim(),
          'city': city.text.trim(),
          'state': state.text.trim(),
          if (postalCode.text.trim().isNotEmpty) 'postalCode': postalCode.text.trim(),
          'countryCode': countryCode.text.trim().toUpperCase(),
          if (contactPhone.text.trim().isNotEmpty) 'contactPhone': contactPhone.text.trim(),
          if (contactEmail.text.trim().isNotEmpty) 'contactEmail': contactEmail.text.trim(),
          if (checkIn.text.trim().isNotEmpty) 'checkInTime': checkIn.text.trim(),
          if (checkOut.text.trim().isNotEmpty) 'checkOutTime': checkOut.text.trim(),
          'amenities': _csv(amenities.text),
          'metadata': metadata,
          'imageMediaAssetIds': List<String>.from(mediaIds),
          if (widget.item == null) 'status': 'draft',
        },
      );
      if (!mounted) return;
      AppFeedback.success(context, 'Accommodation saved.');
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) AppFeedback.error(context, _err(error));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

class _VehicleFormPage extends StatefulWidget {
  const _VehicleFormPage({this.item});
  final MarketplaceItem? item;

  @override
  State<_VehicleFormPage> createState() => _VehicleFormPageState();
}

class _VehicleFormPageState extends State<_VehicleFormPage> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController registrationNumber;
  late final TextEditingController make;
  late final TextEditingController model;
  late final TextEditingController year;
  late final TextEditingController seatCapacity;
  late final TextEditingController luggageCapacity;
  late final TextEditingController amenities;
  late final TextEditingController operationalNotes;
  String vehicleType = 'car';
  bool airConditioned = false;
  final mediaIds = <String>[];
  bool saving = false;
  bool uploading = false;

  static const vehicleTypes = <String>[
    'car',
    'suv',
    'van',
    'tempo_traveller',
    'bus',
    'auto',
    'taxi',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    final raw = widget.item?.raw ?? const <String, dynamic>{};
    final rawType = _str(raw, ['vehicleType', 'vehicle_type'], fallback: 'car');
    vehicleType = vehicleTypes.contains(rawType) ? rawType : 'car';
    registrationNumber = TextEditingController(text: _str(raw, ['registrationNumber', 'registration_number']));
    make = TextEditingController(text: _str(raw, ['make']));
    model = TextEditingController(text: _str(raw, ['model']));
    final rawYear = _num(raw, ['year']);
    year = TextEditingController(text: rawYear == 0 ? '' : '$rawYear');
    final seats = _num(raw, ['seatCapacity', 'seat_capacity']);
    seatCapacity = TextEditingController(text: seats == 0 ? '4' : '$seats');
    final luggage = _num(raw, ['luggageCapacity', 'luggage_capacity']);
    luggageCapacity = TextEditingController(text: luggage == 0 ? '' : '$luggage');
    amenities = TextEditingController(text: _listStrings(raw['amenities']).join(', '));
    operationalNotes = TextEditingController(text: _str(raw, ['operationalNotes', 'operational_notes']));
    airConditioned = raw['airConditioned'] == true || raw['air_conditioned'] == true;
    mediaIds.addAll(_mediaIds(raw));
  }

  @override
  void dispose() {
    for (final controller in [
      registrationNumber,
      make,
      model,
      year,
      seatCapacity,
      luggageCapacity,
      amenities,
      operationalNotes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPage(
        title: widget.item == null ? 'Create vehicle' : 'Edit vehicle',
        child: Form(
          key: formKey,
          child: ListView(
            children: [
              _field(registrationNumber, 'Registration number', required: true),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DropdownButtonFormField<String>(
                  value: vehicleType,
                  decoration: const InputDecoration(labelText: 'Vehicle type'),
                  items: vehicleTypes
                      .map((value) => DropdownMenuItem(value: value, child: Text(value.replaceAll('_', ' '))))
                      .toList(),
                  onChanged: (value) => setState(() => vehicleType = value ?? 'car'),
                ),
              ),
              Row(
                children: [
                  Expanded(child: _field(make, 'Make')),
                  const SizedBox(width: 10),
                  Expanded(child: _field(model, 'Model')),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _field(year, 'Year', number: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _field(seatCapacity, 'Seat capacity', required: true, number: true)),
                ],
              ),
              _field(luggageCapacity, 'Luggage capacity', number: true),
              _field(amenities, 'Amenities (comma separated)', lines: 2),
              _field(operationalNotes, 'Operational notes', lines: 3),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Air conditioned'),
                value: airConditioned,
                onChanged: (value) => setState(() => airConditioned = value),
              ),
              const SizedBox(height: 4),
              Text('Vehicle images', style: AppTypography.sectionTitle),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: uploading ? null : _pickImages,
                icon: uploading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add_photo_alternate_outlined),
                label: Text(uploading ? 'Uploading images…' : 'Add multiple images'),
              ),
              if (mediaIds.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                    mediaIds.length,
                    (index) => InputChip(
                      label: Text('Image ${index + 1}'),
                      onDeleted: () => setState(() => mediaIds.removeAt(index)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: saving || uploading ? null : _save,
                icon: saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: Text(saving ? 'Saving…' : 'Save vehicle'),
              ),
            ],
          ),
        ),
      );

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 88);
    if (picked.isEmpty) return;
    setState(() => uploading = true);
    try {
      for (final image in picked) {
        final id = await getIt<MarketplaceActions>().upload(
          await image.readAsBytes(),
          image.name,
          _mimeFromName(image.name),
        );
        if (mounted && !mediaIds.contains(id)) setState(() => mediaIds.add(id));
      }
      if (mounted) AppFeedback.success(context, '${picked.length} image(s) uploaded.');
    } catch (error) {
      if (mounted) AppFeedback.error(context, _err(error));
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await getIt<MarketplaceActions>().providerCall(
        'saveVehicle',
        id: widget.item?.id,
        body: <String, dynamic>{
          'registrationNumber': registrationNumber.text.trim().toUpperCase(),
          'vehicleType': vehicleType,
          if (make.text.trim().isNotEmpty) 'make': make.text.trim(),
          if (model.text.trim().isNotEmpty) 'model': model.text.trim(),
          if (year.text.trim().isNotEmpty) 'year': int.parse(year.text.trim()),
          'seatCapacity': int.parse(seatCapacity.text.trim()),
          if (luggageCapacity.text.trim().isNotEmpty) 'luggageCapacity': int.parse(luggageCapacity.text.trim()),
          'airConditioned': airConditioned,
          'amenities': _csv(amenities.text),
          if (operationalNotes.text.trim().isNotEmpty) 'operationalNotes': operationalNotes.text.trim(),
          'imageMediaAssetIds': List<String>.from(mediaIds),
          if (widget.item == null) 'status': 'draft',
        },
      );
      if (!mounted) return;
      AppFeedback.success(context, 'Vehicle saved.');
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) AppFeedback.error(context, _err(error));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

class ProviderMarketplaceResourcesPage extends StatefulWidget {
  const ProviderMarketplaceResourcesPage({required this.type, required this.item, super.key});
  final MarketplaceType type;
  final MarketplaceItem item;

  @override
  State<ProviderMarketplaceResourcesPage> createState() => _ProviderMarketplaceResourcesPageState();
}

class _ProviderMarketplaceResourcesPageState extends State<ProviderMarketplaceResourcesPage> {
  late Future<MarketplaceItem> future;

  @override
  void initState() {
    super.initState();
    if (widget.type == MarketplaceType.accommodation) {
      reload();
    }
  }

  void reload() => future = getIt<MarketplaceActions>().providerItem(widget.type, widget.item.id);

  @override
  Widget build(BuildContext context) {
    if (widget.type != MarketplaceType.accommodation) {
      return _TransportResourcePage(item: widget.item);
    }
    return AppPage(
      title: 'Rooms & availability',
      subtitle: widget.item.name,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editUnit(null),
        icon: const Icon(Icons.add),
        label: const Text('Add room'),
      ),
      child: FutureBuilder<MarketplaceItem>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingView(message: 'Loading rooms…');
          }
          if (snapshot.hasError || snapshot.data == null) {
            return AppErrorState(message: _err(snapshot.error), onRetry: () => setState(reload));
          }
          final units = snapshot.data!.units;
          if (units.isEmpty) {
            return const AppEmptyState(
              title: 'No rooms yet',
              message: 'Add a room/unit, then configure inventory and rates.',
              icon: Icons.bed_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              setState(reload);
              await future;
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 90),
              itemCount: units.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) => _providerUnitCard(units[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _providerUnitCard(Map<String, dynamic> unit) {
    final unitId = _str(unit, ['id', 'unit_id', 'unitId']);
    final rates = unit['rates'] is List
        ? (unit['rates'] as List).whereType<Map>().map((e) => e.map((k, v) => MapEntry('$k', v))).toList()
        : <Map<String, dynamic>>[];
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(_str(unit, ['name'], fallback: 'Room'), style: AppTypography.sectionTitle)),
              if (_num(unit, ['basePriceAmount', 'base_price_amount']) > 0)
                Text(_money('INR', _num(unit, ['basePriceAmount', 'base_price_amount']).toDouble()), style: AppTypography.label),
            ],
          ),
          Text(
            [
              _str(unit, ['unit_type', 'unitType']),
              if (_num(unit, ['maxAdults', 'max_adults']) > 0) '${_num(unit, ['maxAdults', 'max_adults'])} adults',
            ].where((e) => e.isNotEmpty).join(' • '),
            style: AppTypography.caption,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(onPressed: () => _editUnit(unit), icon: const Icon(Icons.edit_outlined), label: const Text('Edit room')),
              OutlinedButton.icon(onPressed: () => _inventory(unitId), icon: const Icon(Icons.inventory_2_outlined), label: const Text('Inventory')),
              OutlinedButton.icon(onPressed: () => _editRate(unitId, null), icon: const Icon(Icons.currency_rupee), label: const Text('Add rate')),
              IconButton(onPressed: () => _deleteUnit(unitId), tooltip: 'Delete room', icon: const Icon(Icons.delete_outline)),
            ],
          ),
          if (rates.isNotEmpty) ...[
            const Divider(height: 24),
            Text('Rates', style: AppTypography.label),
            ...rates.map(
              (rate) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(_str(rate, ['rateType', 'rate_type'], fallback: 'standard')),
                subtitle: Text('${_money(_str(rate, ['currency'], fallback: 'INR'), _num(rate, ['priceAmount', 'price_amount']).toDouble())} • ${_str(rate, ['start_date', 'startDate'])} - ${_str(rate, ['end_date', 'endDate'])}'),
                trailing: Wrap(
                  spacing: 0,
                  children: [
                    IconButton(onPressed: () => _editRate(unitId, rate), icon: const Icon(Icons.edit_outlined)),
                    IconButton(onPressed: () => _deleteRate(_str(rate, ['id', 'rate_id', 'rateId'])), icon: const Icon(Icons.delete_outline)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _editUnit(Map<String, dynamic>? unit) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _AccommodationUnitFormPage(
          accommodationId: widget.item.id,
          unit: unit,
        ),
      ),
    );
    if (changed == true && mounted) setState(reload);
  }

  Future<void> _deleteUnit(String unitId) async {
    if (unitId.isEmpty || !await _confirm(context, 'Delete this room/unit?')) return;
    await _providerCall('deleteUnit', id: unitId, success: 'Room deleted.');
  }

  Future<void> _inventory(String unitId) async {
    final date = TextEditingController(text: _iso(DateTime.now().add(const Duration(days: 1))));
    final total = TextEditingController(text: '1');
    final available = TextEditingController(text: '1');
    final minimumStay = TextEditingController(text: '1');
    final maximumStay = TextEditingController();
    final notes = TextEditingController();
    var isClosed = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Set room inventory'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: date, decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)')),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: TextField(controller: total, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total inventory'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: available, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Available inventory'))),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: TextField(controller: minimumStay, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Minimum stay nights'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: maximumStay, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Maximum stay nights (optional)'))),
                  ]),
                  const SizedBox(height: 10),
                  TextField(controller: notes, decoration: const InputDecoration(labelText: 'Notes')),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Closed for this date'),
                    value: isClosed,
                    onChanged: (value) => setDialog(() => isClosed = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok == true) {
      final totalValue = int.tryParse(total.text.trim()) ?? 0;
      final availableValue = int.tryParse(available.text.trim()) ?? 0;
      if (availableValue > totalValue) {
        if (mounted) AppFeedback.error(context, 'Available inventory cannot exceed total inventory.');
      } else {
        await _providerCall(
          'inventory',
          parentId: unitId,
          body: <String, dynamic>{
            'date': date.text.trim(),
            'totalInventory': totalValue,
            'availableInventory': availableValue,
            'isClosed': isClosed,
            'minimumStayNights': int.tryParse(minimumStay.text.trim()) ?? 1,
            if (maximumStay.text.trim().isNotEmpty) 'maximumStayNights': int.tryParse(maximumStay.text.trim()),
            if (notes.text.trim().isNotEmpty) 'notes': notes.text.trim(),
          },
          success: 'Inventory updated.',
        );
      }
    }
    for (final controller in [date, total, available, minimumStay, maximumStay, notes]) {
      controller.dispose();
    }
  }

  Future<void> _editRate(String unitId, Map<String, dynamic>? rate) async {
    final body = await _simpleForm(
      context,
      rate == null ? 'Create accommodation rate' : 'Update accommodation rate',
      _rateFields,
      rate ?? const {},
    );
    if (body == null) return;
    await _providerCall(
      'saveRate',
      id: rate == null ? null : _str(rate, ['id', 'rate_id', 'rateId']),
      parentId: unitId,
      body: body,
      success: 'Rate saved.',
    );
  }

  Future<void> _deleteRate(String rateId) async {
    if (rateId.isEmpty || !await _confirm(context, 'Delete this rate?')) return;
    await _providerCall('deleteRate', id: rateId, success: 'Rate deleted.');
  }

  Future<void> _providerCall(
    String operation, {
    String? id,
    String? parentId,
    Map<String, dynamic>? body,
    String success = 'Saved.',
  }) async {
    try {
      await getIt<MarketplaceActions>().providerCall(operation, id: id, parentId: parentId, body: body);
      if (mounted) {
        AppFeedback.success(context, success);
        setState(reload);
      }
    } catch (error) {
      if (mounted) AppFeedback.error(context, _err(error));
    }
  }
}

class _AccommodationUnitFormPage extends StatefulWidget {
  const _AccommodationUnitFormPage({required this.accommodationId, this.unit});
  final String accommodationId;
  final Map<String, dynamic>? unit;

  @override
  State<_AccommodationUnitFormPage> createState() => _AccommodationUnitFormPageState();
}

class _AccommodationUnitFormPageState extends State<_AccommodationUnitFormPage> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController code;
  late final TextEditingController description;
  late final TextEditingController maxAdults;
  late final TextEditingController maxChildren;
  late final TextEditingController bedCount;
  late final TextEditingController bathroomCount;
  late final TextEditingController basePrice;
  late final TextEditingController currency;
  late final TextEditingController totalInventory;
  late final TextEditingController amenities;
  String unitType = 'room';
  bool isActive = false;
  final mediaIds = <String>[];
  bool saving = false;
  bool uploading = false;

  static const unitTypes = <String>['room', 'suite', 'bed', 'dormitory', 'cottage', 'villa', 'other'];

  @override
  void initState() {
    super.initState();
    final raw = widget.unit ?? const <String, dynamic>{};
    final rawType = _str(raw, ['unitType', 'unit_type'], fallback: 'room');
    unitType = unitTypes.contains(rawType) ? rawType : 'room';
    name = TextEditingController(text: _str(raw, ['name']));
    code = TextEditingController(text: _str(raw, ['code']));
    description = TextEditingController(text: _str(raw, ['description']));
    maxAdults = TextEditingController(text: '${_num(raw, ['maxAdults', 'max_adults']) == 0 ? 2 : _num(raw, ['maxAdults', 'max_adults'])}');
    maxChildren = TextEditingController(text: '${_num(raw, ['maxChildren', 'max_children'])}');
    final beds = raw['bedConfiguration'] ?? raw['bed_configuration'];
    final bedMap = beds is Map ? beds : const {};
    bedCount = TextEditingController(text: '${_num(bedMap.map((k,v)=>MapEntry('$k',v)), ['bedCount']) == 0 ? 1 : _num(bedMap.map((k,v)=>MapEntry('$k',v)), ['bedCount'])}');
    bathroomCount = TextEditingController(text: '${_num(bedMap.map((k,v)=>MapEntry('$k',v)), ['bathroomCount']) == 0 ? 1 : _num(bedMap.map((k,v)=>MapEntry('$k',v)), ['bathroomCount'])}');
    basePrice = TextEditingController(text: _num(raw, ['basePriceAmount', 'base_price_amount']).toString());
    currency = TextEditingController(text: _str(raw, ['currency'], fallback: 'INR'));
    totalInventory = TextEditingController(text: '${_num(raw, ['totalInventory', 'total_inventory']) == 0 ? 1 : _num(raw, ['totalInventory', 'total_inventory'])}');
    amenities = TextEditingController(text: _listStrings(raw['amenities']).join(', '));
    isActive = raw['isActive'] == true || raw['is_active'] == true;
    mediaIds.addAll(_mediaIds(raw));
  }

  @override
  void dispose() {
    for (final controller in [name, code, description, maxAdults, maxChildren, bedCount, bathroomCount, basePrice, currency, totalInventory, amenities]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPage(
        title: widget.unit == null ? 'Add room' : 'Edit room',
        child: Form(
          key: formKey,
          child: ListView(
            children: [
              _field(name, 'Unit name', required: true),
              _field(code, 'Room / unit code'),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DropdownButtonFormField<String>(
                  value: unitType,
                  decoration: const InputDecoration(labelText: 'Unit type'),
                  items: unitTypes.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                  onChanged: (value) => setState(() => unitType = value ?? 'room'),
                ),
              ),
              _field(description, 'Description', lines: 3),
              Row(children: [
                Expanded(child: _field(maxAdults, 'Max adults', required: true, number: true)),
                const SizedBox(width: 10),
                Expanded(child: _field(maxChildren, 'Max children', required: true, number: true)),
              ]),
              Row(children: [
                Expanded(child: _field(bedCount, 'Bed count', required: true, number: true)),
                const SizedBox(width: 10),
                Expanded(child: _field(bathroomCount, 'Bathroom count', required: true, number: true)),
              ]),
              Row(children: [
                Expanded(child: _field(basePrice, 'Base price', required: true, number: true)),
                const SizedBox(width: 10),
                Expanded(child: _field(currency, 'Currency', required: true)),
              ]),
              _field(totalInventory, 'Total inventory', required: true, number: true),
              _field(amenities, 'Amenities (comma separated)', lines: 2),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active / bookable'),
                subtitle: const Text('Requires approved provider KYC on the backend.'),
                value: isActive,
                onChanged: (value) => setState(() => isActive = value),
              ),
              OutlinedButton.icon(
                onPressed: uploading ? null : _pickImages,
                icon: uploading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add_photo_alternate_outlined),
                label: Text(uploading ? 'Uploading images…' : 'Add room images'),
              ),
              if (mediaIds.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                    mediaIds.length,
                    (index) => InputChip(label: Text('Image ${index + 1}'), onDeleted: () => setState(() => mediaIds.removeAt(index))),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: saving || uploading ? null : _save,
                icon: saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: Text(saving ? 'Saving…' : 'Save room'),
              ),
            ],
          ),
        ),
      );

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 88);
    if (picked.isEmpty) return;
    setState(() => uploading = true);
    try {
      for (final image in picked) {
        final id = await getIt<MarketplaceActions>().upload(await image.readAsBytes(), image.name, _mimeFromName(image.name));
        if (mounted && !mediaIds.contains(id)) setState(() => mediaIds.add(id));
      }
    } catch (error) {
      if (mounted) AppFeedback.error(context, _err(error));
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      final oldMetadata = widget.unit?['metadata'];
      final metadata = oldMetadata is Map
          ? oldMetadata.map((key, value) => MapEntry('$key', value))
          : <String, dynamic>{};
      metadata['imageMediaAssetIds'] = List<String>.from(mediaIds);

      await getIt<MarketplaceActions>().providerCall(
        'saveUnit',
        id: widget.unit == null ? null : _str(widget.unit!, ['id', 'unitId', 'unit_id']),
        parentId: widget.accommodationId,
        body: <String, dynamic>{
          'name': name.text.trim(),
          if (code.text.trim().isNotEmpty) 'code': code.text.trim(),
          'unitType': unitType,
          if (description.text.trim().isNotEmpty) 'description': description.text.trim(),
          'maxAdults': int.parse(maxAdults.text.trim()),
          'maxChildren': int.parse(maxChildren.text.trim()),
          'bedConfiguration': <String, dynamic>{
            'bedCount': int.parse(bedCount.text.trim()),
            'bathroomCount': int.parse(bathroomCount.text.trim()),
          },
          'amenities': _csv(amenities.text),
          'basePriceAmount': num.parse(basePrice.text.trim()),
          'currency': currency.text.trim().toUpperCase(),
          'totalInventory': int.parse(totalInventory.text.trim()),
          'isActive': isActive,
          'metadata': metadata,
        },
      );
      if (!mounted) return;
      AppFeedback.success(context, 'Room saved.');
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) AppFeedback.error(context, _err(error));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

class _TransportResourcePage extends StatefulWidget {
  const _TransportResourcePage({required this.item});
  final MarketplaceItem item;

  @override
  State<_TransportResourcePage> createState() => _TransportResourcePageState();
}

class _TransportResourcePageState extends State<_TransportResourcePage> {
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() {
    future = getIt<MarketplaceActions>()
        .providerCall('transportProfile')
        .then((value) => value is Map<String, dynamic>
            ? value
            : (value as Map).map((key, value) => MapEntry('$key', value)));
  }

  List<Map<String, dynamic>> _maps(dynamic value) => value is List
      ? value
          .whereType<Map>()
          .map((e) => e.map((key, value) => MapEntry('$key', value)))
          .toList()
      : <Map<String, dynamic>>[];

  Map<String, dynamic> _vehicle(Map<String, dynamic> profile) {
    for (final vehicle in _maps(profile['vehicles'])) {
      if (_str(vehicle, ['id']) == widget.item.id) return vehicle;
    }
    return widget.item.raw;
  }

  @override
  Widget build(BuildContext context) => AppPage(
        title: 'Vehicle operations',
        subtitle: widget.item.name,
        child: FutureBuilder<Map<String, dynamic>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoadingView(message: 'Loading vehicle operations…');
            }
            if (snapshot.hasError) {
              return AppErrorState(
                message: _err(snapshot.error),
                onRetry: () => setState(reload),
              );
            }
            final profile = snapshot.data ?? const <String, dynamic>{};
            final vehicle = _vehicle(profile);
            final documents = _maps(vehicle['documents']);
            final availability = _maps(vehicle['availability']);
            final pricing = _maps(vehicle['pricing']);
            final routes = _maps(profile['routes']);

            return RefreshIndicator(
              onRefresh: () async {
                setState(reload);
                await future;
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _resourceSection(
                    title: 'Documents',
                    subtitle: 'Registration, insurance, permit, PUC and fitness documents',
                    addLabel: 'Add document',
                    onAdd: () => _document(),
                    children: documents
                        .map(
                          (document) => _resourceTile(
                            title: _str(document, ['documentType', 'document_type'], fallback: 'Document'),
                            subtitle: [
                              _str(document, ['documentNumber', 'document_number']),
                              _str(document, ['status']),
                              _str(document, ['expiresAt', 'expires_at']),
                            ].where((value) => value.isNotEmpty).join(' • '),
                            onEdit: () => _document(document),
                            onDelete: () => _delete(
                              'deleteDocument',
                              id: _str(document, ['id']),
                              parentId: widget.item.id,
                              question: 'Delete this vehicle document?',
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  _resourceSection(
                    title: 'Availability',
                    subtitle: 'Date-wise operating availability',
                    addLabel: availability.isEmpty ? 'Set availability' : 'Add / update date',
                    onAdd: () => _availability(),
                    children: availability
                        .map(
                          (row) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(_str(row, ['date'], fallback: 'Availability')),
                            subtitle: Text([
                              _str(row, ['status']),
                              _str(row, ['startTime', 'start_time']),
                              _str(row, ['endTime', 'end_time']),
                            ].where((value) => value.isNotEmpty).join(' • ')),
                            trailing: IconButton(
                              onPressed: () => _availability(row),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  _resourceSection(
                    title: 'Pricing',
                    subtitle: 'Per trip, per km, per hour or fixed-route pricing',
                    addLabel: 'Add pricing',
                    onAdd: () => _pricing(),
                    children: pricing
                        .map(
                          (price) => _resourceTile(
                            title: _str(price, ['pricingModel', 'pricing_model'], fallback: 'Pricing'),
                            subtitle: [
                              _money(
                                _str(price, ['currency'], fallback: 'INR'),
                                _num(price, ['baseAmount', 'base_amount']).toDouble(),
                              ),
                              _str(price, ['validFrom', 'valid_from']),
                              _str(price, ['validTo', 'valid_to']),
                            ].where((value) => value.isNotEmpty).join(' • '),
                            onEdit: () => _pricing(price),
                            onDelete: () => _delete(
                              'deletePricing',
                              id: _str(price, ['id']),
                              parentId: widget.item.id,
                              question: 'Delete this pricing rule?',
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  _resourceSection(
                    title: 'Routes',
                    subtitle: 'Reusable transport routes for this provider',
                    addLabel: 'Add route',
                    onAdd: () => _route(),
                    children: routes
                        .map(
                          (route) => _resourceTile(
                            title: _str(route, ['name'], fallback: 'Route'),
                            subtitle: [
                              _str(route, ['origin']),
                              _str(route, ['destination']),
                              _str(route, ['status']),
                            ].where((value) => value.isNotEmpty).join(' • '),
                            onEdit: () => _route(route),
                            onDelete: () => _delete(
                              'deleteRoute',
                              id: _str(route, ['id']),
                              question: 'Delete this route?',
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      );

  Widget _resourceSection({
    required String title,
    required String subtitle,
    required String addLabel,
    required VoidCallback onAdd,
    required List<Widget> children,
  }) =>
      AppPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.sectionTitle),
                      Text(subtitle, style: AppTypography.caption),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: Text(addLabel),
                ),
              ],
            ),
            if (children.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('Nothing configured yet.', style: AppTypography.caption),
              )
            else
              ...children,
          ],
        ),
      );

  Widget _resourceTile({
    required String title,
    required String subtitle,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        trailing: Wrap(
          spacing: 0,
          children: [
            IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
            IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
          ],
        ),
      );

  Future<void> _document([Map<String, dynamic>? document]) async {
    final body = await _simpleForm(
      context,
      document == null ? 'Add vehicle document' : 'Update vehicle document',
      _documentFields,
      document ?? const <String, dynamic>{},
    );
    if (body == null) return;
    await _call(
      'saveDocument',
      id: document == null ? null : _str(document, ['id']),
      parentId: widget.item.id,
      body: body,
      success: 'Vehicle document saved.',
    );
  }

  Future<void> _availability([Map<String, dynamic>? row]) async {
    final body = await _simpleForm(
      context,
      'Vehicle availability',
      _availabilityFields,
      row ?? const <String, dynamic>{'status': 'available'},
    );
    if (body == null) return;
    await _call(
      'availability',
      parentId: widget.item.id,
      body: body,
      success: 'Vehicle availability saved.',
    );
  }

  Future<void> _pricing([Map<String, dynamic>? price]) async {
    final body = await _simpleForm(
      context,
      price == null ? 'Create pricing' : 'Update pricing',
      _pricingFields,
      price ?? const <String, dynamic>{'pricingModel': 'per_trip', 'currency': 'INR'},
    );
    if (body == null) return;
    await _call(
      'savePricing',
      id: price == null ? null : _str(price, ['id']),
      parentId: widget.item.id,
      body: body,
      success: 'Pricing saved.',
    );
  }

  Future<void> _route([Map<String, dynamic>? route]) async {
    final body = await _simpleForm(
      context,
      route == null ? 'Create route' : 'Update route',
      _routeFields,
      route ?? const <String, dynamic>{'status': 'draft'},
    );
    if (body == null) return;
    await _call(
      'saveRoute',
      id: route == null ? null : _str(route, ['id']),
      body: body,
      success: 'Route saved.',
    );
  }

  Future<void> _delete(
    String operation, {
    required String id,
    String? parentId,
    required String question,
  }) async {
    if (id.isEmpty || !await _confirm(context, question)) return;
    await _call(operation, id: id, parentId: parentId, success: 'Deleted.');
  }

  Future<void> _call(
    String operation, {
    String? id,
    String? parentId,
    Map<String, dynamic>? body,
    required String success,
  }) async {
    try {
      await getIt<MarketplaceActions>().providerCall(
        operation,
        id: id,
        parentId: parentId,
        body: body,
      );
      if (mounted) {
        AppFeedback.success(context, success);
        setState(reload);
      }
    } catch (error) {
      if (mounted) AppFeedback.error(context, _err(error));
    }
  }
}

class ProviderMarketplaceBookingsPage extends StatefulWidget {
  const ProviderMarketplaceBookingsPage({required this.type, super.key});
  final MarketplaceType type;

  @override
  State<ProviderMarketplaceBookingsPage> createState() => _ProviderMarketplaceBookingsPageState();
}

class _ProviderMarketplaceBookingsPageState extends State<ProviderMarketplaceBookingsPage> {
  late Future<List<MarketplaceBooking>> future;

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() => future = getIt<MarketplaceActions>().providerBookings(widget.type);

  @override
  Widget build(BuildContext context) => AppPage(
        title: '${widget.type.title} Orders',
        child: FutureBuilder<List<MarketplaceBooking>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoadingView(message: 'Loading orders…');
            }
            if (snapshot.hasError) {
              return AppErrorState(message: _err(snapshot.error), onRetry: () => setState(load));
            }
            final bookings = snapshot.data ?? const <MarketplaceBooking>[];
            if (bookings.isEmpty) {
              return const AppEmptyState(title: 'No orders', message: 'Customer bookings will appear here.', icon: Icons.receipt_long_outlined);
            }
            return RefreshIndicator(
              onRefresh: () async {
                setState(load);
                await future;
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: bookings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, index) => _bookingCard(bookings[index]),
              ),
            );
          },
        ),
      );

  Widget _bookingCard(MarketplaceBooking booking) {
    final status = booking.status.toLowerCase();
    final canAccept = status.isEmpty || const {'pending', 'requested', 'created'}.contains(status);
    final canStart = const {'confirmed', 'accepted'}.contains(status) && !booking.hasStarted;
    final canComplete = const {'confirmed', 'accepted'}.contains(status) && booking.hasStarted && !booking.hasEnded;
    final canCancel = !booking.isCompleted && !booking.isCancelled;
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(booking.displayName, style: AppTypography.label)),
              AppStatusChip(label: booking.status.isEmpty ? 'pending' : booking.status),
            ],
          ),
          Text('${_dateOnly(booking.serviceDate)} • ${booking.bookingNumber}', style: AppTypography.caption),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (canAccept) FilledButton(onPressed: () => _action(booking, 'accept'), child: const Text('Accept')),
              if (canAccept) OutlinedButton(onPressed: () => _reason(booking, 'reject'), child: const Text('Reject')),
              if (canStart) FilledButton.tonal(onPressed: () => _otp(booking, 'start'), child: Text(widget.type == MarketplaceType.accommodation ? 'Start stay' : 'Start trip')),
              if (canComplete) FilledButton.tonal(onPressed: () => _otp(booking, 'complete'), child: Text(widget.type == MarketplaceType.accommodation ? 'Complete stay' : 'Complete trip')),
              if (canCancel) TextButton(onPressed: () => _reason(booking, 'cancel'), child: const Text('Cancel')),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _action(MarketplaceBooking booking, String action, {Map<String, dynamic>? body}) async {
    try {
      await getIt<MarketplaceActions>().providerBookingAction(widget.type, booking.id, action, body: body);
      if (mounted) {
        AppFeedback.success(context, 'Booking updated.');
        setState(load);
      }
    } catch (error) {
      if (mounted) AppFeedback.error(context, _err(error));
    }
  }

  Future<void> _otp(MarketplaceBooking booking, String action) async {
    final otp = await _text(
      context,
      action == 'start' ? 'Enter start OTP' : 'Enter completion OTP',
      '6-digit OTP',
    );
    if (otp == null || otp.isEmpty) return;
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      if (mounted) AppFeedback.error(context, 'OTP must contain exactly 6 digits.');
      return;
    }
    await _action(booking, action, body: <String, dynamic>{'otp': otp});
  }

  Future<void> _reason(MarketplaceBooking booking, String action) async {
    final reason = await _text(context, '${action[0].toUpperCase()}${action.substring(1)} booking', 'Reason');
    if (reason == null || reason.isEmpty) return;
    await _action(booking, action, body: {'reason': reason});
  }
}

Widget _imageGallery(List<String> images) => SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) => ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 300,
            child: Image.network(images[index], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.softSurface)),
          ),
        ),
      ),
    );

Widget _field(
  TextEditingController controller,
  String label, {
  bool required = false,
  bool number = false,
  int lines = 1,
}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        maxLines: lines,
        keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : null,
        validator: required
            ? (value) => (value ?? '').trim().isEmpty ? 'Required' : null
            : null,
        decoration: InputDecoration(labelText: label),
      ),
    );

Widget _row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: AppTypography.caption)),
          Expanded(child: Text(value.isEmpty ? '—' : value)),
        ],
      ),
    );

String _iso(DateTime date) => '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
String _dateOnly(String value) => value.length >= 10 ? value.substring(0, 10) : value;
String _money(String currency, double value) => currency.toUpperCase() == 'INR' ? '₹${value.toStringAsFixed(0)}' : '${currency.toUpperCase()} ${value.toStringAsFixed(0)}';
String _err(Object? error) => error is ApiException ? error.message : '${error ?? 'Request failed'}';
String _str(Map<String, dynamic> map, List<String> keys, {String fallback = ''}) {
  for (final key in keys) {
    final value = map[key];
    if (value != null && '$value'.trim().isNotEmpty) return '$value'.trim();
  }
  return fallback;
}
num _num(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is num) return value;
    final parsed = num.tryParse('${value ?? ''}');
    if (parsed != null) return parsed;
  }
  return 0;
}
List<String> _listStrings(dynamic value) => value is List ? value.map((e) => '$e'.trim()).where((e) => e.isNotEmpty).toList() : const [];
List<String> _csv(String value) => value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
List<String> _mediaIds(Map<String, dynamic> raw) {
  final ids = <String>[];
  final direct = raw['media_ids'] ?? raw['mediaIds'];
  if (direct is List) ids.addAll(direct.map((e) => '$e').where((e) => e.isNotEmpty));
  final metadata = raw['metadata'];
  if (metadata is Map) {
    final metadataIds = metadata['imageMediaAssetIds'] ?? metadata['image_media_asset_ids'];
    if (metadataIds is List) ids.addAll(metadataIds.map((e) => '$e').where((e) => e.isNotEmpty));
  }
  for (final key in const ['mediaAssets', 'media', 'images', 'gallery']) {
    final value = raw[key];
    if (value is List) {
      for (final item in value) {
        if (item is Map && item['id'] != null) ids.add('${item['id']}');
      }
    }
  }
  return ids.toSet().toList();
}
List<String> _mediaUrls(Map<String, dynamic> raw) {
  final urls = <String>[];
  void add(dynamic value) {
    if (value is String && value.trim().isNotEmpty) urls.add(value.trim());
    if (value is Map) {
      add(value['url']);
      add(value['public_url']);
      add(value['publicUrl']);
      add(value['content_url']);
      add(value['contentUrl']);
    }
  }
  for (final key in const ['mediaAssets', 'media', 'images', 'gallery']) {
    final value = raw[key];
    if (value is List) for (final item in value) add(item);
  }
  return urls.toSet().toList();
}
String _mimeFromName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  return 'image/jpeg';
}

Future<String?> _text(BuildContext context, String title, String label) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(controller: controller, decoration: InputDecoration(labelText: label)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('Continue')),
      ],
    ),
  );
  controller.dispose();
  return result;
}

Future<bool> _confirm(BuildContext context, String question) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(question),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Confirm')),
        ],
      ),
    ) ??
    false;

class _FieldDef {
  const _FieldDef(this.key, this.label, {this.number = false, this.boolean = false, this.lines = 1});
  final String key;
  final String label;
  final bool number;
  final bool boolean;
  final int lines;
}

Future<Map<String, dynamic>?> _simpleForm(
  BuildContext context,
  String title,
  List<_FieldDef> fields,
  Map<String, dynamic> initial,
) async {
  final controllers = <String, TextEditingController>{};
  final bools = <String, bool>{};
  for (final field in fields) {
    if (field.boolean) {
      bools[field.key] = initial[field.key] == true;
    } else {
      controllers[field.key] = TextEditingController(text: '${initial[field.key] ?? ''}');
    }
  }
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialog) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: fields.map((field) {
                if (field.boolean) {
                  return SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(field.label),
                    value: bools[field.key] ?? false,
                    onChanged: (value) => setDialog(() => bools[field.key] = value),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: controllers[field.key],
                    maxLines: field.lines,
                    keyboardType: field.number ? const TextInputType.numberWithOptions(decimal: true) : null,
                    decoration: InputDecoration(labelText: field.label),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final body = <String, dynamic>{};
              for (final field in fields) {
                if (field.boolean) {
                  body[field.key] = bools[field.key] ?? false;
                  continue;
                }
                final value = controllers[field.key]!.text.trim();
                if (value.isEmpty) continue;
                if (field.number) {
                  body[field.key] = num.tryParse(value) ?? value;
                } else {
                  body[field.key] = value;
                }
              }
              Navigator.pop(ctx, body);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  for (final controller in controllers.values) controller.dispose();
  return result;
}

const _rateFields = [
  _FieldDef('startDate', 'Start date (YYYY-MM-DD)'),
  _FieldDef('endDate', 'End date (YYYY-MM-DD)'),
  _FieldDef('rateType', 'Rate type (standard/weekend/seasonal/festival/special)'),
  _FieldDef('priceAmount', 'Price amount', number: true),
  _FieldDef('currency', 'Currency'),
  _FieldDef('extraAdultAmount', 'Extra adult amount', number: true),
  _FieldDef('extraChildAmount', 'Extra child amount', number: true),
  _FieldDef('isActive', 'Active', boolean: true),
];

const _transportProfileFields = [
  _FieldDef('businessName', 'Business name'),
  _FieldDef('description', 'Description', lines: 3),
  _FieldDef('supportPhone', 'Support phone'),
  _FieldDef('supportEmail', 'Support email'),
  _FieldDef('serviceAreas', 'Service areas (comma separated)'),
  _FieldDef('status', 'Status (draft/active/suspended)'),
];

const _documentFields = [
  _FieldDef('documentType', 'Document type (registration_certificate/insurance/permit/puc/fitness_certificate/other)'),
  _FieldDef('documentNumber', 'Document number'),
  _FieldDef('storageKey', 'Document storage key'),
  _FieldDef('issuedAt', 'Issued date (YYYY-MM-DD)'),
  _FieldDef('expiresAt', 'Expiry date (YYYY-MM-DD)'),
];

const _availabilityFields = [
  _FieldDef('date', 'Date (YYYY-MM-DD)'),
  _FieldDef('startTime', 'Start time (HH:MM)'),
  _FieldDef('endTime', 'End time (HH:MM)'),
  _FieldDef('status', 'Status (available/unavailable/booked/maintenance)'),
  _FieldDef('notes', 'Notes'),
];

const _pricingFields = [
  _FieldDef('routeId', 'Route ID (required for fixed_route)'),
  _FieldDef('pricingModel', 'Pricing model (per_trip/per_km/per_hour/fixed_route)'),
  _FieldDef('baseAmount', 'Base amount', number: true),
  _FieldDef('perKmAmount', 'Per km amount', number: true),
  _FieldDef('perHourAmount', 'Per hour amount', number: true),
  _FieldDef('minimumAmount', 'Minimum amount', number: true),
  _FieldDef('currency', 'Currency'),
  _FieldDef('validFrom', 'Valid from (YYYY-MM-DD)'),
  _FieldDef('validTo', 'Valid to (YYYY-MM-DD)'),
  _FieldDef('isActive', 'Active', boolean: true),
];

const _routeFields = [
  _FieldDef('name', 'Route name'),
  _FieldDef('origin', 'Origin'),
  _FieldDef('destination', 'Destination'),
  _FieldDef('distanceKm', 'Distance km', number: true),
  _FieldDef('estimatedDurationMinutes', 'Duration minutes', number: true),
  _FieldDef('status', 'Status (draft/active/inactive)'),
];
