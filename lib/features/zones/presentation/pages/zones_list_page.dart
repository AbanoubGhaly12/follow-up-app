import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              context.read<SettingsCubit>().toggleLocale();
            },
          ),
        ],
      ),
      body: BlocBuilder<ZoneBloc, ZoneState>(
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
          return Center(child: Text(l10n.initialState));
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
