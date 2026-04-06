import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final Locale locale;

  const SettingsState({required this.locale});

  @override
  List<Object> get props => [locale];
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState(locale: Locale('ar')));

  void changeLocale(Locale locale) {
    emit(SettingsState(locale: locale));
  }

  void toggleLocale() {
    if (state.locale.languageCode == 'ar') {
      emit(const SettingsState(locale: Locale('en')));
    } else {
      emit(const SettingsState(locale: Locale('ar')));
    }
  }
}
