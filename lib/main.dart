import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'core/di/injection_container.dart' as di;
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/settings/settings_cubit.dart';
import 'features/zones/presentation/bloc/zone_bloc.dart';
import 'features/streets/presentation/bloc/street_bloc.dart';
import 'features/families/presentation/bloc/family_bloc.dart';
import 'features/members/presentation/bloc/member_bloc.dart';
import 'features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'features/templates/presentation/bloc/template_bloc.dart';
import 'features/templates/presentation/bloc/template_event.dart';
import 'features/followups/presentation/bloc/followup_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<ZoneBloc>()),
        BlocProvider(create: (_) => di.sl<StreetBloc>()),
        BlocProvider(create: (_) => di.sl<FamilyBloc>()),
        BlocProvider(create: (_) => di.sl<MemberBloc>()),
        BlocProvider(create: (_) => di.sl<DashboardCubit>()),
        BlocProvider(create: (_) => di.sl<SettingsCubit>()),
        BlocProvider(
          create: (_) => di.sl<TemplateBloc>()..add(LoadTemplates()),
        ),
        BlocProvider(create: (_) => di.sl<FollowupBloc>()),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Church Follow Up',
            theme: AppTheme.lightTheme,
            locale: state.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ar', ''), // Arabic
              Locale('en', ''), // English
            ],
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
