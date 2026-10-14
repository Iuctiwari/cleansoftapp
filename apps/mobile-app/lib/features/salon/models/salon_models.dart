/// A person on the salon's team. They are listed by the owner; they do not need an app login.
class SalonStaff {
  const SalonStaff({required this.staffId, required this.name, required this.role});

  factory SalonStaff.fromJson(Map<String, dynamic> json) => SalonStaff(
    staffId: json['staffId'] as String? ?? '',
    name: json['name'] as String? ?? '',
    role: json['role'] as String? ?? '',
  );

  /// Empty for a person who has not been saved yet; the server gives them an id.
  final String staffId;
  final String name;
  final String role;

  Map<String, Object?> toJson() => <String, Object?>{
    if (staffId.isNotEmpty) 'staffId': staffId,
    'name': name.trim(),
    'role': role.trim(),
  };
}

/// One service on the salon's menu.
class SalonMenuItem {
  const SalonMenuItem({
    required this.serviceId,
    required this.name,
    required this.price,
    required this.durationMinutes,
    required this.role,
  });

  factory SalonMenuItem.fromJson(Map<String, dynamic> json) => SalonMenuItem(
    serviceId: json['serviceId'] as String? ?? '',
    name: json['name'] as String? ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0,
    durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 30,
    role: json['role'] as String? ?? '',
  );

  final String serviceId;
  final String name;
  final double price;
  final int durationMinutes;

  /// The kind of staff who do it, e.g. "Hair Stylist".
  final String role;

  Map<String, Object?> toJson() => <String, Object?>{
    if (serviceId.isNotEmpty) 'serviceId': serviceId,
    'name': name.trim(),
    'price': price,
    'durationMinutes': durationMinutes,
    'role': role.trim(),
  };
}

String rupees(double value) =>
    'Rs. ${value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(2)}';

String durationText(int minutes) {
  if (minutes < 60) return '$minutes min';
  final int hours = minutes ~/ 60;
  final int rest = minutes % 60;
  return rest == 0 ? '$hours hr' : '$hours hr $rest min';
}

/// The owner's setup: slot length, team and menu.
class SalonConfig {
  const SalonConfig({required this.configured, required this.slotMinutes, required this.staff, required this.menu});

  factory SalonConfig.fromJson(Map<String, dynamic> json) => SalonConfig(
    configured: json['configured'] as bool? ?? false,
    slotMinutes: (json['slotMinutes'] as num?)?.toInt() ?? 30,
    staff: (json['staff'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(SalonStaff.fromJson)
        .toList(growable: false),
    menu: (json['menu'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(SalonMenuItem.fromJson)
        .toList(growable: false),
  );

  final bool configured;
  final int slotMinutes;
  final List<SalonStaff> staff;
  final List<SalonMenuItem> menu;
}

/// What a customer sees of a salon: the menu and how long a slot is.
class SalonMenu {
  const SalonMenu({required this.configured, required this.slotMinutes, required this.menu});

  factory SalonMenu.fromJson(Map<String, dynamic> json) => SalonMenu(
    configured: json['configured'] as bool? ?? false,
    slotMinutes: (json['slotMinutes'] as num?)?.toInt() ?? 30,
    menu: (json['menu'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(SalonMenuItem.fromJson)
        .toList(growable: false),
  );

  final bool configured;
  final int slotMinutes;
  final List<SalonMenuItem> menu;
}

enum SalonSlotState {
  available,
  pending,
  booked,
  unavailable;

  static SalonSlotState fromCode(String? code) =>
      values.firstWhere((SalonSlotState s) => s.name == code, orElse: () => SalonSlotState.unavailable);
}

class SalonSlot {
  const SalonSlot({required this.start, required this.end, required this.state});

  factory SalonSlot.fromJson(Map<String, dynamic> json) => SalonSlot(
    start: json['start'] as String? ?? '',
    end: json['end'] as String? ?? '',
    state: SalonSlotState.fromCode(json['state'] as String?),
  );

  final String start;
  final String end;
  final SalonSlotState state;
}

class SalonSlots {
  const SalonSlots({
    required this.date,
    required this.closed,
    required this.totalMinutes,
    required this.totalPrice,
    required this.slots,
  });

  factory SalonSlots.fromJson(Map<String, dynamic> json) => SalonSlots(
    date: json['date'] as String? ?? '',
    closed: json['closed'] as bool? ?? false,
    totalMinutes: (json['totalMinutes'] as num?)?.toInt() ?? 0,
    totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
    slots: (json['slots'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(SalonSlot.fromJson)
        .toList(growable: false),
  );

  final String date;
  final bool closed;
  final int totalMinutes;
  final double totalPrice;
  final List<SalonSlot> slots;
}

/// One service of a booked appointment and who does it.
class SalonBookedPart {
  const SalonBookedPart({
    required this.serviceId,
    required this.name,
    required this.price,
    required this.role,
    required this.staffId,
    required this.staffName,
    required this.start,
    required this.end,
  });

  factory SalonBookedPart.fromJson(Map<String, dynamic> json) => SalonBookedPart(
    serviceId: json['serviceId'] as String? ?? '',
    name: json['name'] as String? ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0,
    role: json['role'] as String? ?? '',
    staffId: json['staffId'] as String? ?? '',
    staffName: json['staffName'] as String? ?? '',
    start: _clock((json['startMinute'] as num?)?.toInt() ?? 0),
    end: _clock((json['endMinute'] as num?)?.toInt() ?? 0),
  );

  final String serviceId;
  final String name;
  final double price;
  final String role;
  final String staffId;
  final String staffName;
  final String start;
  final String end;
}

/// The salon part of a booking request: services, who does them, total and payment.
class SalonBooking {
  const SalonBooking({required this.parts, required this.totalPrice, required this.totalMinutes});

  static SalonBooking? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    return SalonBooking(
      parts: (value['parts'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(SalonBookedPart.fromJson)
          .toList(growable: false),
      totalPrice: (value['totalPrice'] as num?)?.toDouble() ?? 0,
      totalMinutes: (value['totalMinutes'] as num?)?.toInt() ?? 0,
    );
  }

  final List<SalonBookedPart> parts;
  final double totalPrice;
  final int totalMinutes;
}

class SalonAppointment {
  const SalonAppointment({
    required this.requestId,
    required this.requestNumber,
    required this.customerName,
    required this.status,
    required this.service,
    required this.start,
    required this.end,
  });

  factory SalonAppointment.fromJson(Map<String, dynamic> json) => SalonAppointment(
    requestId: json['requestId'] as String? ?? '',
    requestNumber: json['requestNumber'] as String? ?? '',
    customerName: json['customerName'] as String? ?? '',
    status: json['status'] as String? ?? '',
    service: json['service'] as String? ?? '',
    start: json['start'] as String? ?? '',
    end: json['end'] as String? ?? '',
  );

  final String requestId;
  final String requestNumber;
  final String customerName;
  final String status;
  final String service;
  final String start;
  final String end;
}

class SalonStaffDay {
  const SalonStaffDay({required this.staff, required this.appointments});

  final SalonStaff staff;
  final List<SalonAppointment> appointments;
}

class SalonSchedule {
  const SalonSchedule({required this.date, required this.closed, required this.staff});

  factory SalonSchedule.fromJson(Map<String, dynamic> json) => SalonSchedule(
    date: json['date'] as String? ?? '',
    closed: json['closed'] as bool? ?? false,
    staff: (json['staff'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(
          (Map<String, dynamic> row) => SalonStaffDay(
            staff: SalonStaff.fromJson(row),
            appointments: (row['appointments'] as List<dynamic>? ?? const <dynamic>[])
                .whereType<Map<String, dynamic>>()
                .map(SalonAppointment.fromJson)
                .toList(growable: false),
          ),
        )
        .toList(growable: false),
  );

  final String date;
  final bool closed;
  final List<SalonStaffDay> staff;
}

String _clock(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

/// Roles the owner can pick from; they can also type their own.
const List<String> suggestedSalonRoles = <String>[
  'Hair Stylist',
  'Hair Dresser',
  'Barber',
  'Makeup Artist',
  'Beautician',
  'Nail Artist',
  'Massage Therapist',
];
