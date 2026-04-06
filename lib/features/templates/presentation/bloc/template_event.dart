import 'package:equatable/equatable.dart';
import '../../data/models/template_model.dart';

abstract class TemplateEvent extends Equatable {
  const TemplateEvent();

  @override
  List<Object?> get props => [];
}

class LoadTemplates extends TemplateEvent {}

class AddTemplate extends TemplateEvent {
  final TemplateModel template;
  const AddTemplate(this.template);

  @override
  List<Object?> get props => [template];
}

class UpdateTemplate extends TemplateEvent {
  final TemplateModel template;
  const UpdateTemplate(this.template);

  @override
  List<Object?> get props => [template];
}

class DeleteTemplate extends TemplateEvent {
  final String id;
  const DeleteTemplate(this.id);

  @override
  List<Object?> get props => [id];
}
