import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../bloc/family_bloc.dart';
import '../../../../core/widgets/detail_view_sheet.dart';
import 'package:intl/intl.dart';

class FamiliesListPage extends StatefulWidget {
  final String? streetId;

  const FamiliesListPage({super.key, this.streetId});

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
      appBar: AppBar(title: Text(l10n.families)),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ListTile(
                                title: Text(
                                  '$headText (${family.landline})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(subtitle),
                                onTap: () {
                                  context.push('/families/${family.id}');
                                },
                              ),
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    TextButton.icon(
                                      onPressed: () {
                                        context.push(
                                          '/families/${family.id}/followups',
                                        );
                                      },
                                      icon: Icon(
                                        Icons.history,
                                        color: Colors.orange.shade800,
                                      ),
                                      label: Text(
                                        l10n.followups,
                                        style: TextStyle(
                                          color: Colors.orange.shade900,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.visibility,
                                        color: Colors.teal,
                                      ),
                                      tooltip: l10n.details,
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
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      tooltip: l10n.edit,
                                      onPressed: () {
                                        context.push(
                                          '/streets/${family.streetId}/families/edit',
                                          extra: family,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
      floatingActionButton:
          widget.streetId != null
              ? FloatingActionButton(
                onPressed: () {
                  context.push('/streets/${widget.streetId}/families/add');
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
