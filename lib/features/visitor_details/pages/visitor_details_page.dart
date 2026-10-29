import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/visitor_model.dart';
import '../../../shared/utils/visitor_actions.dart';
import '../../../shared/widgets/bottom_action_bar.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/gradient_app_bar.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../visitor_form/pages/visitor_form_page.dart';
import '../../visitors/bloc/visitor_bloc.dart';
import '../../visitors/bloc/visitor_event.dart';
import '../../visitors/bloc/visitor_state.dart';

class VisitorDetailsPage extends StatefulWidget {
  final String visitorId;

  const VisitorDetailsPage({super.key, required this.visitorId});

  @override
  State<VisitorDetailsPage> createState() => _VisitorDetailsPageState();
}

class _VisitorDetailsPageState extends State<VisitorDetailsPage> {
  @override
  void initState() {
    super.initState();

    context.read<VisitorBloc>().add(LoadVisitorDetails(widget.visitorId));
  }

  Visitor? _findVisitor(VisitorState state) {
    if (state.selectedVisitor?.id == widget.visitorId) {
      return state.selectedVisitor;
    }

    for (final item in state.visitors) {
      if (item.id == widget.visitorId) return item;
    }
    return null;
  }

  bool _exists(VisitorState state) =>
      state.visitors.any((v) => v.id == widget.visitorId);

  @override
  Widget build(BuildContext context) {
    return BlocListener<VisitorBloc, VisitorState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          (ModalRoute.of(context)?.isCurrent ?? false) &&
          (current.status == VisitorStatus.success ||
              current.status == VisitorStatus.failure),
      listener: (context, state) {
        if (state.status == VisitorStatus.success) {
          showAppSnackBar(
            context,
            state.successMessage ?? 'Visitor updated successfully.',
          );

          if (!_exists(state)) Navigator.pop(context);
        } else {
          showAppSnackBar(
            context,
            state.errorMessage ?? 'The operation failed.',
            error: true,
          );
        }
      },
      child: Scaffold(
        appBar: const GradientAppBar(
          title: 'Visitor Details',
        ),
        bottomNavigationBar: BlocBuilder<VisitorBloc, VisitorState>(
          builder: (context, state) {
            final visitor = _findVisitor(state);

            return visitor == null
                ? const SizedBox.shrink()
                : _buildFooter(context, visitor, state);
          },
        ),
        body: BlocBuilder<VisitorBloc, VisitorState>(
          builder: (context, state) {
            final visitor = _findVisitor(state);

            if (visitor == null) {
              if (state.status == VisitorStatus.detailsFailure) {
                return EmptyStateWidget(
                  icon: Icons.person_off_outlined,
                  title: 'Visitor not found',
                  message: state.errorMessage,
                  actionLabel: 'Retry',
                  onAction: () => context.read<VisitorBloc>().add(
                    LoadVisitorDetails(widget.visitorId),
                  ),
                );
              }
              return const LoadingView();
            }

            return _buildDetails(context, visitor, state);
          },
        ),
      ),
    );
  }

  Widget _buildDetails(
    BuildContext context,
    Visitor visitor,
    VisitorState state,
  ) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.primarySoft,
                      child: Text(
                        visitor.name.isEmpty
                            ? '?'
                            : visitor.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        visitor.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    StatusChip(status: visitor.status),
                  ],
                ),
                const SizedBox(height: 20),
                _infoRow('Visitor ID', visitor.id),
                _infoRow('Mobile', visitor.mobile),
                _infoRow('Email', visitor.email ?? 'Not provided'),
                _infoRow('Visitor Type', visitor.visitorType),
                _infoRow('Project', visitor.project),
                _infoRow('Purpose', visitor.purpose),
                _infoRow('Registered', _formatDate(visitor.createdAt)),
                _infoRow('Check-in Time', _formatDate(visitor.checkInTime)),
                _infoRow('Check-out Time', _formatDate(visitor.checkOutTime)),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  'Visitor QR Code',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Scan this code to retrieve the visitor record.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                QrImageView(
                  data: visitor.id,
                  version: QrVersions.auto,
                  size: 210,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
                SelectableText(
                  visitor.id,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    Visitor visitor,
    VisitorState state,
  ) {
    final busy = state.status == VisitorStatus.submitting;
    final bloc = context.read<VisitorBloc>();

    return BottomActionBar(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: 'Delete',
                  icon: Icons.delete_outline,
                  outlined: true,
                  color: AppTheme.danger,
                  onPressed: busy
                      ? null
                      : () => confirmAndDeleteVisitor(context, visitor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  outlined: true,
                  onPressed: busy
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VisitorFormPage(visitor: visitor),
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (visitor.status == 'Registered')
            CustomButton(
              label: 'Check In Visitor',
              icon: Icons.login,
              color: AppTheme.success,
              isLoading: busy,
              onPressed: () => bloc.add(CheckInVisitor(visitor.id)),
            )
          else if (visitor.status == 'Checked In')
            CustomButton(
              label: 'Check Out Visitor',
              icon: Icons.logout,
              color: AppTheme.warning,
              isLoading: busy,
              onPressed: () => bloc.add(CheckOutVisitor(visitor.id)),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'This visit is complete. Check-in is no longer available.',
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) return '—';

    final date = DateTime.tryParse(value);
    if (date == null) return value;

    final local = date.toLocal();

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    return '${twoDigits(local.day)}/'
        '${twoDigits(local.month)}/'
        '${local.year}  '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }
}
