import '../auth/login_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/user_model.dart';
import '../../utils/file_export_helper.dart';
import '../../models/laundry_order_model.dart';
import '../../viewmodels/employee_dashboard_viewmodel.dart';
import 'create_order_page.dart';
import 'update_status_page.dart';
import 'manage_service_page.dart';
import 'manage_user_page.dart';

class EmployeeDashboardPage extends StatefulWidget {
  final UserModel user;

  const EmployeeDashboardPage({
    super.key,
    required this.user,
  });

  @override
  State<EmployeeDashboardPage> createState() => _EmployeeDashboardPageState();
}

class _EmployeeDashboardPageState extends State<EmployeeDashboardPage> {
  final EmployeeDashboardViewModel viewModel = EmployeeDashboardViewModel();

  DateTime? _fromDate;
  DateTime? _toDate;
  Map<String, dynamic>? _filteredReport;
  bool _isFiltering = false;

  Future<Map<String, dynamic>>? dashboardFuture;

  @override
  void initState() {
    super.initState();
    refreshDashboard();
  }

  void refreshDashboard() {
    dashboardFuture = viewModel.getDashboardSummary();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatCurrency(dynamic amount) {
    final value = amount is num ? amount : num.tryParse(amount.toString()) ?? 0;

    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  List<_ReportChartData> _getReportChartData() {
    if (_filteredReport == null) return [];

    final rawOrders = _filteredReport!['orders'];

    if (rawOrders is! List) return [];

    final orders = List<LaundryOrderModel>.from(rawOrders);

    final Map<DateTime, _ReportChartData> grouped = {};

    for (final order in orders) {
      final date = order.orderDate.toDate();
      final day = DateTime(date.year, date.month, date.day);

      final existing = grouped[day];

      if (existing == null) {
        grouped[day] = _ReportChartData(
          date: day,
          orderCount: 1,
          revenue: order.totalAmount,
        );
      } else {
        grouped[day] = _ReportChartData(
          date: day,
          orderCount: existing.orderCount + 1,
          revenue: existing.revenue + order.totalAmount,
        );
      }
    }

    final sortedKeys = grouped.keys.toList()..sort();

    return sortedKeys.map((key) => grouped[key]!).toList();
  }

  Widget _buildReportChartCard() {
    final chartData = _getReportChartData();

    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report Chart',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              'Order count based on selected date filter',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 16),

            if (chartData.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xffF4F7FB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 38,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No data available for chart',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 250,
                padding: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: const Color(0xffF8FAFD),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),
                child: CustomPaint(
                  painter: _ReportLineChartPainter(
                    data: chartData,
                    lineColor: const Color(0xff4A90E2),
                    gridColor: Colors.grey.shade300,
                    textColor: Colors.grey.shade700,
                  ),
                ),
              ),

            if (chartData.isNotEmpty) ...[
              const SizedBox(height: 14),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _chartSummaryBox(
                    title: 'Total Orders',
                    value: '${_filteredReport!['totalOrders']}',
                    icon: Icons.receipt_long,
                  ),
                  _chartSummaryBox(
                    title: 'Total Revenue',
                    value: _formatCurrency(_filteredReport!['totalRevenue']),
                    icon: Icons.payments,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chartSummaryBox({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffEAF3FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xff4A90E2),
            size: 22,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to log out of your account?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareTempFile(
    String filename,
    Uint8List bytes,
    String label,
  ) async {
    if (kIsWeb) {
      saveFileWeb(filename, bytes, 'application/octet-stream');
      _showSnack('$label downloaded to browser');
      return;
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: label);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),
      appBar: AppBar(
        title: const Text('Employee Dashboard'),
        backgroundColor: const Color(0xff4A90E2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data ?? {};

          final List<LaundryOrderModel> orders =
              data['orders'] as List<LaundryOrderModel>? ?? [];

          final activeOrders = orders.where((order) {
            return order.status.toLowerCase() != 'completed';
          }).toList();

          final completedOrders = orders.where((order) {
            return order.status.toLowerCase() == 'completed';
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              children: [
                Text(
                  'Welcome, ${widget.user.name}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('Role: ${widget.user.role}'),
                const SizedBox(height: 20),

                orderExpansionCard(
                  title: 'Total Orders',
                  value: data['totalOrders'].toString(),
                  icon: Icons.receipt_long,
                  orders: orders,
                ),

                orderExpansionCard(
                  title: 'Active Orders',
                  value: data['activeOrders'].toString(),
                  icon: Icons.timelapse,
                  orders: activeOrders,
                ),

                orderExpansionCard(
                  title: 'Completed Orders',
                  value: data['completedOrders'].toString(),
                  icon: Icons.check_circle,
                  orders: completedOrders,
                ),

                summaryCard(
                  'Total Revenue',
                  'Rp ${data['totalRevenue']}',
                  Icons.payments,
                ),

                const SizedBox(height: 24),

                if (widget.user.role == 'Admin') ...[
                  const Text(
                    'Reporting',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              SizedBox(
                                width: 140,
                                child: OutlinedButton(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _fromDate ?? DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );

                                    if (picked != null) {
                                      setState(() => _fromDate = picked);
                                    }
                                  },
                                  child: Text(
                                    _fromDate == null
                                        ? 'From'
                                        : DateFormat('yyyy-MM-dd')
                                            .format(_fromDate!),
                                  ),
                                ),
                              ),

                              SizedBox(
                                width: 140,
                                child: OutlinedButton(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _toDate ?? DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );

                                    if (picked != null) {
                                      setState(() => _toDate = picked);
                                    }
                                  },
                                  child: Text(
                                    _toDate == null
                                        ? 'To'
                                        : DateFormat('yyyy-MM-dd')
                                            .format(_toDate!),
                                  ),
                                ),
                              ),

                              SizedBox(
                                width: 140,
                                child: ElevatedButton(
                                  onPressed: _isFiltering
                                      ? null
                                      : () async {
                                          if (_fromDate == null ||
                                              _toDate == null) {
                                            _showSnack(
                                              'Please select both from and to dates',
                                            );
                                            return;
                                          }

                                          setState(() => _isFiltering = true);

                                          try {
                                            final report =
                                                await viewModel.getFilteredReport(
                                              DateTime(
                                                _fromDate!.year,
                                                _fromDate!.month,
                                                _fromDate!.day,
                                              ),
                                              DateTime(
                                                _toDate!.year,
                                                _toDate!.month,
                                                _toDate!.day,
                                                23,
                                                59,
                                                59,
                                              ),
                                            );

                                            setState(() {
                                              _filteredReport = report;
                                            });

                                            _showSnack('Filter applied');
                                          } catch (e) {
                                            _showSnack('Filter failed: $e');
                                          } finally {
                                            setState(() => _isFiltering = false);
                                          }
                                        },
                                  child: Text(
                                    _isFiltering ? 'Loading...' : 'Apply Filter',
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              SizedBox(
                                width: 140,
                                child: ElevatedButton(
                                  onPressed: (_filteredReport == null ||
                                          (_filteredReport?['orders'] as List)
                                              .isEmpty)
                                      ? null
                                      : () async {
                                          final orders =
                                              _filteredReport!['orders']
                                                  as List<dynamic>;

                                          final csv = viewModel.generateCsv(
                                            List<LaundryOrderModel>.from(orders),
                                          );

                                          final bytes =
                                              Uint8List.fromList(csv.codeUnits);

                                          if (kIsWeb) {
                                            saveFileWeb(
                                              'report_${DateTime.now().millisecondsSinceEpoch}.csv',
                                              bytes,
                                              'text/csv',
                                            );
                                            _showSnack(
                                              'CSV download started in browser',
                                            );
                                            return;
                                          }

                                          await _shareTempFile(
                                            'report_${DateTime.now().millisecondsSinceEpoch}.csv',
                                            bytes,
                                            'Laporan CSV',
                                          );
                                        },
                                  child: const Text('Export CSV'),
                                ),
                              ),

                              SizedBox(
                                width: 140,
                                child: ElevatedButton(
                                  onPressed: (_filteredReport == null ||
                                          (_filteredReport?['orders'] as List)
                                              .isEmpty)
                                      ? null
                                      : () async {
                                          final orders =
                                              List<LaundryOrderModel>.from(
                                            _filteredReport!['orders']
                                                as List<dynamic>,
                                          );

                                          try {
                                            final bytes = await viewModel
                                                .generatePdfBytes(orders);

                                            if (kIsWeb) {
                                              saveFileWeb(
                                                'report_${DateTime.now().millisecondsSinceEpoch}.pdf',
                                                bytes,
                                                'application/pdf',
                                              );
                                              _showSnack(
                                                'PDF download started in browser',
                                              );
                                              return;
                                            }

                                            await _shareTempFile(
                                              'report_${DateTime.now().millisecondsSinceEpoch}.pdf',
                                              bytes,
                                              'Laporan PDF',
                                            );
                                          } catch (e) {
                                            _showSnack(
                                              'Export PDF failed: $e',
                                            );
                                          }
                                        },
                                  child: const Text('Export PDF'),
                                ),
                              ),

                              SizedBox(
                                width: 140,
                                child: ElevatedButton(
                                  onPressed: (_filteredReport == null ||
                                          (_filteredReport?['orders'] as List)
                                              .isEmpty)
                                      ? null
                                      : () async {
                                          final orders =
                                              List<LaundryOrderModel>.from(
                                            _filteredReport!['orders']
                                                as List<dynamic>,
                                          );

                                          try {
                                            final bytes = await viewModel
                                                .generateExcelBytes(orders);

                                            if (kIsWeb) {
                                              saveFileWeb(
                                                'report_${DateTime.now().millisecondsSinceEpoch}.xlsx',
                                                bytes,
                                                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                                              );
                                              _showSnack(
                                                'Excel download started in browser',
                                              );
                                              return;
                                            }

                                            await _shareTempFile(
                                              'report_${DateTime.now().millisecondsSinceEpoch}.xlsx',
                                              bytes,
                                              'Laporan Excel',
                                            );
                                          } catch (e) {
                                            _showSnack(
                                              'Export Excel failed: $e',
                                            );
                                          }
                                        },
                                  child: const Text('Export Excel'),
                                ),
                              ),
                            ],
                          ),

                          if (_filteredReport != null) ...[
                            const SizedBox(height: 12),
                            _buildReportChartCard(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],

                const Text(
                  'Menu',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.add_box),
                    title: const Text('Create Order'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateOrderPage(
                            employee: widget.user,
                          ),
                        ),
                      );

                      setState(() {
                        refreshDashboard();
                      });
                    },
                  ),
                ),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.update),
                    title: const Text('Update Laundry Status'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UpdateStatusPage(
                            employee: widget.user,
                          ),
                        ),
                      );

                      setState(() {
                        refreshDashboard();
                      });
                    },
                  ),
                ),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.local_laundry_service),
                    title: const Text('Manage Services'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManageServicePage(),
                        ),
                      );

                      setState(() {
                        refreshDashboard();
                      });
                    },
                  ),
                ),

                if (widget.user.role == 'Admin')
                  menuCard(
                    Icons.people,
                    'Manage Users',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManageUserPage(),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget orderExpansionCard({
    required String title,
    required String value,
    required IconData icon,
    required List<LaundryOrderModel> orders,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(icon, color: const Color(0xff4A90E2)),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          if (orders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No orders found'),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Order Code')),
                  DataColumn(label: Text('Weight')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Status')),
                ],
                rows: orders.map((order) {
                  return DataRow(
                    cells: [
                      DataCell(Text(order.orderCode)),
                      DataCell(Text('${order.totalWeight} kg')),
                      DataCell(Text('Rp ${order.totalAmount}')),
                      DataCell(Text(order.status)),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget summaryCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xff4A90E2)),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget menuCard(
    IconData icon,
    String title, {
    VoidCallback? onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}

class _ReportChartData {
  final DateTime date;
  final int orderCount;
  final int revenue;

  _ReportChartData({
    required this.date,
    required this.orderCount,
    required this.revenue,
  });
}

class _ReportLineChartPainter extends CustomPainter {
  final List<_ReportChartData> data;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;

  _ReportLineChartPainter({
    required this.data,
    required this.lineColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const leftPadding = 40.0;
    const rightPadding = 18.0;
    const topPadding = 24.0;
    const bottomPadding = 46.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    final maxOrders = data.map((e) => e.orderCount).reduce(math.max);
    final maxY = math.max(maxOrders, 1);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final pointBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i <= 4; i++) {
      final y = topPadding + (chartHeight / 4) * i;

      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );

      final labelValue = ((maxY / 4) * (4 - i)).round();

      _drawText(
        canvas,
        labelValue.toString(),
        Offset(6, y - 7),
        10,
        textColor,
      );
    }

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final x = data.length == 1
          ? leftPadding + chartWidth / 2
          : leftPadding + (chartWidth / (data.length - 1)) * i;

      final y = topPadding +
          chartHeight -
          ((data[i].orderCount / maxY) * chartHeight);

      final point = Offset(x, y);
      points.add(point);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);

    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      canvas.drawCircle(point, 6, pointBorderPaint);
      canvas.drawCircle(point, 4, pointPaint);

      if (data.length <= 10) {
        _drawCenteredText(
          canvas,
          data[i].orderCount.toString(),
          Offset(point.dx, point.dy - 22),
          10,
          textColor,
        );
      }
    }

    final labelSkip = data.length <= 6 ? 1 : (data.length / 5).ceil();

    for (int i = 0; i < data.length; i++) {
      if (i % labelSkip == 0 || i == data.length - 1) {
        final x = data.length == 1
            ? leftPadding + chartWidth / 2
            : leftPadding + (chartWidth / (data.length - 1)) * i;

        final label = DateFormat('MM/dd').format(data[i].date);

        _drawCenteredText(
          canvas,
          label,
          Offset(x, size.height - 32),
          10,
          textColor,
        );
      }
    }

    _drawCenteredText(
      canvas,
      'Date',
      Offset(leftPadding + chartWidth / 2, size.height - 13),
      11,
      textColor,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    double fontSize,
    Color color,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, offset);
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset center,
    double fontSize,
    Color color,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );

    textPainter.layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _ReportLineChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.textColor != textColor;
  }
}