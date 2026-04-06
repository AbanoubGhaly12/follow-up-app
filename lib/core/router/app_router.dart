import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';

import '../../features/zones/presentation/pages/zones_list_page.dart';
import '../../features/zones/presentation/pages/zone_form_page.dart';
import '../../features/zones/data/models/zone_model.dart';

import '../../features/streets/presentation/pages/streets_list_page.dart';
import '../../features/streets/presentation/pages/street_form_page.dart';
import '../../features/streets/data/models/street_model.dart';

import '../../features/families/presentation/pages/families_list_page.dart';
import '../../features/families/presentation/pages/family_form_page.dart';
import '../../features/families/data/models/family_model.dart';

import '../../features/members/presentation/pages/members_list_page.dart';
import '../../features/members/presentation/pages/member_form_page.dart';
import '../../features/members/presentation/pages/birthdays_list_page.dart';
import '../../features/templates/presentation/pages/templates_list_page.dart';
import '../../features/templates/presentation/pages/template_form_page.dart';
import '../../features/templates/data/models/template_model.dart';
import '../../features/members/data/models/member_model.dart';
import '../../features/followups/presentation/pages/followup_history_page.dart';
import '../../features/followups/presentation/pages/followup_form_page.dart';
import '../../features/followups/presentation/pages/followups_report_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Dashboard Route
    GoRoute(path: '/', builder: (context, state) => const DashboardPage()),

    // Global Routes (From Quick Actions)
    GoRoute(
      path: '/templates',
      builder: (context, state) => const TemplatesListPage(),
    ),
    GoRoute(
      path: '/templates/add',
      builder: (context, state) => const TemplateFormPage(),
    ),
    GoRoute(
      path: '/templates/edit',
      builder:
          (context, state) =>
              TemplateFormPage(template: state.extra as TemplateModel),
    ),
    GoRoute(
      path: '/birthdays',
      builder: (context, state) => const BirthdaysListPage(),
    ),
    GoRoute(
      path: '/streets',
      builder: (context, state) => const StreetsListPage(),
    ),
    GoRoute(
      path: '/members',
      builder: (context, state) => const MembersListPage(),
    ),
    GoRoute(
      path: '/followups/report',
      builder: (context, state) => const FollowupsReportPage(),
    ),

    // Hierarchy Routes
    GoRoute(
      path: '/zones',
      builder: (context, state) => const ZonesListPage(),
      routes: [
        GoRoute(path: 'add', builder: (context, state) => const ZoneFormPage()),
        GoRoute(
          path: 'edit',
          builder: (context, state) {
            final zone = state.extra as ZoneModel;
            return ZoneFormPage(zone: zone);
          },
        ),
        GoRoute(
          path: ':zid',
          builder: (context, state) {
            final zid = state.pathParameters['zid']!;
            return StreetsListPage(zoneId: zid);
          },
          routes: [
            GoRoute(
              path: 'streets/add',
              builder: (context, state) {
                final zid = state.pathParameters['zid']!;
                return StreetFormPage(zoneId: zid);
              },
            ),
            GoRoute(
              path: 'streets/edit',
              builder: (context, state) {
                final zid = state.pathParameters['zid']!;
                final street = state.extra as StreetModel;
                return StreetFormPage(zoneId: zid, street: street);
              },
            ),
          ],
        ),
      ],
    ),

    GoRoute(
      path: '/streets/:sid',
      builder: (context, state) {
        final sid = state.pathParameters['sid']!;
        return FamiliesListPage(streetId: sid);
      },
      routes: [
        GoRoute(
          path: 'families/add',
          builder: (context, state) {
            final sid = state.pathParameters['sid']!;
            return FamilyFormPage(streetId: sid);
          },
        ),
        GoRoute(
          path: 'families/edit',
          builder: (context, state) {
            final sid = state.pathParameters['sid']!;
            final family = state.extra as FamilyModel;
            return FamilyFormPage(streetId: sid, family: family);
          },
        ),
      ],
    ),

    GoRoute(
      path: '/families/:fid',
      builder: (context, state) {
        final fid = state.pathParameters['fid']!;
        return MembersListPage(familyId: fid);
      },
      routes: [
        GoRoute(
          path: 'members/add',
          builder: (context, state) {
            final fid = state.pathParameters['fid']!;
            return MemberFormPage(familyId: fid);
          },
        ),
        GoRoute(
          path: 'members/edit',
          builder: (context, state) {
            final fid = state.pathParameters['fid']!;
            final member = state.extra as MemberModel;
            return MemberFormPage(familyId: fid, member: member);
          },
        ),
        GoRoute(
          path: 'followups',
          builder: (context, state) {
            final fid = state.pathParameters['fid']!;
            return FollowupHistoryPage(familyId: fid);
          },
        ),
        GoRoute(
          path: 'followups/add',
          builder: (context, state) {
            final fid = state.pathParameters['fid']!;
            return FollowupFormPage(familyId: fid);
          },
        ),
      ],
    ),
  ],
);
