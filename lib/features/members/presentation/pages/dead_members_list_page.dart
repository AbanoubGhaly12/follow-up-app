import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../../families/data/models/family_model.dart';
import '../../../families/presentation/bloc/family_bloc.dart';
import '../../../followups/data/models/followup_model.dart';
import '../../../followups/presentation/bloc/followup_bloc.dart';
import '../../../followups/presentation/bloc/followup_event.dart';
import '../../../templates/data/models/template_model.dart';
import '../../../templates/presentation/bloc/template_bloc.dart';
import '../../../templates/presentation/bloc/template_state.dart';
import '../../data/models/member_model.dart';
import '../bloc/member_bloc.dart';
enum _DeadFilter { day, week, month }

class DeadMembersListPage extends StatefulWidget {
  const DeadMembersListPage({super.key});

  @override
  State<DeadMembersListPage> createState() => _DeadMembersListPageState();
}

class _DeadMembersListPageState extends State<DeadMembersListPage> {
  String _searchQuery = '';
  DateTime _selectedDate = DateTime.now();
  _DeadFilter _currentFilter = _DeadFilter.month;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _openTemplateOptions(BuildContext context, MemberModel member, String familyPhone) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return BlocBuilder<TemplateBloc, TemplateState>(
          builder: (context, state) {
            if (state is TemplateLoaded) {
              final condolenceTemplates = state.templates
                  .where((t) => t.type == TemplateType.condolences)
                  .toList();

              if (condolenceTemplates.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.noCondolenceTemplates,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: condolenceTemplates.length,
                itemBuilder: (ctx, index) {
                  final template = condolenceTemplates[index];
                  return ListTile(
                    leading: const Icon(Icons.textsms, color: Colors.blue),
                    title: Text(template.title),
                    subtitle: Text(template.content, maxLines: 1),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showChannelPicker(context, member, familyPhone, template);
                    },
                  );
                },
              );
            }
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          },
        );
      },
    );
  }

  void _showChannelPicker(
    BuildContext context,
    MemberModel member,
    String familyPhone,
    TemplateModel template,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.sms, color: Colors.blue),
                title: const Text('SMS'),
                onTap: () {
                  Navigator.pop(ctx);
                  _dispatchMessage(member, familyPhone, template, 'sms');
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat, color: Colors.green),
                title: const Text('WhatsApp'),
                onTap: () {
                  Navigator.pop(ctx);
                  _dispatchMessage(member, familyPhone, template, 'whatsapp');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _dispatchMessage(
    MemberModel member,
    String familyPhone,
    TemplateModel template,
    String method,
  ) async {
    final rawMessage = template.content.replaceAll('{MemberName}', member.name);
    final encodedMessage = Uri.encodeComponent(rawMessage);

    Uri? uri;
    if (method == 'sms') {
      uri = Uri.parse('sms:$familyPhone?body=$encodedMessage');
    } else if (method == 'whatsapp') {
      final phone = familyPhone.replaceAll(RegExp(r'[^0-9]'), '');
      uri = Uri.parse('https://wa.me/$phone?text=$encodedMessage');
    }

    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.couldNotLaunchApp),
          ),
        );
      }
    }
  }

  void _markFollowupDone(MemberModel member) {
    final followup = FollowupModel(
      id: const Uuid().v4(),
      familyId: member.familyId,
      memberId: member.id,
      memberName: member.name,
      followupDate: DateTime.now(),
      notes: 'Yearly Condolence Follow-up',
      type: FollowupType.condolence,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    context.read<FollowupBloc>().add(AddFollowup(followup, member.familyId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.condolenceFollowupDone)),
    );
    // Reload members to reflect changes
    context.read<MemberBloc>().add(const LoadMembers(familyId: null));
  }

  @override
  void initState() {
    super.initState();
    context.read<MemberBloc>().add(const LoadMembers(familyId: null));
    context.read<FamilyBloc>().add(const LoadFamilies());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.deadMembers),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(l10n),
          _buildFilterToggle(l10n),
          Expanded(
            child: BlocBuilder<FamilyBloc, FamilyState>(
              builder: (context, familyState) {
                Map<String, FamilyModel> familyMap = {};
                if (familyState is FamilyLoaded) {
                  familyMap = {for (var f in familyState.families) f.id: f};
                }

                return BlocBuilder<MemberBloc, MemberState>(
                  builder: (context, state) {
                    if (state is MemberLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is MemberLoaded) {
                      final deadMembers = state.members.where((member) {
                        if (!member.isDead || member.deathDate == null) return false;

                        final matchesSearch = member.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            member.mobileNumber.toLowerCase().contains(_searchQuery.toLowerCase());
                        if (!matchesSearch) return false;

                        final dDate = member.deathDate!;
                        switch (_currentFilter) {
                          case _DeadFilter.day:
                            return dDate.day == _selectedDate.day && dDate.month == _selectedDate.month;
                          case _DeadFilter.week:
                            final start = DateTime(2000, _selectedDate.month, _selectedDate.day);
                            final end = start.add(const Duration(days: 7));
                            var dNormalized = DateTime(2000, dDate.month, dDate.day);

                            if (end.year > start.year) {
                              return (dNormalized.isAfter(start) || dNormalized.isAtSameMomentAs(start)) ||
                                  (dNormalized.month == 1 &&
                                      (dNormalized.isBefore(DateTime(2001, end.month, end.day)) ||
                                          dNormalized.isAtSameMomentAs(DateTime(2001, end.month, end.day))));
                            }
                            return (dNormalized.isAfter(start) || dNormalized.isAtSameMomentAs(start)) &&
                                (dNormalized.isBefore(end) || dNormalized.isAtSameMomentAs(end));
                          case _DeadFilter.month:
                            return dDate.month == _selectedDate.month;
                        }
                      }).toList();

                      deadMembers.sort((a, b) {
                        if (a.deathDate!.month != b.deathDate!.month) {
                          return a.deathDate!.month.compareTo(b.deathDate!.month);
                        }
                        return a.deathDate!.day.compareTo(b.deathDate!.day);
                      });

                      if (deadMembers.isEmpty) {
                        return Center(child: Text(l10n.noDeadMembersInPeriod));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: deadMembers.length,
                        itemBuilder: (context, index) {
                          final member = deadMembers[index];
                          final dateFormat = DateFormat('MMMM d');
                          final family = familyMap[member.familyId];
                          final isDone = member.isCondolenceFollowedUpThisYear;

                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: isDone ? Colors.green.shade50 : null,
                                border: Border(
                                  left: BorderSide(
                                    color: isDone ? Colors.green : Colors.grey,
                                    width: 6,
                                  ),
                                ),
                              ),
                              child: ListTile(
                                leading: Icon(
                                  isDone ? Icons.check_circle : Icons.person_off,
                                  color: isDone ? Colors.green : Colors.blueGrey,
                                  size: 30,
                                ),
                                title: Text(
                                  member.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  l10n.diedOn(dateFormat.format(member.deathDate!)),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!isDone)
                                      IconButton(
                                        icon: const Icon(Icons.done_all, color: Colors.blue),
                                        tooltip: l10n.markAsFollowedUp,
                                        onPressed: () => _markFollowupDone(member),
                                      ),
                                    if (family != null && family.mobileNumber.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.message, color: Colors.orange),
                                        onPressed: () => _openTemplateOptions(context, member, family.mobileNumber),
                                      ),
                                     IconButton(
                                      icon: const Icon(Icons.family_restroom, color: Colors.blue),
                                      tooltip: 'View Family',
                                      onPressed: () {
                                        context.push('/families/${member.familyId}');
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    } else if (state is MemberError) {
                      return Center(child: Text(l10n.error(state.message)));
                    }
                    return Center(child: Text(l10n.initialState));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterToggle(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          SegmentedButton<_DeadFilter>(
            segments: [
              ButtonSegment(
                value: _DeadFilter.day,
                label: Text(l10n.day),
                icon: const Icon(Icons.today),
              ),
              ButtonSegment(
                value: _DeadFilter.week,
                label: Text(l10n.week),
                icon: const Icon(Icons.view_week),
              ),
              ButtonSegment(
                value: _DeadFilter.month,
                label: Text(l10n.month),
                icon: const Icon(Icons.calendar_month),
              ),
            ],
            selected: {_currentFilter},
            onSelectionChanged: (Set<_DeadFilter> newSelection) {
              setState(() {
                _currentFilter = newSelection.first;
              });
            },
          ),
          const SizedBox(height: 8),
          Text(
            _getFilterDescription(l10n),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterDescription(AppLocalizations l10n) {
    switch (_currentFilter) {
      case _DeadFilter.day:
        return DateFormat('d MMMM').format(_selectedDate);
      case _DeadFilter.week:
        final end = _selectedDate.add(const Duration(days: 7));
        return "${DateFormat('d MMM').format(_selectedDate)} - ${DateFormat('d MMM').format(end)}";
      case _DeadFilter.month:
        return DateFormat('MMMM yyyy').format(_selectedDate);
    }
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: l10n.search,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }
}
