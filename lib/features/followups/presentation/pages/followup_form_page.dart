import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../data/models/followup_model.dart';
import '../bloc/followup_bloc.dart';
import '../bloc/followup_event.dart';

class FollowupFormPage extends StatefulWidget {
  final String familyId;
  final String? familyName;
  final String? memberId;
  final String? memberName;

  const FollowupFormPage({
    super.key,
    required this.familyId,
    this.familyName,
    this.memberId,
    this.memberName,
  });

  @override
  State<FollowupFormPage> createState() => _FollowupFormPageState();
}

class _FollowupFormPageState extends State<FollowupFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  FollowupType _selectedType = FollowupType.phone;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final followup = FollowupModel(
        id: const Uuid().v4(),
        familyId: widget.familyId,
        familyName: widget.familyName,
        memberId: widget.memberId,
        memberName: widget.memberName,
        followupDate: _selectedDate,
        notes: _notesController.text,
        type: _selectedType,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      context.read<FollowupBloc>().add(AddFollowup(followup, widget.familyId));
      context.pop();
    }
  }

  String _getTypeLabel(FollowupType type, AppLocalizations l10n) {
    switch (type) {
      case FollowupType.phone:
        return l10n.typePhone;
      case FollowupType.visit:
        return l10n.typeVisit;
      case FollowupType.churchMeeting:
        return l10n.typeMeeting;
      case FollowupType.onlineCall:
        return l10n.typeOnline;
      default:
        return l10n.typeOther;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addFollowup)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.memberName != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${l10n.members}: ${widget.memberName}",
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Date Picker
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.followupDate,
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(dateFormat.format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 16),

              // Type Dropdown
              DropdownButtonFormField<FollowupType>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: l10n.followupType,
                  border: const OutlineInputBorder(),
                ),
                items:
                    FollowupType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(_getTypeLabel(type, l10n)),
                      );
                    }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedType = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Notes
              Expanded(
                child: TextFormField(
                  controller: _notesController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    labelText: l10n.followupNotes,
                    alignLabelWithHint: true,
                    border: const OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? l10n.requiredField
                              : null,
                ),
              ),
              const SizedBox(height: 24),

              // Save
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
