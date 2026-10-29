import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/visitor_actions.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/gradient_app_bar.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/visitor_card.dart';
import '../../visitor_details/pages/visitor_details_page.dart';
import '../../visitor_form/pages/visitor_form_page.dart';
import '../bloc/visitor_bloc.dart';
import '../bloc/visitor_event.dart';
import '../bloc/visitor_state.dart';

class VisitorListPage extends StatefulWidget {
  const VisitorListPage({super.key});

  @override
  State<VisitorListPage> createState() => _VisitorListPageState();
}

class _VisitorListPageState extends State<VisitorListPage> {
  late final TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();
  bool _searchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: context.read<VisitorBloc>().state.searchQuery,
    );
    _searchFocusNode.addListener(
      () => setState(() => _searchFocused = _searchFocusNode.hasFocus),
    );
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _open(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

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
          showAppSnackBar(context, state.successMessage ?? 'Done.');
        } else if (state.visitors.isNotEmpty) {
          showAppSnackBar(
            context,
            state.errorMessage ?? 'The operation failed.',
            error: true,
          );
        }
      },
      child: Scaffold(
        appBar: GradientAppBar(
          icon: Icons.people,
          title: 'All Visitors',
          actions: [
            IconButton(
              tooltip: 'Register visitor',
              onPressed: () => _open(const VisitorFormPage()),
              icon: const Icon(Icons.person_add_alt_1),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _searchFocused
                        ? AppTheme.primary.withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.06),
                    width: _searchFocused ? 1.4 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _searchFocused
                          ? AppTheme.primary.withValues(alpha: 0.20)
                          : Colors.black.withValues(alpha: 0.08),
                      blurRadius: _searchFocused ? 18 : 12,
                      spreadRadius: -4,
                      offset: Offset(0, _searchFocused ? 6 : 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppTheme.primary.withValues(
                          alpha: _searchFocused ? 0.16 : 0.07,
                        ),
                      ),
                      child: Icon(
                        Icons.search,
                        size: 18,
                        color: _searchFocused
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        textInputAction: TextInputAction.search,
                        cursorColor: AppTheme.primary,
                        onChanged: (value) => context
                            .read<VisitorBloc>()
                            .add(SearchVisitors(value)),
                        decoration: const InputDecoration(
                          hintText: 'Search name or mobile number',
                          isDense: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchController,
                      builder: (context, value, _) => value.text.isEmpty
                          ? const SizedBox(width: 12)
                          : IconButton(
                              tooltip: 'Clear search',
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(
                                Icons.close,
                                size: 18,
                                color: AppTheme.textSecondary,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                context
                                    .read<VisitorBloc>()
                                    .add(const SearchVisitors(''));
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<VisitorBloc, VisitorState>(
                builder: (context, state) => _buildBody(context, state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, VisitorState state) {
    final loadingFirstTime = (state.status == VisitorStatus.initial ||
            state.status == VisitorStatus.loading) &&
        state.visitors.isEmpty;

    if (loadingFirstTime) return const LoadingView();

    if (state.status == VisitorStatus.failure && state.visitors.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => refreshVisitors(context),
        child: EmptyStateWidget(
          icon: Icons.cloud_off_outlined,
          title: 'Unable to load visitors',
          message: state.errorMessage,
          actionLabel: 'Try Again',
          onAction: () =>
              context.read<VisitorBloc>().add(const LoadVisitors()),
        ),
      );
    }

    final visitors = state.filteredVisitors;

    if (visitors.isEmpty) {
      final searching = state.searchQuery.trim().isNotEmpty;

      return RefreshIndicator(
        onRefresh: () => refreshVisitors(context),
        child: EmptyStateWidget(
          icon: searching ? Icons.search_off : Icons.people_outline,
          title: searching ? 'No matching visitors' : 'No visitor records',
          message: searching
              ? 'Try a different name or mobile number.'
              : 'Registered visitors will appear here.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => refreshVisitors(context),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: visitors.length,
        itemBuilder: (context, index) {
          final visitor = visitors[index];

          return VisitorCard(
            visitor: visitor,
            onTap: () => _open(VisitorDetailsPage(visitorId: visitor.id)),
            onEdit: () => _open(VisitorFormPage(visitor: visitor)),
            onDelete: () => confirmAndDeleteVisitor(context, visitor),
          );
        },
      ),
    );
  }
}
