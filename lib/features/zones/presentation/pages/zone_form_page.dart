import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../auth/presentation/cubit/user_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../data/models/zone_model.dart';
import '../bloc/zone_bloc.dart';

class ZoneFormPage extends StatefulWidget {
  final ZoneModel? zone;

  const ZoneFormPage({super.key, this.zone});

  @override
  State<ZoneFormPage> createState() => _ZoneFormPageState();
}

class _ZoneFormPageState extends State<ZoneFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _tagController;
  late TextEditingController _descriptionController;
  List<String> _selectedAdminUids = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.zone?.name ?? '');
    _tagController = TextEditingController(text: widget.zone?.tag ?? '');
    _descriptionController = TextEditingController(
      text: widget.zone?.description ?? '',
    );
    _selectedAdminUids = List<String>.from(widget.zone?.zoneAdmins ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveZone() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();

      if (widget.zone == null) {
        // Add
        final newZone = ZoneModel(
          id: const Uuid().v4(),
          name: _nameController.text,
          tag: 'ZONE-${const Uuid().v4()}',
          description: _descriptionController.text,
          zoneAdmins: _selectedAdminUids,
          createdAt: now,
          updatedAt: now,
        );
        context.read<ZoneBloc>().add(AddZone(newZone));
      } else {
        // Update
        final updatedZone = widget.zone!.copyWith(
          name: _nameController.text,
          tag: widget.zone!.tag,
          description: _descriptionController.text,
          zoneAdmins: _selectedAdminUids,
          updatedAt: now,
        );
        context.read<ZoneBloc>().add(UpdateZone(updatedZone));
      }
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.zone == null ? l10n.addZone : l10n.editZone),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.name),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? l10n.requiredField
                            : null,
              ),
              const SizedBox(height: 16),
              if (widget.zone != null) ...[
                TextFormField(
                  controller: _tagController,
                  decoration: InputDecoration(
                    labelText: l10n.tag,
                  ),
                  readOnly: true,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: l10n.description),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.admins,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              BlocBuilder<UserCubit, UserState>(
                builder: (context, state) {
                  if (state is UserLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is UsersLoaded) {
                    if (state.users.isEmpty) {
                      return Text(
                        "No sub-admins found. Please add users first.",
                        style: TextStyle(color: Colors.grey.shade600),
                      );
                    }
                    return Wrap(
                      spacing: 8,
                      children: state.users.map((user) {
                        final isSelected = _selectedAdminUids.contains(user.uid);
                        return FilterChip(
                          label: Text(user.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedAdminUids.add(user.uid);
                              } else {
                                _selectedAdminUids.remove(user.uid);
                              }
                            });
                          },
                        );
                      }).toList(),
                    );
                  }
                  return const SizedBox();
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveZone,
                  child: Text(l10n.saveZone),
                ),
              ),
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, authState) {
                  final isSuperAdmin = (authState is AuthAuthenticated) &&
                      (authState.profile?.isSuperAdmin ?? false);
                  if (widget.zone != null && isSuperAdmin) {
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
                                    content: Text(l10n.confirmDeleteZone),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: Text(l10n.cancel),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          context.read<ZoneBloc>().add(
                                            DeleteZone(widget.zone!.id),
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
