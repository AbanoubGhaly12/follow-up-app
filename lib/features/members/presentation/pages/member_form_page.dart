import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/models/member_model.dart';
import '../bloc/member_bloc.dart';

class MemberFormPage extends StatefulWidget {
  final String familyId;
  final MemberModel? member;

  const MemberFormPage({super.key, required this.familyId, this.member});

  @override
  State<MemberFormPage> createState() => _MemberFormPageState();
}

class _MemberFormPageState extends State<MemberFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _emailController;
  late TextEditingController _confessiFatherController;
  late TextEditingController _confessiFatherChurchController;
  late TextEditingController _nationalIdController;
  late TextEditingController _belongChurchController;
  late TextEditingController _professionController;
  late TextEditingController _tagController;

  DateTime? _birthdate;
  bool _isFamilyHead = false;
  bool _isDead = false;
  DateTime? _deathDate;
  MaritalStatus _maritalStatus = MaritalStatus.single;
  CollegeYear _collegeYear = CollegeYear.UNIV; // Default
  MemberRole _role = MemberRole.member;
  final List<String> _weeklyOffDays = [];

  final List<String> _allDays = [
    'SAT',
    'SUN',
    'MON',
    'TUES',
    'WED',
    'THU',
    'FRI',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member?.name ?? '');
    _mobileController = TextEditingController(
      text: widget.member?.mobileNumber ?? '',
    );
    _emailController = TextEditingController(text: widget.member?.email ?? '');
    _confessiFatherController = TextEditingController(
      text: widget.member?.confessionFather ?? '',
    );
    _confessiFatherChurchController = TextEditingController(
      text: widget.member?.confessionFatherChurchName ?? '',
    );
    _nationalIdController = TextEditingController(
      text: widget.member?.nationalId ?? '',
    );
    _belongChurchController = TextEditingController(
      text: widget.member?.belongToChurchName ?? '',
    );
    _professionController = TextEditingController(
      text: widget.member?.profession ?? '',
    );
    _tagController = TextEditingController(
      text: widget.member?.tag ?? '',
    );

    _birthdate = widget.member?.birthdate;
    _isFamilyHead = widget.member?.isFamilyHead ?? false;
    _isDead = widget.member?.isDead ?? false;
    _deathDate = widget.member?.deathDate;
    _maritalStatus = widget.member?.maritalStatus ?? MaritalStatus.single;
    _collegeYear = widget.member?.collegeYear ?? CollegeYear.UNIV;
    _role = widget.member?.role ?? MemberRole.member;
    if (widget.member?.weeklyOffDays != null) {
      _weeklyOffDays.addAll(widget.member!.weeklyOffDays);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _confessiFatherController.dispose();
    _confessiFatherChurchController.dispose();
    _nationalIdController.dispose();
    _belongChurchController.dispose();
    _professionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isBirthdate) async {
    final initial = isBirthdate ? _birthdate : _deathDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isBirthdate) {
          _birthdate = picked;
        } else {
          _deathDate = picked;
        }
      });
    }
  }

  String _localizeMaritalStatus(MaritalStatus status, AppLocalizations l10n) {
    switch (status) {
      case MaritalStatus.single: return l10n.single;
      case MaritalStatus.married: return l10n.married;
      case MaritalStatus.divorced: return l10n.divorced;
      case MaritalStatus.widowed: return l10n.widow;
    }
  }

  String _localizeCollegeYear(CollegeYear year, AppLocalizations l10n) {
    switch (year) {
      case CollegeYear.PRESCHOOL: return l10n.preschool;
      case CollegeYear.KG: return l10n.kg;
      case CollegeYear.PRIM: return l10n.primary;
      case CollegeYear.PREP: return l10n.preparatory;
      case CollegeYear.SEC: return l10n.secondary;
      case CollegeYear.UNIV: return l10n.university;
    }
  }

  String _localizeRole(MemberRole role, AppLocalizations l10n) {
    switch (role) {
      case MemberRole.father: return l10n.husband;
      case MemberRole.mother: return l10n.wife;
      case MemberRole.child: return l10n.son;
      case MemberRole.member: return l10n.member;
    }
  }

  void _saveMember() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();

      final memberData = MemberModel(
        id: widget.member?.id ?? const Uuid().v4(),
        familyId: widget.familyId,
        name: _nameController.text,
        tag: widget.member?.tag ?? 'MEMBER-${const Uuid().v4()}',
        isFamilyHead: _isFamilyHead,
        birthdate: _birthdate,
        mobileNumber: _mobileController.text.startsWith('+20')
            ? _mobileController.text 
            : '+20${_mobileController.text}',
        email: _emailController.text,
        confessionFather: _confessiFatherController.text,
        confessionFatherChurchName: _confessiFatherChurchController.text,
        nationalId: _nationalIdController.text,
        belongToChurchName: _belongChurchController.text,
        isDead: _isDead,
        deathDate: _deathDate,
        maritalStatus: _maritalStatus,
        collegeYear: _collegeYear,
        profession: _professionController.text,
        weeklyOffDays: _weeklyOffDays,
        role: _role,
        createdAt: widget.member?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.member == null) {
        context.read<MemberBloc>().add(AddMember(memberData));
      } else {
        context.read<MemberBloc>().add(UpdateMember(memberData));
      }
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.member == null ? l10n.addMember : l10n.editMember),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.member != null) ...[
                TextFormField(
                  controller: _tagController,
                  decoration: InputDecoration(labelText: l10n.tag),
                  readOnly: true,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.name),
                validator: (v) => v!.isEmpty ? l10n.requiredField : null,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(l10n.isFamilyHead),
                value: _isFamilyHead,
                onChanged: (v) => setState(() => _isFamilyHead = v),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  _birthdate == null
                      ? l10n.selectBirthdate
                      : l10n.birthdate(
                        DateFormat('yyyy-MM-dd').format(_birthdate!),
                      ),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(true),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mobileController,
                decoration: InputDecoration(
                  labelText: l10n.mobileNumber,
                  suffixText: '+2',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: l10n.email),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nationalIdController,
                decoration: InputDecoration(labelText: l10n.nationalId),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _professionController,
                decoration: InputDecoration(labelText: l10n.profession),
              ),
              const Divider(),
              Text(
                l10n.churchInfo,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _belongChurchController,
                decoration: InputDecoration(labelText: l10n.belongToChurch),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confessiFatherController,
                decoration: InputDecoration(labelText: l10n.confessionFather),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confessiFatherChurchController,
                decoration: InputDecoration(
                  labelText: l10n.confessionFatherChurch,
                ),
              ),
              const Divider(),
              const SizedBox(height: 16),
              DropdownButtonFormField<MaritalStatus>(
                value: _maritalStatus,
                decoration: InputDecoration(labelText: l10n.maritalStatus),
                items: MaritalStatus.values.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(_localizeMaritalStatus(s, l10n)),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _maritalStatus = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<CollegeYear>(
                value: _collegeYear,
                decoration: InputDecoration(labelText: l10n.educationStage),
                items: CollegeYear.values.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(_localizeCollegeYear(s, l10n)),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _collegeYear = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MemberRole>(
                value: _role,
                decoration: InputDecoration(labelText: l10n.familyRole),
                items: MemberRole.values.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(_localizeRole(s, l10n)),
                  );
                    }).toList(),
                onChanged: (v) => setState(() => _role = v!),
              ),
              const SizedBox(height: 16),
              const Divider(),
              Text(l10n.weeklyOffDays),
              Wrap(
                spacing: 8.0,
                children:
                    _allDays.map((day) {
                      return FilterChip(
                        label: Text(day),
                        selected: _weeklyOffDays.contains(day),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _weeklyOffDays.add(day);
                            } else {
                              _weeklyOffDays.remove(day);
                            }
                          });
                        },
                      );
                    }).toList(),
              ),
              const Divider(),
              SwitchListTile(
                title: Text(l10n.isDead),
                value: _isDead,
                onChanged: (v) => setState(() => _isDead = v),
              ),
              if (_isDead)
                ListTile(
                  title: Text(
                    _deathDate == null
                        ? l10n.selectDeathDate
                        : l10n.deathDate(
                          DateFormat('yyyy-MM-dd').format(_deathDate!),
                        ),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _pickDate(false),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveMember,
                  child: Text(l10n.saveMember),
                ),
              ),
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, authState) {
                  final isSuperAdmin = (authState is AuthAuthenticated) && (authState.profile?.isSuperAdmin ?? false);
                  if (widget.member != null && isSuperAdmin) {
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
                                content: Text(l10n.confirmDeleteMember),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text(l10n.cancel),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      context.read<MemberBloc>().add(
                                        DeleteMember(
                                          widget.member!.id,
                                          widget.familyId,
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
