import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../bloc/followup_bloc.dart';
import '../bloc/followup_event.dart';
import '../bloc/followup_state.dart';
import '../../data/models/followup_model.dart';
import '../../../../core/widgets/detail_view_sheet.dart';
import '../../../zones/presentation/bloc/zone_bloc.dart';
import '../../../streets/presentation/bloc/street_bloc.dart';
import '../../../streets/presentation/bloc/street_event.dart';
import '../../../streets/presentation/bloc/street_state.dart';

class FollowupsReportPage extends StatefulWidget {
  const FollowupsReportPage({super.key});

  @override
  State<FollowupsReportPage> createState() => _FollowupsReportPageState();
}

class _FollowupsReportPageState extends State<FollowupsReportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _selectedDate;
  FollowupType? _selectedType;
  String? _selectedZoneId;
  String? _selectedStreetId;
  int? _selectedInactivityMonths;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _fetchFollowups();
      }
    });
    context.read<ZoneBloc>().add(LoadZones());
    _fetchFollowups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _fetchFollowups({bool forceSync = false}) {
    context.read<FollowupBloc>().add(
      SearchFollowups(
        date: _selectedDate,
        type: _selectedType,
        zoneId: _selectedZoneId,
        streetId: _selectedStreetId,
        inactivityMonths: _selectedInactivityMonths,
        isFamilyReport: _tabController.index == 0,
        forceSync: forceSync,
      ),
    );
  }

  Color _typeColor(FollowupType type) {
    if (_selectedInactivityMonths != null) return Colors.red.shade700;
    switch (type) {
      case FollowupType.phone:
        return Colors.blue.shade600;
      case FollowupType.visit:
        return Colors.green.shade600;
      case FollowupType.churchMeeting:
        return Colors.purple.shade600;
      case FollowupType.onlineCall:
        return Colors.teal.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _getTypeLabel(FollowupType type, AppLocalizations l10n) {
    if (_selectedInactivityMonths != null) return l10n.inactivityPeriod;
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

  IconData _typeIcon(FollowupType type) {
    if (_selectedInactivityMonths != null) return Icons.warning_amber_rounded;
    switch (type) {
      case FollowupType.phone:
        return Icons.phone;
      case FollowupType.visit:
        return Icons.home;
      case FollowupType.churchMeeting:
        return Icons.church;
      case FollowupType.onlineCall:
        return Icons.video_call;
      default:
        return Icons.note;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.followupReport),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchFollowups(forceSync: true),
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            color: theme.primaryColor,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(text: l10n.familyFollowups),
                Tab(text: l10n.memberFollowups),
              ],
            ),
          ),
          _buildFilters(l10n, theme),
          Expanded(
            child: BlocBuilder<FollowupBloc, FollowupState>(
              builder: (context, state) {
                if (state is FollowupLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is FollowupLoaded) {
                  if (state.followups.isEmpty) {
                    return Center(child: Text(l10n.noFollowupsFound));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    itemCount: state.followups.length,
                    itemBuilder: (context, index) {
                      final followup = state.followups[index];
                      return _buildFollowupCard(followup, l10n, dateFormat);
                    },
                  );
                } else if (state is FollowupError) {
                  return Center(child: Text(l10n.error(state.message)));
                }
                return Container();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(AppLocalizations l10n, ThemeData theme) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.primaryColor.withAlpha(13), // 0.05 * 255 = ~13
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _selectedInactivityMonths,
                  decoration: InputDecoration(
                    labelText: l10n.inactivityPeriod,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: const OutlineInputBorder(),
                  ),
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 14,
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.allTime)),
                    DropdownMenuItem(
                      value: -1,
                      child: Text(l10n.neverFollowedUpFilter),
                    ),
                    DropdownMenuItem(
                      value: 3,
                      child: Text(l10n.moreThan3Months),
                    ),
                    DropdownMenuItem(
                      value: 6,
                      child: Text(l10n.moreThan6Months),
                    ),
                    DropdownMenuItem(
                      value: 9,
                      child: Text(l10n.moreThan9Months),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedInactivityMonths = val;
                      if (val != null) {
                        _selectedDate = null;
                        _selectedType = null;
                      }
                    });
                    _fetchFollowups();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _selectedInactivityMonths != null
                          ? null
                          : () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                              _fetchFollowups();
                            }
                          },
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    _selectedDate == null
                        ? l10n.allTime
                        : dateFormat.format(_selectedDate!),
                  ),
                ),
              ),
              if (_selectedDate != null)
                IconButton(
                  onPressed: () {
                    setState(() => _selectedDate = null);
                    _fetchFollowups();
                  },
                  icon: const Icon(Icons.clear, size: 18),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<FollowupType?>(
                  value: _selectedType,
                  disabledHint: Text(l10n.allTypes),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(),
                  ),
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 14,
                    overflow: TextOverflow.ellipsis,
                  ),
                  items:
                      _selectedInactivityMonths != null
                          ? null
                          : [
                            DropdownMenuItem(
                              value: null,
                              child: Text(l10n.allTypes),
                            ),
                            ...FollowupType.values.map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(_getTypeLabel(type, l10n)),
                              ),
                            ),
                          ],
                  onChanged:
                      _selectedInactivityMonths != null
                          ? null
                          : (val) {
                            setState(() => _selectedType = val);
                            _fetchFollowups();
                          },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: BlocBuilder<ZoneBloc, ZoneState>(
                  builder: (context, state) {
                    List<DropdownMenuItem<String?>> items = [
                      DropdownMenuItem(value: null, child: Text(l10n.allZones)),
                    ];
                    if (state is ZoneLoaded) {
                      items.addAll(
                        state.zones.map(
                          (z) => DropdownMenuItem(
                            value: z.id,
                            child: Text(z.name),
                          ),
                        ),
                      );
                    }
                    return DropdownButtonFormField<String?>(
                      value: _selectedZoneId,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 14,
                        overflow: TextOverflow.ellipsis,
                      ),
                      items: items,
                      onChanged: (val) {
                        setState(() {
                          _selectedZoneId = val;
                          _selectedStreetId = null;
                        });
                        if (val != null) {
                          context.read<StreetBloc>().add(
                            LoadStreets(zoneId: val),
                          );
                        }
                        _fetchFollowups();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BlocBuilder<StreetBloc, StreetState>(
                  builder: (context, state) {
                    List<DropdownMenuItem<String?>> items = [
                      DropdownMenuItem(
                        value: null,
                        child: Text(l10n.allStreets),
                      ),
                    ];
                    if (state is StreetLoaded && _selectedZoneId != null) {
                      items.addAll(
                        state.streets.map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name),
                          ),
                        ),
                      );
                    }
                    return DropdownButtonFormField<String?>(
                      value: _selectedStreetId,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 14,
                        overflow: TextOverflow.ellipsis,
                      ),
                      items: items,
                      onChanged: (val) {
                        setState(() => _selectedStreetId = val);
                        _fetchFollowups();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFollowupCard(
    FollowupModel followup,
    AppLocalizations l10n,
    DateFormat dateFormat,
  ) {
    final typeColor = _typeColor(followup.type);
    final typeLabel = _getTypeLabel(followup.type, l10n);

    // Neglect-specific subtitle and notes
    String subtitleText;
    String notesText;

    if (_selectedInactivityMonths != null) {
      if (followup.notes == 'NEVER') {
        subtitleText = l10n.neverFollowedUp;
        notesText = '';
      } else {
        subtitleText = l10n.lastFollowedUpOn(
          dateFormat.format(followup.followupDate),
        );
        notesText = '';
      }
    } else {
      subtitleText =
          "${_getTypeLabel(followup.type, l10n)} | ${dateFormat.format(followup.followupDate)}";
      notesText = followup.notes;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          DetailViewSheet.show(
            context,
            title: typeLabel,
            items: [
              DetailItem(l10n.familyName, followup.familyName ?? l10n.unknown),
              if (followup.memberName != null)
                DetailItem(l10n.members, followup.memberName!),
              DetailItem(
                _selectedInactivityMonths != null
                    ? l10n.inactivityPeriod
                    : l10n.followupType,
                typeLabel,
              ),
              if (_selectedInactivityMonths == null)
                DetailItem(
                  l10n.followupDate,
                  dateFormat.format(followup.followupDate),
                ),
              if (_selectedInactivityMonths == null)
                DetailItem(l10n.followupNotes, followup.notes),
              if (_selectedInactivityMonths != null &&
                  followup.notes != 'NEVER')
                DetailItem(
                  l10n.lastFollowedUpOn(''),
                  dateFormat.format(followup.followupDate),
                ),
              if (_selectedInactivityMonths == null)
                DetailItem(
                  l10n.createdAt,
                  dateFormat.format(followup.createdAt),
                ),
            ],
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: typeColor, width: 6)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: typeColor.withAlpha(26), // 0.1 * 255 = ~26
              child: Icon(_typeIcon(followup.type), color: typeColor),
            ),
            title: Text(
              "${followup.familyName ?? l10n.unknown}${followup.memberName != null ? ' - ${followup.memberName}' : ''}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  subtitleText,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                if (notesText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    notesText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
