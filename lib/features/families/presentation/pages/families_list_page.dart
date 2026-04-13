import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../bloc/family_bloc.dart';
import '../../../../core/widgets/detail_view_sheet.dart';
import 'package:intl/intl.dart';

class FamiliesListPage extends StatefulWidget {
  final String? streetId;
  final bool isReadOnly;

  const FamiliesListPage({super.key, this.streetId, this.isReadOnly = false});

  @override
  State<FamiliesListPage> createState() => _FamiliesListPageState();
}

class _FamiliesListPageState extends State<FamiliesListPage> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<FamilyBloc>().add(LoadFamilies(streetId: widget.streetId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.families),
        actions: [
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              final isSuperAdmin = (authState is AuthAuthenticated) && (authState.profile?.isSuperAdmin ?? false);
              if (!isSuperAdmin || widget.isReadOnly || widget.streetId == null) return const SizedBox();
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.upload_file),
                    tooltip: 'Import CSV',
                    onPressed: () async {
                      final result = await FilePicker.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['csv'],
                      );
                      if (result != null) {
                        try {
                          String csvString;
                          if (result.files.single.bytes != null) {
                            csvString = utf8.decode(result.files.single.bytes!);
                          } else {
                            final file = File(result.files.single.path!);
                            csvString = await file.readAsString();
                          }
                          final eol = csvString.contains('\r\n') ? '\r\n' : '\n';
                          final fields = CsvToListConverter(eol: eol).convert(csvString);
                          
                          if (fields.length > 1) { // headers + at least 1 row
                            final headers = fields.first.map((e) => e.toString().toLowerCase().trim()).toList();
                            final requiredHeaders = ['family_head'];
                            final hasAll = requiredHeaders.every((h) => headers.contains(h));
                            
                            if (hasAll) {
                              final List<Map<String, dynamic>> csvData = [];
                              for (var i = 1; i < fields.length; i++) {
                                final row = fields[i];
                                Map<String, dynamic> rowData = {};
                                for (String h in headers) {
                                  final index = headers.indexOf(h);
                                  rowData[h] = index < row.length ? row[index] : '';
                                }
                                csvData.add(rowData);
                              }
                              if (context.mounted) {
                                context.read<FamilyBloc>().add(ImportFamiliesCsv(csvData, widget.streetId!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Importing families...'))
                                );
                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Invalid CSV. Missing "family_head" column.'))
                                );
                              }
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error parsing CSV: $e'))
                            );
                          }
                        }
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.cloud_upload),
                    tooltip: 'Upload offline to Cloud',
                    onPressed: () {
                      context.read<FamilyBloc>().add(const SyncOfflineFamilies());
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Syncing offline families...'))
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<FamilyBloc, FamilyState>(
        builder: (context, state) {
          if (state is FamilyLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is FamilyLoaded) {
            final filteredFamilies =
                state.families.where((family) {
                  final query = _searchQuery.toLowerCase();
                  return family.familyHead.toLowerCase().contains(query) ||
                      family.landline.toLowerCase().contains(query);
                }).toList();

            if (filteredFamilies.isEmpty) {
              return Column(
                children: [
                  _buildSearchBar(l10n),
                  Expanded(child: Center(child: Text(l10n.noFamiliesFound))),
                ],
              );
            }
            return Column(
              children: [
                _buildSearchBar(l10n),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredFamilies.length,
                    itemBuilder: (context, index) {
                      final family = filteredFamilies[index];
                      final address = family.addressInfo;
                      final subtitle =
                          '${address.buildingNumber}, ${address.street}';
                      final headText =
                          family.familyHead.isNotEmpty
                              ? family.familyHead
                              : l10n.families;

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
                                color: Colors.green.shade700,
                                width: 6,
                              ),
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              String path = '/families/${family.id}?familyName=${Uri.encodeComponent(family.familyHead)}';
                              if (widget.isReadOnly) {
                                path += '&other=true';
                              }
                              context.push(path);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                headText,
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                            if (family.isFollowedUpThisMonth &&
                                                family.lastFollowupDate !=
                                                    null)
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8.0,
                                                    ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.check_circle,
                                                      color: Colors.green,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      l10n.followedUpOn(
                                                        DateFormat(
                                                          'dd/MM/yyyy',
                                                        ).format(
                                                          family
                                                              .lastFollowupDate!,
                                                        ),
                                                      ),
                                                      style: const TextStyle(
                                                        color: Colors.green,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        family.landline,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      TextButton.icon(
                                        onPressed: () {
                                          String path = '/families/${family.id}/followups?familyName=${Uri.encodeComponent(family.familyHead)}';
                                          if (widget.isReadOnly) {
                                            path += '&other=true';
                                          }
                                          context.push(path);
                                        },
                                        icon: Icon(
                                          Icons.history,
                                          color: Colors.orange.shade800,
                                          size: 20,
                                        ),
                                        label: Text(
                                          l10n.followups,
                                          style: TextStyle(
                                            color: Colors.orange.shade900,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          backgroundColor: Colors.orange
                                              .withAlpha(20),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.visibility_outlined,
                                          color: Colors.teal,
                                        ),
                                        onPressed: () {
                                          final addr = family.addressInfo;
                                          DetailViewSheet.show(
                                            context,
                                            title:
                                                family.familyHead.isNotEmpty
                                                    ? family.familyHead
                                                    : l10n.families,
                                            items: [
                                              DetailItem(
                                                l10n.familyHead,
                                                family.familyHead,
                                              ),
                                              DetailItem(
                                                l10n.tag,
                                                family.tag,
                                              ),
                                              DetailItem(
                                                l10n.mobileNumber,
                                                family.mobileNumber,
                                              ),
                                              DetailItem(
                                                l10n.landline,
                                                family.landline,
                                              ),
                                              DetailItem(
                                                l10n.streetName,
                                                addr.street,
                                              ),
                                              DetailItem(
                                                l10n.buildingNumber,
                                                addr.buildingNumber,
                                              ),
                                              DetailItem(
                                                l10n.floorNumber,
                                                addr.floorNumber,
                                              ),
                                              DetailItem(
                                                l10n.flatNumber,
                                                addr.flatNumber,
                                              ),
                                              DetailItem(
                                                l10n.streetFrom,
                                                addr.streetFrom,
                                              ),
                                              if (family.marriageDate != null)
                                                DetailItem(
                                                  l10n.marriageDate(
                                                    DateFormat(
                                                      'dd MMM yyyy',
                                                    ).format(
                                                      family.marriageDate!,
                                                    ),
                                                  ),
                                                  '',
                                                ),
                                            ],
                                          );
                                        },
                                      ),
                                      BlocBuilder<AuthCubit, AuthState>(
                                        builder: (context, authState) {
                                          final isSuperAdmin = (authState is AuthAuthenticated) && (authState.profile?.isSuperAdmin ?? false);
                                          if (!isSuperAdmin || widget.isReadOnly) return const SizedBox();
                                          return IconButton(
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () {
                                              context.push(
                                                '/streets/${family.streetId}/families/edit',
                                                extra: family,
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          } else if (state is FamilyError) {
            return Center(child: Text(l10n.error(state.message)));
          }
          return Center(child: Text(l10n.initialState));
        },
      ),
      floatingActionButton: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final isSuperAdmin = (authState is AuthAuthenticated) && (authState.profile?.isSuperAdmin ?? false);
          if (!isSuperAdmin || widget.streetId == null || widget.isReadOnly) return const SizedBox();
          return FloatingActionButton(
            onPressed: () {
              context.push('/streets/${widget.streetId}/families/add');
            },
            child: const Icon(Icons.add),
          );
        },
      ),
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
