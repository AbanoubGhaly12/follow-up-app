import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/models/street_model.dart';
import '../bloc/street_bloc.dart';
import '../bloc/street_event.dart';

class StreetFormPage extends StatefulWidget {
  final String zoneId;
  final StreetModel? street;

  const StreetFormPage({super.key, required this.zoneId, this.street});

  @override
  State<StreetFormPage> createState() => _StreetFormPageState();
}

class _StreetFormPageState extends State<StreetFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.street?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveStreet() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();

      if (widget.street == null) {
        // Add
        final newStreet = StreetModel(
          id: const Uuid().v4(),
          zoneId: widget.zoneId,
          name: _nameController.text,
          createdAt: now,
          updatedAt: now,
        );
        context.read<StreetBloc>().add(AddStreet(newStreet));
      } else {
        // Update
        final updatedStreet = widget.street!.copyWith(
          name: _nameController.text,
          updatedAt: now,
        );
        context.read<StreetBloc>().add(UpdateStreet(updatedStreet));
      }
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.street == null ? l10n.addStreet : l10n.editStreet),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.streetName),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? l10n.requiredField
                            : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveStreet,
                  child: Text(l10n.saveStreet),
                ),
              ),
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, authState) {
                  final isSuperAdmin = (authState is AuthAuthenticated) &&
                      (authState.profile?.isSuperAdmin ?? false);
                  if (widget.street != null && isSuperAdmin) {
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
                              builder:
                                  (ctx) => AlertDialog(
                                    title: Text(l10n.delete),
                                    content: Text(l10n.confirmDeleteStreet),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: Text(l10n.cancel),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          context.read<StreetBloc>().add(
                                            DeleteStreet(
                                              widget.street!.id,
                                              widget.zoneId,
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
