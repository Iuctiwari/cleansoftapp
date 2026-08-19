import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/receipt/services/receipt_api_service.dart';

/// Shows the backend-generated receipt PDF before the user downloads,
/// shares, or prints it. The PDF is fetched on demand from
/// GET /orders/:orderId/receipt; nothing is generated or stored on open.
class ReceiptPreviewScreen extends StatefulWidget {
  const ReceiptPreviewScreen({
    required this.orderId,
    required this.branchId,
    required this.orderNumber,
    this.service,
    super.key,
  });

  final String orderId;
  final String branchId;
  final String orderNumber;
  final ReceiptApiService? service;

  @override
  State<ReceiptPreviewScreen> createState() => _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends State<ReceiptPreviewScreen> {
  late final ReceiptApiService _service;
  late Future<Uint8List> _pdf;

  @override
  void initState() {
    super.initState();
    _service =
        widget.service ??
        ReceiptApiService(tokenStorage: AuthenticationDependencies.tokenStorage);
    _load();
  }

  void _load() {
    _pdf = _service.fetchReceiptPdf(
      orderId: widget.orderId,
      branchId: widget.branchId,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: Text('Receipt · ${widget.orderNumber}')),
    body: FutureBuilder<Uint8List>(
      future: _pdf,
      builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AppLoadingView();
        }
        if (snapshot.hasError) {
          final Object error = snapshot.error!;
          return AppErrorView(
            message: error is ReceiptApiException
                ? error.message
                : 'Unable to load this receipt.',
            onRetry: () => setState(_load),
          );
        }
        final Uint8List bytes = snapshot.requireData;
        return PdfPreview(
          build: (PdfPageFormat format) async => bytes,
          initialPageFormat: PdfPageFormat.a4,
          allowPrinting: true,
          allowSharing: true,
          canChangeOrientation: false,
          canChangePageFormat: false,
          canDebug: false,
          pdfFileName: 'receipt-${widget.orderNumber}.pdf',
        );
      },
    ),
  );
}
