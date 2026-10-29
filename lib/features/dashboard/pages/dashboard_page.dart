import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/visitor_model.dart';
import '../../../shared/utils/visitor_actions.dart';
import '../../../shared/widgets/dashboard_stat_card.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/gradient_app_bar.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/visitor_card.dart';
import '../../qr_scanner/pages/qr_scanner_page.dart';
import '../../visitor_details/pages/visitor_details_page.dart';
import '../../visitor_form/pages/visitor_form_page.dart';
import '../../visitors/bloc/visitor_bloc.dart';
import '../../visitors/bloc/visitor_event.dart';
import '../../visitors/bloc/visitor_state.dart';
import '../../visitors/pages/visitor_list_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String get _todayLabel {
    final now = DateTime.now();
    return 'Today, ${now.day} ${_months[now.month - 1]} ${now.year}';
  }

  String _activityTime(Visitor visitor) {
    final raw =
        visitor.checkOutTime ?? visitor.checkInTime ?? visitor.createdAt;
    final parsed = DateTime.tryParse(raw)?.toLocal();

    if (parsed == null) return '—';

    final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final period = parsed.hour < 12 ? 'AM' : 'PM';

    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(
        icon: Icons.apartment,
        title: 'Visitor Management',
      ),
      body: BlocBuilder<VisitorBloc, VisitorState>(
        builder: (context, state) {
          final isLoading =
              state.status == VisitorStatus.loading ||
              state.status == VisitorStatus.initial;

          if (isLoading && state.visitors.isEmpty) {
            return const LoadingView();
          }

          if (state.status == VisitorStatus.failure && state.visitors.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.cloud_off_outlined,
              title: 'Unable to load visitors',
              message: state.errorMessage,
              actionLabel: 'Try Again',
              onAction: () =>
                  context.read<VisitorBloc>().add(const LoadVisitors()),
            );
          }

          return RefreshIndicator(
            onRefresh: () => refreshVisitors(context),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Card(
                      elevation: 5,
                      color: Colors.white,
                      shadowColor: Colors.black38,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 20,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                _todayLabel,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () =>
                          context.read<VisitorBloc>().add(const LoadVisitors()),
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        elevation: 5,
                        shadowColor: Colors.black38,
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primary,
                        minimumSize: const Size(0, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DashboardStatCard(
                  title: 'Total Visitors Today',
                  count: state.totalVisitorsToday,
                  icon: Icons.people,
                  color: AppTheme.primary,
                  tint: AppTheme.primaryTint,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DashboardStatCard(
                        title: 'Checked Out Today',
                        count: state.checkedOutToday,
                        icon: Icons.logout_rounded,
                        color: AppTheme.warning,
                        tint: AppTheme.warningTint,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DashboardStatCard(
                        title: 'Currently Checked In',
                        count: state.currentlyCheckedIn,
                        icon: Icons.login_rounded,
                        color: AppTheme.success,
                        tint: AppTheme.successTint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionTile(
                        label: 'Register\nVisitor',
                        icon: Icons.person_add_alt_1,
                        color: AppTheme.primary,
                        filled: true,
                        onTap: () => _open(context, const VisitorFormPage()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionTile(
                        label: 'Visitor\nList',
                        icon: Icons.people,
                        color: AppTheme.success,
                        onTap: () => _open(context, const VisitorListPage()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionTile(
                        label: 'Scan\nQR Code',
                        icon: Icons.qr_code_scanner,
                        color: AppTheme.accentPink,
                        onTap: () => _open(context, const QrScannerPage()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Recent Visitors',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _open(context, const VisitorListPage()),
                      child: const Text('View all  ›'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (isLoading) const LinearProgressIndicator(),
                if (state.visitors.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 45,
                          color: AppTheme.textSecondary,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'No visitors yet',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text('Registered visitors will appear here.'),
                      ],
                    ),
                  )
                else
                  ...state.visitors.reversed
                      .take(5)
                      .map(
                        (visitor) => VisitorCard(
                          visitor: visitor,
                          timeLabel: _activityTime(visitor),
                          onTap: () => _open(
                            context,
                            VisitorDetailsPage(visitorId: visitor.id),
                          ),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ActionTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? Colors.white : AppTheme.textPrimary;

    return Material(
      color: filled ? AppTheme.primaryDark : Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 1,
      shadowColor: Colors.black26,
      child: Ink(
        decoration: BoxDecoration(
          gradient: filled ? AppTheme.tileGradient : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
            child: Column(
              children: [
                Icon(icon, color: filled ? Colors.white : color, size: 30),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: filled
                        ? Colors.white.withValues(alpha: 0.25)
                        : color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: filled ? Colors.white : color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
