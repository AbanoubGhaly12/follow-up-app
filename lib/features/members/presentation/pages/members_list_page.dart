import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../bloc/member_bloc.dart';
import '../../../../core/widgets/detail_view_sheet.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../templates/presentation/bloc/template_bloc.dart';
import '../../../templates/presentation/bloc/template_state.dart';
import '../../../templates/data/models/template_model.dart';
import '../../data/models/member_model.dart';

class MembersListPage extends StatefulWidget {
  final String? familyId;

  const MembersListPage({super.key, this.familyId});

  @override
  State<MembersListPage> createState() => _MembersListPageState();
}

class _MembersListPageState extends State<MembersListPage> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<MemberBloc>().add(LoadMembers(familyId: widget.familyId));
  }

  Future<void> _callMember(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showTemplateSheet(BuildContext context, MemberModel member) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return BlocBuilder<TemplateBloc, TemplateState>(
          builder: (context, state) {
            if (state is TemplateLoaded) {
              final templates = state.templates;
              if (templates.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.noTemplatesAvailable,
                    ),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: templates.length,
                itemBuilder: (ctx, index) {
                  final template = templates[index];
                  return ListTile(
                    leading: const Icon(Icons.textsms, color: Colors.blue),
                    title: Text(template.title),
                    subtitle: Text(
                      template.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                  _sendMessage(member, template, 'sms');
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat, color: Colors.green),
                title: const Text('WhatsApp'),
                onTap: () {
                  Navigator.pop(ctx);
                  _sendMessage(member, template, 'whatsapp');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendMessage(
    MemberModel member,
    TemplateModel template,
    String method,
  ) async {
    final message = template.content.replaceAll('{MemberName}', member.name);
    final encoded = Uri.encodeComponent(message);

    Uri? uri;
    if (method == 'sms') {
      uri = Uri.parse('sms:${member.mobileNumber}?body=$encoded');
    } else {
      final phone = member.mobileNumber.replaceAll(RegExp(r'[^0-9]'), '');
      uri = Uri.parse('https://wa.me/$phone?text=$encoded');
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.members)),
      body: BlocBuilder<MemberBloc, MemberState>(
        builder: (context, state) {
          if (state is MemberLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is MemberLoaded) {
            final filteredMembers =
                state.members.where((member) {
                  final query = _searchQuery.toLowerCase();
                  return member.name.toLowerCase().contains(query) ||
                      member.mobileNumber.toLowerCase().contains(query);
                }).toList();

            if (filteredMembers.isEmpty) {
              return Column(
                children: [
                  _buildSearchBar(l10n),
                  Expanded(child: Center(child: Text(l10n.noMembersFound))),
                ],
              );
            }
            return Column(
              children: [
                _buildSearchBar(l10n),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredMembers.length,
                    itemBuilder: (context, index) {
                      final member = filteredMembers[index];
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
                                color: Colors.purple.shade700,
                                width: 6,
                              ),
                            ),
                          ),
                          child: ListTile(
                            title: Text(member.name),
                            subtitle: Text(
                              '${member.role.name} - ${member.mobileNumber}',
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
                                    final df = DateFormat('dd MMM yyyy');
                                    DetailViewSheet.show(
                                      context,
                                      title: member.name,
                                      items: [
                                        DetailItem(l10n.name, member.name),
                                        DetailItem(
                                          l10n.mobileNumber,
                                          member.mobileNumber,
                                        ),
                                        DetailItem(l10n.email, member.email),
                                        DetailItem(
                                          l10n.birthdate(
                                            df.format(member.birthdate),
                                          ),
                                          '',
                                        ),
                                        DetailItem(
                                          l10n.nationalId,
                                          member.nationalId,
                                        ),
                                        DetailItem(
                                          l10n.profession,
                                          member.profession,
                                        ),
                                        DetailItem(
                                          l10n.maritalStatus,
                                          member.maritalStatus.name,
                                        ),
                                        DetailItem(
                                          l10n.familyRole,
                                          member.role.name,
                                        ),
                                        DetailItem(
                                          l10n.educationStage,
                                          member.collegeYear.name,
                                        ),
                                        DetailItem(
                                          l10n.confessionFather,
                                          member.confessionFather,
                                        ),
                                        DetailItem(
                                          l10n.confessionFatherChurch,
                                          member.confessionFatherChurchName,
                                        ),
                                        DetailItem(
                                          l10n.belongToChurch,
                                          member.belongToChurchName,
                                        ),
                                        DetailItem(
                                          l10n.weeklyOffDays,
                                          member.weeklyOffDays.join(', '),
                                        ),
                                      ],
                                    );
                                  },
                                ),
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
                                      () => _showTemplateSheet(context, member),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () {
                                    context.push(
                                      '/families/${member.familyId}/members/edit',
                                      extra: member,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          } else if (state is MemberError) {
            return Center(child: Text(l10n.error(state.message)));
          }
          return Center(child: Text(l10n.initialState));
        },
      ),
      floatingActionButton:
          widget.familyId != null
              ? FloatingActionButton(
                onPressed: () {
                  context.push('/families/${widget.familyId}/members/add');
                },
                child: const Icon(Icons.add),
              )
              : null,
    );
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
