import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import '../../../../core/settings/settings_cubit.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboard),
        actions: [
          BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              final isArabic = state.locale.languageCode == 'ar';
              return IconButton(
                icon: const Icon(Icons.language),
                tooltip: l10n.changeLanguage,
                onPressed: () {
                  context.read<SettingsCubit>().toggleLocale();
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DashboardCubit>().loadStats();
            },
          ),
        ],
      ),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is DashboardLoaded) {
            final stats = state.stats;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.stats,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard(
                        context,
                        title: l10n.totalZones,
                        count: stats.totalZones,
                        icon: Icons.map,
                        color: Colors.blue.shade700,
                      ),
                      _buildStatCard(
                        context,
                        title: l10n.totalStreets,
                        count: stats.totalStreets,
                        icon: Icons.add_road,
                        color: Colors.orange.shade700,
                      ),
                      _buildStatCard(
                        context,
                        title: l10n.totalFamilies,
                        count: stats.totalFamilies,
                        icon: Icons.family_restroom,
                        color: Colors.green.shade700,
                      ),
                      _buildStatCard(
                        context,
                        title: l10n.totalMembers,
                        count: stats.totalMembers,
                        icon: Icons.people,
                        color: Colors.purple.shade700,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    l10n.quickActions,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    context,
                    title: l10n.zones,
                    icon: Icons.map,
                    onTap: () => context.push('/zones'),
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    context,
                    title: l10n.allStreets,
                    icon: Icons.add_road,
                    onTap: () => context.push('/streets'),
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    context,
                    title: l10n.allMembers,
                    icon: Icons.people,
                    onTap: () => context.push('/members'),
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    context,
                    title: l10n.birthdays,
                    icon: Icons.cake,
                    onTap: () => context.push('/birthdays'),
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    context,
                    title: l10n.messageTemplates ?? "Message Templates",
                    icon: Icons.message,
                    onTap: () => context.push('/templates'),
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    context,
                    title: l10n.followupReport,
                    icon: Icons.assessment,
                    onTap: () => context.push('/followups/report'),
                  ),
                ],
              ),
            );
          } else if (state is DashboardError) {
            return Center(child: Text(state.message));
          }
          return Container();
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: Colors.white70, size: 20),
              ],
            ),
            Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
