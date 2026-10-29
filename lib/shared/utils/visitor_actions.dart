import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/visitor_model.dart';
import '../../features/visitors/bloc/visitor_bloc.dart';
import '../../features/visitors/bloc/visitor_event.dart';
import '../../features/visitors/bloc/visitor_state.dart';

Future<bool> confirmAndDeleteVisitor(
  BuildContext context,
  Visitor visitor,
) async {
  final bloc = context.read<VisitorBloc>();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete Visitor?'),
      content: Text(
        'Are you sure you want to delete ${visitor.name}? '
        'This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.danger,
            minimumSize: const Size(90, 44),
          ),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed != true) return false;

  bloc.add(DeleteVisitor(visitor.id));
  return true;
}

Future<void> refreshVisitors(BuildContext context) async {
  final bloc = context.read<VisitorBloc>();
  bloc.add(const LoadVisitors());

  await bloc.stream.firstWhere(
    (s) =>
        s.status == VisitorStatus.loaded || s.status == VisitorStatus.failure,
  );
}

void showAppSnackBar(
  BuildContext context,
  String message, {
  bool error = false,
  Duration duration = const Duration(seconds: 4),
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        content: Text(message),
        backgroundColor: error ? AppTheme.danger : AppTheme.success,
      ),
    );
}
