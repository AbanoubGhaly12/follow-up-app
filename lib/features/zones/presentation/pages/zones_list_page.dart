import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../../../../core/settings/settings_cubit.dart';
import '../../../../core/widgets/detail_view_sheet.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../bloc/zone_bloc.dart';

class ZonesListPage extends StatefulWidget {
  final bool showOnlyOtherZones;
  const ZonesListPage({super.key, this.showOnlyOtherZones = false});

  @override
  State<ZonesListPage> createState() => _ZonesListPageState();
}

class _ZonesListPageState extends State<ZonesListPage> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    final isSuperAdmin = (authState is AuthAuthenticated) && (authState.profile?.isSuperAdmin ?? false);
    context.read<ZoneBloc>().add(LoadZones(
      isSuperAdmin: isSuperAdmin,
      otherZonesOnly: widget.showOnlyOtherZones,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.showOnlyOtherZones ? (l10n.otherZones ?? 'Other Zones') : l10n.zones),
        actions: [
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              final isSuperAdmin = (authState is AuthAuthenticated) && (authState.profile?.isSuperAdmin ?? false);
              if (!isSuperAdmin || widget.showOnlyOtherZones) return const SizedBox();
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
                          if (fields[0].length > 1) { // headers + at least 1 row

                            // 1. Convert CSV to List of Lists
                            // 2. Extract the header row (the first row)
                            List<String> headers = fields[0].map((e) => e.toString()).toList();

                            // 3. Map the remaining rows to Maps
                            List<Map<String, dynamic>> mappedData = fields.skip(1).map((row) {
                              Map<String, dynamic> map = {};
                              for (int i = 0; i < headers.length; i++) {
                                map[headers[i]] = row[i];
                              }
                              return map;
                            }).toList();
                              if (context.mounted) {
                                context.read<ZoneBloc>().add(ImportZonesCsv(mappedData));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Importing zones...'))
                                );
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Invalid CSV. Missing "name" or "tag" column.'))
                                );
                              }
                            }
                          }
                        }
                         catch (e) {
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
                      context.read<ZoneBloc>().add(SyncOfflineZones());
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Syncing offline zones...'))
                      );
                    },
                  ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              context.read<SettingsCubit>().toggleLocale();
            },
          ),
        ],
      ),
      body: BlocConsumer<ZoneBloc, ZoneState>(
        listener: (context, state) {
          if (state is ZoneError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is ZoneLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ZoneLoaded) {
            final filteredZones =
                state.zones.where((zone) {
                  return zone.name.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  );
                }).toList();

            if (filteredZones.isEmpty) {
              return Column(
                children: [
                  _buildSearchBar(l10n),
                  Expanded(child: Center(child: Text(l10n.noZonesFound))),
                ],
              );
            }
            return Column(
              children: [
                _buildSearchBar(l10n),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredZones.length,
                    itemBuilder: (context, index) {
                      final zone = filteredZones[index];
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
                                color: Colors.blue.shade700,
                                width: 6,
                              ),
                            ),
                          ),
                          child: ListTile(
                            title: Text(zone.name),
                            subtitle: Text(zone.tag),
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
                                      title: zone.name,
                                      items: [
                                        DetailItem(l10n.name, zone.name),
                                        DetailItem(l10n.tag, zone.tag),
                                        DetailItem(
                                          l10n.description,
                                          zone.description ?? '',
                                        ),
                                        DetailItem(
                                          l10n.admins,
                                          zone.zoneAdmins.join(', '),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                BlocBuilder<AuthCubit, AuthState>(
                                  builder: (context, authState) {
                                    final isSuperAdmin = (authState is AuthAuthenticated) && (authState.profile?.isSuperAdmin ?? false);
                                    if (!isSuperAdmin || widget.showOnlyOtherZones) return const SizedBox();
                                    return IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () {
                                        context.push('/zones/edit', extra: zone);
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              context.push('/zones/${zone.id}?other=${widget.showOnlyOtherZones}');
                            },
                            onLongPress: () {
                              if (widget.showOnlyOtherZones) return;
                              final authState = context.read<AuthCubit>().state;
                              final isSuperAdmin = (authState is AuthAuthenticated) && (authState.profile?.isSuperAdmin ?? false);
                              if (isSuperAdmin) {
                                context.push('/zones/edit', extra: zone);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          } else if (state is ZoneError) {
            return Center(child: Text(l10n.error(state.message)));
          }
          // Default when not loading/loaded (e.g., initial or error but we already show snackbar)
          if (state is ZoneInitial) {
            return Center(child: Text(l10n.initialState));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final isSuperAdmin = (authState is AuthAuthenticated) && (authState.profile?.isSuperAdmin ?? false);
          if (!isSuperAdmin || widget.showOnlyOtherZones) return const SizedBox();
          return FloatingActionButton(
            onPressed: () {
              context.push('/zones/add');
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
