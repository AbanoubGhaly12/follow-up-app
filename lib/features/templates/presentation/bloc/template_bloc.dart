import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/template_repository.dart';
import 'template_event.dart';
import 'template_state.dart';

class TemplateBloc extends Bloc<TemplateEvent, TemplateState> {
  final TemplateRepository repository;

  TemplateBloc({required this.repository}) : super(TemplateInitial()) {
    on<LoadTemplates>(_onLoadTemplates);
    on<AddTemplate>(_onAddTemplate);
    on<UpdateTemplate>(_onUpdateTemplate);
    on<DeleteTemplate>(_onDeleteTemplate);
  }

  Future<void> _onLoadTemplates(
    LoadTemplates event,
    Emitter<TemplateState> emit,
  ) async {
    emit(TemplateLoading());
    try {
      final templates = await repository.getAllTemplates();
      emit(TemplateLoaded(templates));
    } catch (e) {
      emit(TemplateError(e.toString()));
    }
  }

  Future<void> _onAddTemplate(
    AddTemplate event,
    Emitter<TemplateState> emit,
  ) async {
    try {
      await repository.insertTemplate(event.template);
      add(LoadTemplates());
    } catch (e) {
      emit(TemplateError(e.toString()));
    }
  }

  Future<void> _onUpdateTemplate(
    UpdateTemplate event,
    Emitter<TemplateState> emit,
  ) async {
    try {
      await repository.updateTemplate(event.template);
      add(LoadTemplates());
    } catch (e) {
      emit(TemplateError(e.toString()));
    }
  }

  Future<void> _onDeleteTemplate(
    DeleteTemplate event,
    Emitter<TemplateState> emit,
  ) async {
    try {
      await repository.deleteTemplate(event.id);
      add(LoadTemplates());
    } catch (e) {
      emit(TemplateError(e.toString()));
    }
  }
}
