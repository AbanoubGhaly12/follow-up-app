import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/manage_users_page.dart';
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
import '../../features/admin/presentation/pages/import_data_page.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final isLoginRoute = state.matchedLocation == '/login';

    if (!isLoggedIn && !isLoginRoute) {
      return '/login';
    }
    if (isLoggedIn && isLoginRoute) {
      return '/';
    }
    return null;
  },
  routes: [
    // Admin Routes
    GoRoute(
      path: '/admin/import',
      builder: (context, state) => const ImportDataPage(),
    ),

    // Login Route
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),

    // User Management
    GoRoute(
      path: '/users',
      builder: (context, state) => const ManageUsersPage(),
      routes: [
        GoRoute(
          path: 'add',
          builder: (context, state) => const AddUserPage(),
        ),
      ],
    ),

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
      builder: (context, state) {
        final other = state.uri.queryParameters['other'] == 'true';
        return ZonesListPage(showOnlyOtherZones: other);
      },
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
            final other = state.uri.queryParameters['other'] == 'true';
            return StreetsListPage(zoneId: zid, isReadOnly: other);
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
        final other = state.uri.queryParameters['other'] == 'true';
        return FamiliesListPage(streetId: sid, isReadOnly: other);
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
        final familyName = state.uri.queryParameters['familyName'];
        final other = state.uri.queryParameters['other'] == 'true';
        return MembersListPage(
          familyId: fid,
          familyName: familyName,
          isReadOnly: other,
        );
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
            final familyName = state.uri.queryParameters['familyName'];
            final other = state.uri.queryParameters['other'] == 'true';
            return FollowupHistoryPage(
              familyId: fid,
              familyName: familyName,
              isReadOnly: other,
            );
          },
        ),
        GoRoute(
          path: 'followups/add',
          builder: (context, state) {
            final fid = state.pathParameters['fid']!;
            final familyName = state.uri.queryParameters['familyName'];
            final memberId = state.uri.queryParameters['memberId'];
            final memberName = state.uri.queryParameters['memberName'];
            return FollowupFormPage(
              familyId: fid,
              familyName: familyName,
              memberId: memberId,
              memberName: memberName,
            );
          },
        ),
      ],
    ),
  ],
);
