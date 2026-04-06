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
                          child: InkWell(
                            onTap: () {
                              context.push(
                                '/families/${family.id}?familyName=${Uri.encodeComponent(family.familyHead)}',
                              );
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
                                          context.push(
                                            '/families/${family.id}/followups?familyName=${Uri.encodeComponent(family.familyHead)}',
                                          );
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
                                          Icons.edit_outlined,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () {
                                          context.push(
                                            '/streets/${family.streetId}/families/edit',
                                            extra: family,
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
