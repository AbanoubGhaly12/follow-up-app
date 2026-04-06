import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../bloc/followup_bloc.dart';
import '../bloc/followup_event.dart';
import '../bloc/followup_state.dart';
import '../../data/models/followup_model.dart';
import '../../../../core/widgets/detail_view_sheet.dart';

class FollowupsReportPage extends StatefulWidget {
  const FollowupsReportPage({super.key});

  @override
  State<FollowupsReportPage> createState() => _FollowupsReportPageState();
}

class _FollowupsReportPageState extends State<FollowupsReportPage> {
  DateTime? _selectedDate;
  FollowupType? _selectedType;

  @override
  void initState() {
    super.initState();
    _fetchFollowups();
  }

  void _fetchFollowups() {
    context.read<FollowupBloc>().add(
      SearchFollowups(date: _selectedDate, type: _selectedType),
    );
  }

  Color _typeColor(FollowupType type) {
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
            onPressed: _fetchFollowups,
          ),
        ],
      ),
      body: Column(
        children: [
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
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
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
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.allTypes)),
                    ...FollowupType.values.map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(_getTypeLabel(type, l10n)),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedType = val);
                    _fetchFollowups();
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
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          DetailViewSheet.show(
            context,
            title: _getTypeLabel(followup.type, l10n),
            items: [
              DetailItem(l10n.familyName, followup.familyName ?? l10n.unknown),
              DetailItem(l10n.followupType, _getTypeLabel(followup.type, l10n)),
              DetailItem(
                l10n.followupDate,
                dateFormat.format(followup.followupDate),
              ),
              DetailItem(l10n.followupNotes, followup.notes),
              DetailItem(l10n.createdAt, dateFormat.format(followup.createdAt)),
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
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    followup.familyName ?? l10n.unknown,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  dateFormat.format(followup.followupDate),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withAlpha(26), // 0.1 * 255
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getTypeLabel(followup.type, l10n),
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    followup.notes,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade800),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
