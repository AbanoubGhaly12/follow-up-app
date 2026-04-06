import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../templates/data/models/template_model.dart';
import '../../../templates/presentation/bloc/template_bloc.dart';
import '../../../templates/presentation/bloc/template_state.dart';
import '../../data/models/member_model.dart';
import '../bloc/member_bloc.dart';

enum _BirthdayFilter { day, week, month }

class BirthdaysListPage extends StatefulWidget {
  const BirthdaysListPage({super.key});

  @override
  State<BirthdaysListPage> createState() => _BirthdaysListPageState();
}

class _BirthdaysListPageState extends State<BirthdaysListPage> {
  String _searchQuery = '';
  DateTime _selectedDate = DateTime.now();
  _BirthdayFilter _currentFilter =
      _BirthdayFilter.month; // Default to Month as it's most common

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

  void _openTemplateOptions(BuildContext context, MemberModel member) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return BlocBuilder<TemplateBloc, TemplateState>(
          builder: (context, state) {
            if (state is TemplateLoaded) {
              final birthdayTemplates =
                  state.templates
                      .where((t) => t.type == TemplateType.birthday)
                      .toList();

              if (birthdayTemplates.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.noBirthdayTemplates,
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: birthdayTemplates.length,
                itemBuilder: (ctx, index) {
                  final template = birthdayTemplates[index];
                  return ListTile(
                    leading: const Icon(Icons.textsms, color: Colors.blue),
                    title: Text(template.title),
                    subtitle: Text(template.content, maxLines: 1),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showChannelPicker(context, member, template);
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
                  _dispatchMessage(member, template, 'sms');
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat, color: Colors.green),
                title: const Text('WhatsApp'),
                onTap: () {
                  Navigator.pop(ctx);
                  _dispatchMessage(member, template, 'whatsapp');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _callMember(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _dispatchMessage(
    MemberModel member,
    TemplateModel template,
    String method,
  ) async {
    final rawMessage = template.content.replaceAll('{MemberName}', member.name);
    final encodedMessage = Uri.encodeComponent(rawMessage);

    Uri? uri;
    if (method == 'sms') {
      uri = Uri.parse('sms:${member.mobileNumber}?body=$encodedMessage');
    } else if (method == 'whatsapp') {
      final phone = member.mobileNumber.replaceAll(RegExp(r'[^0-9]'), '');
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

  @override
  void initState() {
    super.initState();
    context.read<MemberBloc>().add(const LoadMembers(familyId: null));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentYear = DateTime.now().year;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.birthdays),
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
            child: BlocBuilder<MemberBloc, MemberState>(
              builder: (context, state) {
                if (state is MemberLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is MemberLoaded) {
                  final birthdayMembers =
                      state.members.where((member) {
                        final matchesSearch =
                            member.name.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ||
                            member.mobileNumber.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            );
                        if (!matchesSearch) return false;

                        final bDate = member.birthdate;
                        switch (_currentFilter) {
                          case _BirthdayFilter.day:
                            return bDate.day == _selectedDate.day &&
                                bDate.month == _selectedDate.month;
                          case _BirthdayFilter.week:
                            // Check if birthday falls within 7 days of _selectedDate (ignoring year)
                            final start = DateTime(
                              2000,
                              _selectedDate.month,
                              _selectedDate.day,
                            );
                            final end = start.add(const Duration(days: 7));
                            var bNormalized = DateTime(
                              2000,
                              bDate.month,
                              bDate.day,
                            );

                            // Handle year wrap around (e.g. Dec 30 to Jan 5)
                            if (end.year > start.year) {
                              return (bNormalized.isAfter(start) ||
                                      bNormalized.isAtSameMomentAs(start)) ||
                                  (bNormalized.month == 1 &&
                                      (bNormalized.isBefore(
                                            DateTime(2001, end.month, end.day),
                                          ) ||
                                          bNormalized.isAtSameMomentAs(
                                            DateTime(2001, end.month, end.day),
                                          )));
                            }

                            return (bNormalized.isAfter(start) ||
                                    bNormalized.isAtSameMomentAs(start)) &&
                                (bNormalized.isBefore(end) ||
                                    bNormalized.isAtSameMomentAs(end));
                          case _BirthdayFilter.month:
                            return bDate.month == _selectedDate.month;
                        }
                      }).toList();

                  // Sort by month and day
                  birthdayMembers.sort((a, b) {
                    if (a.birthdate.month != b.birthdate.month) {
                      return a.birthdate.month.compareTo(b.birthdate.month);
                    }
                    return a.birthdate.day.compareTo(b.birthdate.day);
                  });

                  if (birthdayMembers.isEmpty) {
                    return Center(child: Text(l10n.noBirthdaysInPeriod));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    itemCount: birthdayMembers.length,
                    itemBuilder: (context, index) {
                      final member = birthdayMembers[index];
                      final age = currentYear - member.birthdate.year;
                      final dateFormat = DateFormat('MMMM d');

                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border(
                              left: BorderSide(
                                color: Colors.pink.shade300,
                                width: 6,
                              ),
                            ),
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.cake,
                              color: Colors.pink.shade300,
                              size: 30,
                            ),
                            title: Text(
                              member.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              l10n.turnsAgeOn(
                                age.toString(),
                                dateFormat.format(member.birthdate),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.phone,
                                    color: Colors.green,
                                  ),
                                  onPressed:
                                      () => _callMember(member.mobileNumber),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.message,
                                    color: Colors.orange,
                                  ),
                                  onPressed:
                                      () =>
                                          _openTemplateOptions(context, member),
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
          SegmentedButton<_BirthdayFilter>(
            segments: [
              ButtonSegment(
                value: _BirthdayFilter.day,
                label: Text(l10n.day),
                icon: const Icon(Icons.today),
              ),
              ButtonSegment(
                value: _BirthdayFilter.week,
                label: Text(l10n.week),
                icon: const Icon(Icons.view_week),
              ),
              ButtonSegment(
                value: _BirthdayFilter.month,
                label: Text(l10n.month),
                icon: const Icon(Icons.calendar_month),
              ),
            ],
            selected: {_currentFilter},
            onSelectionChanged: (Set<_BirthdayFilter> newSelection) {
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
      case _BirthdayFilter.day:
        return DateFormat('d MMMM').format(_selectedDate);
      case _BirthdayFilter.week:
        final end = _selectedDate.add(const Duration(days: 7));
        return "${DateFormat('d MMM').format(_selectedDate)} - ${DateFormat('d MMM').format(end)}";
      case _BirthdayFilter.month:
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
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 16,
          ),
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
