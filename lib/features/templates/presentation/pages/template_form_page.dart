import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../data/models/template_model.dart';
import '../bloc/template_bloc.dart';
import '../bloc/template_event.dart';

class TemplateFormPage extends StatefulWidget {
  final TemplateModel? template;

  const TemplateFormPage({super.key, this.template});

  @override
  State<TemplateFormPage> createState() => _TemplateFormPageState();
}

class _TemplateFormPageState extends State<TemplateFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  TemplateType _selectedType = TemplateType.generic;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.template?.title ?? '',
    );
    _contentController = TextEditingController(
      text: widget.template?.content ?? '',
    );
    if (widget.template != null) {
      _selectedType = widget.template!.type;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _insertPlaceholder(String placeholder) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    if (selection.baseOffset < 0 || selection.extentOffset < 0) {
      _contentController.text = text + placeholder;
    } else {
      final newText = text.replaceRange(
        selection.baseOffset,
        selection.extentOffset,
        placeholder,
      );
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.baseOffset + placeholder.length,
        ),
      );
    }
  }

  void _saveTemplate() {
    if (_formKey.currentState!.validate()) {
      final isNew = widget.template == null;
      final template = TemplateModel(
        id: isNew ? const Uuid().v4() : widget.template!.id,
        title: _titleController.text,
        type: _selectedType,
        content: _contentController.text,
        createdAt: isNew ? DateTime.now() : widget.template!.createdAt,
        updatedAt: DateTime.now(),
      );

      if (isNew) {
        context.read<TemplateBloc>().add(AddTemplate(template));
      } else {
        context.read<TemplateBloc>().add(UpdateTemplate(template));
      }

      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isNew = widget.template == null;

    return Scaffold(
      appBar: AppBar(title: Text(isNew ? l10n.addTemplate : l10n.editTemplate)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.title,
                  border: const OutlineInputBorder(),
                ),
                validator:
                    (value) => value!.isEmpty ? l10n.requiredField : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TemplateType>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: l10n.templateType,
                  border: const OutlineInputBorder(),
                ),
                items:
                    TemplateType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.name.toUpperCase()),
                      );
                    }).toList(),
                onChanged: (val) {
                  setState(() {
                    if (val != null) _selectedType = val;
                  });
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Content",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 16),
                    label: const Text("Insert {MemberName}"),
                    onPressed: () => _insertPlaceholder("{MemberName}"),
                    backgroundColor: Colors.blue.shade100,
                    side: BorderSide.none,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TextFormField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: "Enter your message here...",
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) => value!.isEmpty ? l10n.requiredField : null,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveTemplate,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
