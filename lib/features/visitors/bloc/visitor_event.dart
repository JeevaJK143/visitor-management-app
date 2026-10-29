import 'package:equatable/equatable.dart';

import '../../../data/models/visitor_model.dart';

abstract class VisitorEvent extends Equatable {
  const VisitorEvent();

  @override
  List<Object?> get props => [];
}

class LoadVisitors extends VisitorEvent {
  const LoadVisitors();
}

class SearchVisitors extends VisitorEvent {
  final String query;

  const SearchVisitors(this.query);

  @override
  List<Object?> get props => [query];
}

class LoadVisitorDetails extends VisitorEvent {
  final String id;

  const LoadVisitorDetails(this.id);

  @override
  List<Object?> get props => [id];
}

class RegisterVisitor extends VisitorEvent {
  final String name;
  final String mobile;
  final String? email;
  final String visitorType;
  final String project;
  final String purpose;

  const RegisterVisitor({
    required this.name,
    required this.mobile,
    this.email,
    required this.visitorType,
    required this.project,
    required this.purpose,
  });

  @override
  List<Object?> get props => [
    name, mobile, email, visitorType, project, purpose,
  ];
}

class EditVisitor extends VisitorEvent {
  final Visitor visitor;

  const EditVisitor(this.visitor);

  @override
  List<Object?> get props => [visitor];
}

class DeleteVisitor extends VisitorEvent {
  final String id;

  const DeleteVisitor(this.id);

  @override
  List<Object?> get props => [id];
}

class CheckInVisitor extends VisitorEvent {
  final String id;

  const CheckInVisitor(this.id);

  @override
  List<Object?> get props => [id];
}

class CheckOutVisitor extends VisitorEvent {
  final String id;

  const CheckOutVisitor(this.id);

  @override
  List<Object?> get props => [id];
}