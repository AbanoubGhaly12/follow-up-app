import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/detail_view_sheet.dart';
import '../bloc/followup_bloc.dart';
import '../bloc/followup_event.dart';
import '../bloc/followup_state.dart';
import '../../data/models/followup_model.dart';

class FollowupHistoryPage extends StatefulWidget {
  final String familyId;
  final String? familyName;

  const FollowupHistoryPage({
    super.key,
    required this.familyId,
    this.familyName,
  });

  @override
  State<FollowupHistoryPage> createState() => _FollowupHistoryPageState();
}

class _FollowupHistoryPageState extends State<FollowupHistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<FollowupBloc>().add(LoadFollowups(widget.familyId));
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
      appBar: AppBar(
        title: Text(
          widget.familyName != null
              ? "${l10n.followups} - ${widget.familyName}"
              : l10n.followups,
        ),
      ),
      body: BlocBuilder<FollowupBloc, FollowupState>(
        builder: (context, state) {
          if (state is FollowupLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is FollowupLoaded) {
            if (state.followups.isEmpty) {
              return Center(child: Text(l10n.noFollowupsFound));
            }
            return ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: state.followups.length,
              itemBuilder: (context, index) {
                final followup = state.followups[index];
                final typeColor = _typeColor(followup.type);
                final typeIcon = _typeIcon(followup.type);
                final typeLabel = _getTypeLabel(followup.type, l10n);

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
                        left: BorderSide(color: typeColor, width: 6),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: typeColor.withAlpha(38), // ~0.15 * 255
                        child: Icon(typeIcon, color: typeColor),
                      ),
                      title: Text(
                        typeLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (followup.memberName != null) ...[
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    size: 14,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    followup.memberName!,
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              dateFormat.format(followup.followupDate),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              followup.notes,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.visibility,
                              color: Colors.teal,
                            ),
                            onPressed: () {
                              DetailViewSheet.show(
                                context,
                                title: typeLabel,
                                items: [
                                  DetailItem(l10n.followupType, typeLabel),
                                  if (followup.memberName != null)
                                    DetailItem(
                                      l10n.members,
                                      followup.memberName!,
                                    ),
                                  DetailItem(
                                    l10n.followupDate,
                                    dateFormat.format(followup.followupDate),
                                  ),
                                  DetailItem(
                                    l10n.followupNotes,
                                    followup.notes,
                                  ),
                                ],
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder:
                                    (ctx) => AlertDialog(
                                      title: Text(l10n.delete),
                                      content: Text(l10n.confirmDeleteFollowup),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: Text(l10n.cancel),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            context.read<FollowupBloc>().add(
                                              DeleteFollowup(
                                                followup.id,
                                                widget.familyId,
                                              ),
                                            );
                                          },
                                          child: Text(
                                            l10n.delete,
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          } else if (state is FollowupError) {
            return Center(child: Text(l10n.error(state.message)));
          }
          return Center(child: Text(l10n.initialState));
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final followupBloc = context.read<FollowupBloc>();
          await context.push(
            '/families/${widget.familyId}/followups/add?familyName=${Uri.encodeComponent(widget.familyName ?? '')}',
          );
          if (mounted) {
            followupBloc.add(LoadFollowups(widget.familyId));
          }
        },
      ),
    );
  }
}
