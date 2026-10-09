import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/core/push/push_platform.dart';
import 'package:nexoraa_mobile/features/online_requests/widgets/shop_ui.dart';

/// Where tapping a push takes the person.
class PushDestination {
  const PushDestination(this.routeName, {this.pathParameters = const <String, String>{}, this.extra});

  final String routeName;
  final Map<String, String> pathParameters;
  final Object? extra;

  @override
  bool operator ==(Object other) =>
      other is PushDestination &&
      other.routeName == routeName &&
      other.extra == extra &&
      _same(other.pathParameters, pathParameters);

  @override
  int get hashCode => Object.hash(routeName, extra, pathParameters.length);

  static bool _same(Map<String, String> a, Map<String, String> b) =>
      a.length == b.length && a.entries.every((MapEntry<String, String> e) => b[e.key] == e.value);
}

/// Pushes the server sends about marketplace requests *to customers*.
const Set<String> _customerRequestTypes = <String>{
  'request_accepted',
  'request_declined',
  'request_completed',
  'request_update',
};

/// Chooses the screen for a push from the ids it carries (see the server's
/// `data` payloads). Anything unknown opens the notifications list, which is
/// always safe.
PushDestination destinationFor(PushPayload payload) {
  final Map<String, String> data = payload.data;
  final String type = data['type'] ?? '';

  // To a customer: their request.
  if (_customerRequestTypes.contains(type)) {
    final String? requestId = data['requestId'];
    return requestId == null || requestId.isEmpty
        ? const PushDestination(AppRouteNames.consumerHome, extra: 1)
        : PushDestination(
            AppRouteNames.consumerRequest,
            pathParameters: <String, String>{'requestId': requestId},
          );
  }

  // To a shop: a new online request for one of its branches.
  if (type == 'online_request') {
    final String? branchId = data['branchId'];
    return PushDestination(
      AppRouteNames.onlineRequests,
      extra: branchId == null || branchId.isEmpty ? null : ShopBranchArgs(branchId: branchId),
    );
  }

  // Order and worker-task notifications (and anything new): the list.
  return const PushDestination(AppRouteNames.notifications);
}
