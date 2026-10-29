import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/visitor_model.dart';
import '../../../data/repositories/visitor_repository.dart';
import 'visitor_event.dart';
import 'visitor_state.dart';

class VisitorBloc extends Bloc<VisitorEvent, VisitorState> {
  final VisitorRepository repository;

  VisitorBloc({required this.repository})
      : super(const VisitorState()) {
    on<LoadVisitors>(_onLoadVisitors);
    on<SearchVisitors>(_onSearchVisitors);
    on<LoadVisitorDetails>(_onLoadVisitorDetails);
    on<RegisterVisitor>(_onRegisterVisitor);
    on<EditVisitor>(_onEditVisitor);
    on<DeleteVisitor>(_onDeleteVisitor);
    on<CheckInVisitor>(_onCheckInVisitor);
    on<CheckOutVisitor>(_onCheckOutVisitor);
  }

  Future<void> _onLoadVisitors(
      LoadVisitors event,
      Emitter<VisitorState> emit,
      ) async {
    emit(state.copyWith(
      status: VisitorStatus.loading,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final visitors = await repository.getVisitors();

      emit(state.copyWith(
        status: VisitorStatus.loaded,
        visitors: List.unmodifiable(visitors),
        clearSelectedVisitor: true,
        clearError: true,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: VisitorStatus.failure,
        errorMessage: _message(error),
      ));
    }
  }

  void _onSearchVisitors(
      SearchVisitors event,
      Emitter<VisitorState> emit,
      ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  Future<void> _onLoadVisitorDetails(
      LoadVisitorDetails event,
      Emitter<VisitorState> emit,
      ) async {
    emit(state.copyWith(
      status: VisitorStatus.detailsLoading,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final visitor = await repository.getVisitor(event.id);

      emit(state.copyWith(
        status: VisitorStatus.detailsLoaded,
        selectedVisitor: visitor,
        visitors: _replaceVisitor(state.visitors, visitor),
        clearError: true,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: VisitorStatus.detailsFailure,
        errorMessage: _message(error),
      ));
    }
  }

  Future<List<Visitor>> _refreshOr(List<Visitor> fallback) async {
    try {
      return await repository.getVisitors();
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _onRegisterVisitor(
      RegisterVisitor event,
      Emitter<VisitorState> emit,
      ) async {
    emit(state.copyWith(
      status: VisitorStatus.submitting,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final created = await repository.createVisitor(
        name: event.name,
        mobile: event.mobile,
        email: event.email,
        visitorType: event.visitorType,
        project: event.project,
        purpose: event.purpose,
      );

      final visitors = await _refreshOr(
        _replaceVisitor(state.visitors, created),
      );

      emit(state.copyWith(
        status: VisitorStatus.success,
        visitors: List.unmodifiable(visitors),
        selectedVisitor: created,
        successMessage: 'Visitor registered successfully.',
        clearError: true,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: VisitorStatus.failure,
        errorMessage: _message(error),
      ));
    }
  }

  Future<void> _onEditVisitor(
      EditVisitor event,
      Emitter<VisitorState> emit,
      ) async {
    emit(state.copyWith(
      status: VisitorStatus.submitting,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final updated = await repository.updateVisitor(event.visitor);
      final visitors = await _refreshOr(
        _replaceVisitor(state.visitors, updated),
      );

      emit(state.copyWith(
        status: VisitorStatus.success,
        visitors: List.unmodifiable(visitors),
        selectedVisitor: updated,
        successMessage: 'Visitor updated successfully.',
        clearError: true,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: VisitorStatus.failure,
        errorMessage: _message(error),
      ));
    }
  }

  Future<void> _onDeleteVisitor(
      DeleteVisitor event,
      Emitter<VisitorState> emit,
      ) async {
    emit(state.copyWith(
      status: VisitorStatus.submitting,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      await repository.deleteVisitor(event.id);
      final visitors = await _refreshOr(
        state.visitors.where((v) => v.id != event.id).toList(),
      );

      emit(state.copyWith(
        status: VisitorStatus.success,
        visitors: List.unmodifiable(visitors),
        clearSelectedVisitor:
        state.selectedVisitor?.id == event.id,
        successMessage: 'Visitor deleted successfully.',
        clearError: true,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: VisitorStatus.failure,
        errorMessage: _message(error),
      ));
    }
  }

  Future<void> _onCheckInVisitor(
      CheckInVisitor event,
      Emitter<VisitorState> emit,
      ) async {
    await _updateVisitStatus(
      event.id,
      emit,
      checkIn: true,
    );
  }

  Future<void> _onCheckOutVisitor(
      CheckOutVisitor event,
      Emitter<VisitorState> emit,
      ) async {
    await _updateVisitStatus(
      event.id,
      emit,
      checkIn: false,
    );
  }

  Future<void> _updateVisitStatus(
      String id,
      Emitter<VisitorState> emit, {
        required bool checkIn,
      }) async {
    emit(state.copyWith(
      status: VisitorStatus.submitting,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final visitor = await repository.getVisitor(id);

      final updated = checkIn
          ? await repository.checkIn(visitor)
          : await repository.checkOut(visitor);

      final visitors = await _refreshOr(
        _replaceVisitor(state.visitors, updated),
      );

      emit(state.copyWith(
        status: VisitorStatus.success,
        visitors: List.unmodifiable(visitors),
        selectedVisitor: updated,
        successMessage: checkIn
            ? 'Visitor checked in successfully.'
            : 'Visitor checked out successfully.',
        clearError: true,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: VisitorStatus.failure,
        errorMessage: _message(error),
      ));
    }
  }

  List<Visitor> _replaceVisitor(
      List<Visitor> visitors,
      Visitor updated,
      ) {
    final exists = visitors.any((v) => v.id == updated.id);

    if (!exists) return [...visitors, updated];

    return visitors
        .map((v) => v.id == updated.id ? updated : v)
        .toList();
  }

  String _message(Object error) {
    if (error is StateError) return error.message;
    return error.toString().replaceFirst('Exception: ', '');
  }
}