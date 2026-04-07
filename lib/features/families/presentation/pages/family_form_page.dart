import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/models/family_model.dart';
import '../bloc/family_bloc.dart';

class FamilyFormPage extends StatefulWidget {
  final String streetId;
  final FamilyModel? family;

  const FamilyFormPage({super.key, required this.streetId, this.family});

  @override
  State<FamilyFormPage> createState() => _FamilyFormPageState();
}

class _FamilyFormPageState extends State<FamilyFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _familyHeadController;
  late TextEditingController _landlineController;
  late TextEditingController _streetController;
  late TextEditingController _buildingController;
  late TextEditingController _floorController;
  late TextEditingController _flatController;
  late TextEditingController _streetFromController;
  DateTime? _marriageDate;

  @override
  void initState() {
    super.initState();
    _familyHeadController = TextEditingController(
      text: widget.family?.familyHead ?? '',
    );
    _landlineController = TextEditingController(
      text: widget.family?.landline ?? '',
    );
    _streetController = TextEditingController(
      text: widget.family?.addressInfo.street ?? '',
    );
    _buildingController = TextEditingController(
      text: widget.family?.addressInfo.buildingNumber ?? '',
    );
    _floorController = TextEditingController(
      text: widget.family?.addressInfo.floorNumber ?? '',
    );
    _flatController = TextEditingController(
      text: widget.family?.addressInfo.flatNumber ?? '',
    );
    _streetFromController = TextEditingController(
      text: widget.family?.addressInfo.streetFrom ?? '',
    );
    _marriageDate = widget.family?.marriageDate;
  }

  @override
  void dispose() {
    _familyHeadController.dispose();
    _landlineController.dispose();
    _streetController.dispose();
    _buildingController.dispose();
    _floorController.dispose();
    _flatController.dispose();
    _streetFromController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _marriageDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _marriageDate = picked;
      });
    }
  }

  void _saveFamily() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final address = AddressInfo(
        street: _streetController.text,
        buildingNumber: _buildingController.text,
        floorNumber: _floorController.text,
        flatNumber: _flatController.text,
        streetFrom: _streetFromController.text,
      );

      if (widget.family == null) {
        final newFamily = FamilyModel(
          id: const Uuid().v4(),
          streetId: widget.streetId,
          familyHead: _familyHeadController.text,
          marriageDate: _marriageDate,
          landline: _landlineController.text,
          addressInfo: address,
          createdAt: now,
          updatedAt: now,
        );
        context.read<FamilyBloc>().add(AddFamily(newFamily));
      } else {
        final updatedFamily = widget.family!.copyWith(
          familyHead: _familyHeadController.text,
          marriageDate: _marriageDate,
          landline: _landlineController.text,
          addressInfo: address,
          updatedAt: now,
        );
        context.read<FamilyBloc>().add(UpdateFamily(updatedFamily));
      }
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.family == null ? l10n.addFamily : l10n.editFamily),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _familyHeadController,
                decoration: InputDecoration(labelText: l10n.familyHead),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? l10n.requiredField
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _landlineController,
                decoration: InputDecoration(labelText: l10n.landline),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? l10n.requiredField
                            : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  _marriageDate == null
                      ? l10n.selectMarriageDate
                      : l10n.marriageDate(
                        DateFormat('yyyy-MM-dd').format(_marriageDate!),
                      ),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.address,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _buildingController,
                decoration: InputDecoration(labelText: l10n.buildingNumber),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _floorController,
                decoration: InputDecoration(labelText: l10n.floorNumber),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _flatController,
                decoration: InputDecoration(labelText: l10n.flatNumber),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _streetController,
                decoration: InputDecoration(labelText: l10n.streetName),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _streetFromController,
                decoration: InputDecoration(labelText: l10n.streetFrom),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveFamily,
                child: Text(l10n.saveFamily),
              ),
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, authState) {
                  final isSuperAdmin = (authState is AuthAuthenticated) && (authState.profile?.isSuperAdmin ?? false);
                  if (widget.family != null && isSuperAdmin) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: Text(
                            l10n.delete,
                            style: const TextStyle(color: Colors.red),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(l10n.delete),
                                content: Text(l10n.confirmDeleteFamily),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text(l10n.cancel),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      context.read<FamilyBloc>().add(
                                        DeleteFamily(
                                          widget.family!.id,
                                          widget.streetId,
                                        ),
                                      );
                                      context.pop();
                                    },
                                    child: Text(
                                      l10n.delete,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
