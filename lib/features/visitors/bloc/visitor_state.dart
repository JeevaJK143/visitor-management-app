import 'package:equatable/equatable.dart';

import '../../../data/models/visitor_model.dart';

enum VisitorStatus {
  initial,
  loading,
  loaded,
  submitting,
  success,
  failure,
  detailsLoading,
  detailsLoaded,
  detailsFailure,
}

class VisitorState extends Equatable {
  final VisitorStatus status;
  final List<Visitor> visitors;
  final Visitor? selectedVisitor;
  final String searchQuery;
  final String? errorMessage;
  final String? successMessage;

  const VisitorState({
    this.status = VisitorStatus.initial,
    this.visitors = const [],
    this.selectedVisitor,
    this.searchQuery = '',
    this.errorMessage,
    this.successMessage,
  });

  List<Visitor> get filteredVisitors {
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) return visitors;

    return visitors.where((visitor) {
      return visitor.name.toLowerCase().contains(query) ||
          visitor.mobile.toLowerCase().contains(query);
    }).toList();
  }

  bool _isToday(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return false;

    final parsed = DateTime.tryParse(timestamp);
    if (parsed == null) return false;

    final date = parsed.toLocal();
    final now = DateTime.now();

    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  int get totalVisitorsToday =>
      visitors.where((v) => _isToday(v.createdAt)).length;

  int get currentlyCheckedIn =>
      visitors.where((v) => v.status == 'Checked In').length;

  int get checkedOutToday =>
      visitors.where((v) => _isToday(v.checkOutTime)).length;

  VisitorState copyWith({
    VisitorStatus? status,
    List<Visitor>? visitors,
    Visitor? selectedVisitor,
    bool clearSelectedVisitor = false,
    String? searchQuery,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return VisitorState(
      status: status ?? this.status,
      visitors: visitors ?? this.visitors,
      selectedVisitor: clearSelectedVisitor
          ? null
          : (selectedVisitor ?? this.selectedVisitor),
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError
          ? null
          : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    visitors,
    selectedVisitor,
    searchQuery,
    errorMessage,
    successMessage,
  ];
}