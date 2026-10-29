import '../models/visitor_model.dart';
import '../services/visitor_api_service.dart';

class VisitorRepository {
  final VisitorApiService _apiService;

  VisitorRepository(this._apiService);

  Future<List<Visitor>> getVisitors() {
    return _apiService.getVisitors();
  }

  Future<Visitor> getVisitor(String id) {
    return _apiService.getVisitor(id);
  }

  Future<Visitor> createVisitor({
    required String name,
    required String mobile,
    String? email,
    required String visitorType,
    required String project,
    required String purpose,
  }) {
    final visitor = Visitor(
      id: '',
      name: name.trim(),
      mobile: mobile.trim(),
      email: email == null || email.trim().isEmpty ? null : email.trim(),
      visitorType: visitorType,
      project: project,
      purpose: purpose.trim(),
      status: 'Registered',
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );

    return _apiService.createVisitor(visitor);
  }

  Future<Visitor> updateVisitor(Visitor visitor) {
    return _apiService.updateVisitor(visitor);
  }

  Future<void> deleteVisitor(String id) {
    return _apiService.deleteVisitor(id);
  }

  Future<Visitor> checkIn(Visitor visitor) async {
    if (visitor.status != 'Registered') {
      throw StateError(
        'Only registered visitors can check in.',
      );
    }

    final updated = visitor.copyWith(
      status: 'Checked In',
      checkInTime: DateTime.now().toUtc().toIso8601String(),
      clearCheckOutTime: true,
    );

    return _apiService.updateVisitor(updated);
  }

  Future<Visitor> checkOut(Visitor visitor) async {
    if (visitor.status != 'Checked In') {
      throw StateError(
        'Only checked-in visitors can check out.',
      );
    }

    final updated = visitor.copyWith(
      status: 'Checked Out',
      checkOutTime: DateTime.now().toUtc().toIso8601String(),
    );

    return _apiService.updateVisitor(updated);
  }

  void dispose() {
    _apiService.dispose();
  }
}