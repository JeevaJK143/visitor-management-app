import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/visitor_repository.dart';
import 'data/services/visitor_api_service.dart';
import 'features/dashboard/pages/main_navigation_page.dart';
import 'features/visitors/bloc/visitor_bloc.dart';
import 'features/visitors/bloc/visitor_event.dart';

class VisitorApp extends StatelessWidget {
  const VisitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<VisitorRepository>(
      create: (_) => VisitorRepository(
        VisitorApiService(
          baseUrl: AppConstants.apiBaseUrl,
        ),
      ),
      dispose: (repository) => repository.dispose(),
      child: Builder(
        builder: (context) {
          return BlocProvider<VisitorBloc>(
            create: (_) => VisitorBloc(
              repository: context.read<VisitorRepository>(),
            )..add(const LoadVisitors()),
            child: MaterialApp(
              title: 'Visitor Management',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              home: const MainNavigationPage(),
            ),
          );
        },
      ),
    );
  }
}