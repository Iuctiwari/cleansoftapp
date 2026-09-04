import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_models.dart';
import 'package:nexoraa_mobile/features/authentication/services/auth_token_storage.dart';
import 'package:nexoraa_mobile/features/orders/controllers/order_controller.dart';
import 'package:nexoraa_mobile/features/orders/models/order.dart';
import 'package:nexoraa_mobile/features/orders/services/order_api_service.dart';

void main() {
  test('assignWorker sends staffId and assignment note to backend', () async {
    final List<http.Request> requests = <http.Request>[];
    final OrderApiService service = OrderApiService(
      tokenStorage: _MemoryTokenStorage(),
      baseUrl: 'http://orders.test/api',
      client: MockClient((http.Request request) async {
        requests.add(request);
        return http.Response(
          jsonEncode(<String, Object?>{
            'data': _orderJson(
              'order-123',
              assignedTo: 'staff-456',
              note: 'Handle with care',
              assignmentStatus: 'Assigned',
            ),
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    )..selectBranch('branch-1');

    final OrderController controller = OrderController(service: service);
    final Order order = await controller.assignWorker(
      'order-123',
      'staff-456',
      note: 'Handle with care',
    );

    expect(requests.length, 1);
    expect(requests.first.method, 'POST');
    expect(requests.first.url.path, '/api/v1/orders/order-123/assign');
    final Map<String, dynamic> body = jsonDecode(requests.first.body);
    expect(body['assignedTo'], 'staff-456');
    expect(body['note'], 'Handle with care');
    expect(order.assignment?.note, 'Handle with care');
    expect(order.status, OrderStatus.assigned);
    expect(order.assignment?.status, 'Assigned');
  });

  test(
    'acceptAssignment and rejectAssignment call correct backend endpoints and update state',
    () async {
      final List<http.Request> requests = <http.Request>[];
      final OrderApiService service = OrderApiService(
        tokenStorage: _MemoryTokenStorage(),
        baseUrl: 'http://orders.test/api',
        client: MockClient((http.Request request) async {
          requests.add(request);
          if (request.url.path.endsWith('/accept')) {
            return http.Response(
              jsonEncode(<String, Object?>{
                'data': _orderJson(
                  'order-123',
                  assignedTo: 'staff-456',
                  status: 'Accepted',
                ),
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode(<String, Object?>{
              'data': _orderJson('order-123', status: 'Rejected'),
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      )..selectBranch('branch-1');

      final OrderController controller = OrderController(service: service);
      final Order acceptedOrder = await controller.acceptAssignment(
        'order-123',
      );
      expect(acceptedOrder.status, OrderStatus.accepted);

      final Order rejectedOrder = await controller.rejectAssignment(
        'order-123',
        reason: 'Unavailable',
      );
      expect(rejectedOrder.status, OrderStatus.rejected);
      expect(controller.orders.any((o) => o.id == 'order-123'), isFalse);

      expect(requests.length, 2);
      expect(
        requests[0].url.path,
        '/api/v1/orders/order-123/assignment/accept',
      );
      expect(
        requests[1].url.path,
        '/api/v1/orders/order-123/assignment/reject',
      );
    },
  );

  test(
    'changeStatus to delivered marks status Delivered and places order at top',
    () async {
      final List<http.Request> requests = <http.Request>[];
      final OrderApiService service = OrderApiService(
        tokenStorage: _MemoryTokenStorage(),
        baseUrl: 'http://orders.test/api',
        client: MockClient((http.Request request) async {
          requests.add(request);
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode(<String, Object?>{
                'data': <String, Object?>{
                  'items': <Object>[
                    _orderJson('order-999', status: 'Ready'),
                    _orderJson('order-123', status: 'Ready'),
                  ],
                  'total': 2,
                  'page': 1,
                  'limit': 20,
                  'totalPages': 1,
                },
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode(<String, Object?>{
              'data': _orderJson('order-123', status: 'Delivered'),
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      )..selectBranch('branch-1');

      final OrderController controller = OrderController(service: service);
      await controller.load();
      expect(controller.orders.first.id, 'order-999');

      final Order order = await controller.changeStatus(
        'order-123',
        OrderStatus.delivered,
      );

      expect(requests.length, 2);
      expect(requests.last.method, 'PATCH');
      expect(requests.last.url.path, '/api/v1/orders/order-123/status');
      expect(jsonDecode(requests.last.body)['status'], 'Delivered');
      expect(order.status, OrderStatus.delivered);
      expect(controller.orders.first.id, 'order-123');
      expect(controller.orders.first.status, OrderStatus.delivered);
    },
  );

  test(
    'OrderDetailsData findStaff and resolveStaffName correctly resolves staff name and role',
    () {
      final order = Order.fromJson(
        _orderJson(
          'order-123',
          assignedTo: 'staff-456',
          assignmentStatus: 'Pending',
          status: 'Assigned',
        ),
      );
      final data = _TestOrderDetailsData(
        order: order,
        staffId: 'staff-456',
        staffName: 'Rahul Sharma',
        staffRole: 'Worker',
      );

      expect(data.resolveStaffName(order.assignedTo), 'Rahul Sharma');
      expect(data.findStaff(order.assignedTo)?.role, 'Worker');
    },
  );
}

class _TestOrderDetailsData {
  _TestOrderDetailsData({
    required this.order,
    required this.staffId,
    required this.staffName,
    required this.staffRole,
  });

  final Order order;
  final String staffId;
  final String staffName;
  final String staffRole;

  String resolveStaffName(String? idOrName) {
    if (idOrName == null || idOrName.trim().isEmpty) return 'Worker';
    if (idOrName == staffId) return staffName;
    return idOrName;
  }

  _TestStaff? findStaff(String? idOrName) {
    if (idOrName == staffId)
      return _TestStaff(id: staffId, name: staffName, role: staffRole);
    return null;
  }
}

class _TestStaff {
  const _TestStaff({required this.id, required this.name, required this.role});
  final String id;
  final String name;
  final String role;
}

Map<String, Object?> _orderJson(
  String id, {
  String? assignedTo,
  String? note,
  String assignmentStatus = 'Accepted',
  String status = 'Assigned',
}) => <String, Object?>{
  'id': id,
  'tenantId': 'tenant-1',
  'branchId': 'branch-1',
  'orderNumber': 'ORD-MAIN-000123',
  'customerId': 'customer-1',
  'customerSnapshot': <String, Object>{
    'customerId': 'customer-1',
    'name': 'Hassan Ali',
    'mobile': '9876543210',
    'customerType': 'Regular',
  },
  'status': status,
  'paymentStatus': 'Paid',
  'items': <Object>[
    <String, Object>{
      'id': 'item-1',
      'itemCategoryId': 'category-1',
      'itemCategorySnapshot': <String, Object>{'name': 'Shirt'},
      'serviceId': 'service-1',
      'serviceSnapshot': <String, Object>{'name': 'Dry cleaning'},
      'quantity': 1,
      'unitPrice': 100,
      'discount': 0,
      'tax': 0,
      'lineTotal': 100,
    },
  ],
  'subtotal': 100.0,
  'discount': 0.0,
  'discountPercentage': 0.0,
  'tax': 0.0,
  'grandTotal': 100.0,
  'paidAmount': 100.0,
  'outstandingAmount': 0.0,
  'assignedTo': assignedTo,
  'assignment': assignedTo != null
      ? <String, Object?>{
          'id': 'assign-1',
          'assignedTo': assignedTo,
          'assignedBy': 'manager-1',
          'status': assignmentStatus,
          'note': note,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        }
      : null,
  'createdAt': DateTime.now().toIso8601String(),
  'updatedAt': DateTime.now().toIso8601String(),
  'version': 1,
};

final class _MemoryTokenStorage implements AuthTokenStorage {
  AuthenticationSession? _session = AuthenticationSession(
    accessToken: 'order-token',
    refreshToken: 'refresh-token',
    accessTokenExpiresAt: DateTime.utc(2027),
    refreshTokenExpiresAt: DateTime.utc(2028),
  );

  @override
  Future<void> clear() async => _session = null;

  @override
  Future<AuthenticationSession?> read() async => _session;

  @override
  Future<void> write(AuthenticationSession session) async => _session = session;
}
