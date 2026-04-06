import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../bloc/street_bloc.dart';
import '../bloc/street_event.dart';
import '../bloc/street_state.dart';
import '../../../../core/widgets/detail_view_sheet.dart';

class StreetsListPage extends StatefulWidget {
  final String? zoneId;

  const StreetsListPage({super.key, this.zoneId});

  @override
  State<StreetsListPage> createState() => _StreetsListPageState();
}

class _StreetsListPageState extends State<StreetsListPage> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<StreetBloc>().add(LoadStreets(zoneId: widget.zoneId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.streets), // We will add to l10n
      ),
      body: BlocBuilder<StreetBloc, StreetState>(
        builder: (context, state) {
          if (state is StreetLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is StreetLoaded) {
            final filteredStreets =
                state.streets.where((street) {
                  return street.name.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  );
                }).toList();

            if (filteredStreets.isEmpty) {
              return Column(
                children: [
                  _buildSearchBar(l10n),
                  Expanded(child: Center(child: Text(l10n.noStreetsFound))),
                ],
              );
            }
            return Column(
              children: [
                _buildSearchBar(l10n),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredStreets.length,
                    itemBuilder: (context, index) {
                      final street = filteredStreets[index];

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
                                color: Colors.orange.shade700,
                                width: 6,
                              ),
                            ),
                          ),
                          child: ListTile(
                            title: Text(street.name),
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
                                      title: street.name,
                                      items: [
                                        DetailItem(l10n.name, street.name),
                                        DetailItem(l10n.zoneId, street.zoneId),
                                      ],
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () {
                                    context.push(
                                      '/zones/${street.zoneId}/streets/edit',
                                      extra: street,
                                    );
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              context.push('/streets/${street.id}');
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          } else if (state is StreetError) {
            return Center(child: Text(l10n.error(state.message)));
          }
          return Container();
        },
      ),
      floatingActionButton:
          widget.zoneId != null
              ? FloatingActionButton(
                child: const Icon(Icons.add),
                onPressed: () {
                  context.push('/zones/${widget.zoneId}/streets/add');
                },
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
