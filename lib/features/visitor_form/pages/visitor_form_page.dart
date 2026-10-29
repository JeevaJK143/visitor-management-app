import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/visitor_model.dart';
import '../../../shared/utils/visitor_actions.dart';
import '../../../shared/widgets/bottom_action_bar.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/gradient_app_bar.dart';
import '../../visitor_details/pages/visitor_details_page.dart';
import '../../visitors/bloc/visitor_bloc.dart';
import '../../visitors/bloc/visitor_event.dart';
import '../../visitors/bloc/visitor_state.dart';

class VisitorFormPage extends StatefulWidget {
  final Visitor? visitor;

  const VisitorFormPage({super.key, this.visitor});

  @override
  State<VisitorFormPage> createState() => _VisitorFormPageState();
}

class _VisitorFormPageState extends State<VisitorFormPage> {
  static const _visitorTypes = ['Customer', 'Vendor', 'Other'];
  static const _projects = ['Project A', 'Project B', 'Project C'];

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _emailController;
  late final TextEditingController _purposeController;

  String _visitorType = _visitorTypes.first;
  String _project = _projects.first;

  bool get isEditing => widget.visitor != null;

  @override
  void initState() {
    super.initState();

    final visitor = widget.visitor;

    _nameController = TextEditingController(text: visitor?.name ?? '');
    _mobileController = TextEditingController(text: visitor?.mobile ?? '');
    _emailController = TextEditingController(text: visitor?.email ?? '');
    _purposeController = TextEditingController(text: visitor?.purpose ?? '');

    if (visitor != null) {
      if (_visitorTypes.contains(visitor.visitorType)) {
        _visitorType = visitor.visitorType;
      }
      if (_projects.contains(visitor.project)) {
        _project = visitor.project;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final bloc = context.read<VisitorBloc>();
    final email = _emailController.text.trim();

    if (isEditing) {
      bloc.add(
        EditVisitor(
          widget.visitor!.copyWith(
            name: _nameController.text.trim(),
            mobile: _mobileController.text.trim(),
            email: email.isEmpty ? null : email,
            clearEmail: email.isEmpty,
            visitorType: _visitorType,
            project: _project,
            purpose: _purposeController.text.trim(),
          ),
        ),
      );
    } else {
      bloc.add(
        RegisterVisitor(
          name: _nameController.text.trim(),
          mobile: _mobileController.text.trim(),
          email: email.isEmpty ? null : email,
          visitorType: _visitorType,
          project: _project,
          purpose: _purposeController.text.trim(),
        ),
      );
    }
  }

  void _onStateChanged(BuildContext context, VisitorState state) {
    if (state.status == VisitorStatus.success) {
      showAppSnackBar(
        context,
        state.successMessage ??
            (isEditing
                ? 'Visitor updated successfully.'
                : 'Visitor registered successfully.'),
      );

      final created = state.selectedVisitor;

      if (!isEditing && created != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VisitorDetailsPage(visitorId: created.id),
          ),
        );
      } else {
        Navigator.pop(context, true);
      }
    } else if (state.status == VisitorStatus.failure) {
      showAppSnackBar(
        context,
        state.errorMessage ?? 'Unable to save visitor.',
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VisitorBloc, VisitorState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          (ModalRoute.of(context)?.isCurrent ?? false) &&
          (current.status == VisitorStatus.success ||
              current.status == VisitorStatus.failure),
      listener: _onStateChanged,
      child: Scaffold(
        appBar: GradientAppBar(
          title: isEditing ? 'Edit Visitor' : 'Register Visitor',
        ),
        bottomNavigationBar: BottomActionBar(
          child: BlocBuilder<VisitorBloc, VisitorState>(
            builder: (context, state) {
              final isSaving = state.status == VisitorStatus.submitting;

              return Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      label: 'Cancel',
                      outlined: true,
                      onPressed: isSaving ? null : () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      label: isSaving
                          ? 'Saving...'
                          : isEditing
                          ? 'Save Changes'
                          : 'Register',
                      icon: isEditing
                          ? Icons.save_outlined
                          : Icons.person_add_alt_1,
                      isLoading: isSaving,
                      onPressed: _submit,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Visitor Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Enter the visitor details below.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 24),
                      CustomTextField(
                        label: 'Visitor Name *',
                        hint: 'Enter full name',
                        icon: Icons.person_outline,
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Visitor name is required'
                            : null,
                      ),
                      const SizedBox(height: 18),
                      CustomTextField(
                        label: 'Mobile Number *',
                        hint: '10-digit mobile number',
                        icon: Icons.phone_outlined,
                        controller: _mobileController,
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          final mobile = value?.trim() ?? '';

                          if (mobile.isEmpty) {
                            return 'Mobile number is required';
                          }
                          if (!RegExp(r'^[0-9]{10}$').hasMatch(mobile)) {
                            return 'Enter exactly 10 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      CustomTextField(
                        label: 'Email Address',
                        hint: 'Enter email (optional)',
                        icon: Icons.email_outlined,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final email = value?.trim() ?? '';

                          if (email.isNotEmpty &&
                              !RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              ).hasMatch(email)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      _dropdown(
                        label: 'Visitor Type *',
                        icon: Icons.badge_outlined,
                        value: _visitorType,
                        options: _visitorTypes,
                        onChanged: (v) => setState(() => _visitorType = v),
                      ),
                      const SizedBox(height: 18),
                      _dropdown(
                        label: 'Project *',
                        icon: Icons.apartment_outlined,
                        value: _project,
                        options: _projects,
                        onChanged: (v) => setState(() => _project = v),
                      ),
                      const SizedBox(height: 18),
                      CustomTextField(
                        label: 'Purpose of Visit *',
                        hint: 'Why is the visitor visiting?',
                        icon: Icons.description_outlined,
                        controller: _purposeController,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Purpose of visit is required'
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.primary),
          ),
          items: [
            for (final option in options)
              DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}
