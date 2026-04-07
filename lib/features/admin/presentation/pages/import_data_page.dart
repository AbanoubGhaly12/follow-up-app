import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/import_service.dart';

class ImportDataPage extends StatefulWidget {
  const ImportDataPage({super.key});

  @override
  State<ImportDataPage> createState() => _ImportDataPageState();
}

class _ImportDataPageState extends State<ImportDataPage> {
  String _selectedType = 'Zones';
  PlatformFile? _selectedFile;
  bool _isImporting = false;
  ImportResult? _result;

  final List<String> _types = ['Zones', 'Streets', 'Families', 'Members'];

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
        _result = null;
      });
    }
  }

  Future<void> _runImport() async {
    if (_selectedFile == null) return;

    setState(() {
      _isImporting = true;
      _result = null;
    });

    try {
      final file = File(_selectedFile!.path!);
      final csvContent = await file.readAsString();
      final importer = sl<ImportService>();

      ImportResult res;
      switch (_selectedType) {
        case 'Zones':
          res = await importer.importZones(csvContent);
          break;
        case 'Streets':
          res = await importer.importStreets(csvContent);
          break;
        case 'Families':
          res = await importer.importFamilies(csvContent);
          break;
        case 'Members':
          res = await importer.importMembers(csvContent);
          break;
        default:
          throw Exception("Unknown import type");
      }

      setState(() {
        _result = res;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Import failed: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.importData),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(height: 8),
                    Text(
                      l10n.importDataDescription,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.importSequenceWarning,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText:  l10n.category,
                border: const OutlineInputBorder(),
              ),
              items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) => setState(() => _selectedType = val!),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _isImporting ? null : _pickFile,
              icon: const Icon(Icons.file_open),
              label: Text(_selectedFile == null ? l10n.selectCsvFile : 'File: ${_selectedFile!.name}'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: (_selectedFile == null || _isImporting) ? null : _runImport,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              child: _isImporting 
                ? const CircularProgressIndicator(color: Colors.white) 
                : Text(l10n.startImport),
            ),
            if (_result != null) ...[
              const SizedBox(height: 32),
              _buildResultSummary(l10n),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultSummary(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.importResults, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem(l10n.success, _result!.successCount, Colors.green),
            _statItem(l10n.skipped, _result!.skipCount, Colors.orange),
            _statItem(l10n.errorsCount, _result!.errors.length, Colors.red),
          ],
        ),
        if (_result!.errors.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text("Error Details:"),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(8),
              itemCount: _result!.errors.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) => Text(
                _result!.errors[index],
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _statItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(value.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
