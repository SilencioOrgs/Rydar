import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/scooter_model.dart';
import '../../services/motorcycle_catalog_service.dart';
import 'scooter_model_dropdowns.dart';

class MotorcycleCategoryPicker extends StatelessWidget {
  const MotorcycleCategoryPicker({
    super.key,
    required this.selected,
    required this.onSelected,
    this.selectedId,
    this.brandLabel = 'Brand',
    this.modelLabel = 'Model',
    this.allowAdd = true,
  });

  final ScooterModel? selected;
  final String? selectedId;
  final ValueChanged<ScooterModel> onSelected;
  final String brandLabel;
  final String modelLabel;
  final bool allowAdd;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ScooterModel>>(
      stream: MotorcycleCatalogService.instance.watchModels(),
      builder: (context, snapshot) {
        final models = snapshot.data ?? ScooterCatalog.models;
        final selectedModel = _selectedFrom(models);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScooterModelDropdowns(
              models: models,
              selected: selectedModel,
              onSelected: onSelected,
              brandLabel: brandLabel,
              modelLabel: modelLabel,
            ),
            if (selectedModel.description != null &&
                selectedModel.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              _CategoryDescription(selectedModel.description!),
            ],
            if (snapshot.hasError) ...[
              const SizedBox(height: 8),
              const _InlineCategoryMessage(
                'Could not load shared categories right now.',
              ),
            ],
            if (allowAdd) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _showAddSheet(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('ADD MOTORCYCLE'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.orange,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  ScooterModel _selectedFrom(List<ScooterModel> models) {
    return ScooterCatalog.findById(
          selected?.id ?? selectedId,
          models: models,
        ) ??
        selected ??
        ScooterCatalog.defaultModel;
  }

  Future<void> _showAddSheet(BuildContext context) async {
    final model = await showModalBottomSheet<ScooterModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddMotorcycleSheet(),
    );
    if (model != null) {
      onSelected(model);
    }
  }
}

class _CategoryDescription extends StatelessWidget {
  const _CategoryDescription(this.description);

  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.glassWhite(0.045),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder(0.10)),
      ),
      child: Text(
        description,
        style: TextStyle(
          color: AppColors.text.withValues(alpha: 0.64),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InlineCategoryMessage extends StatelessWidget {
  const _InlineCategoryMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: TextStyle(
        color: AppColors.text.withValues(alpha: 0.56),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _AddMotorcycleSheet extends StatefulWidget {
  const _AddMotorcycleSheet();

  @override
  State<_AddMotorcycleSheet> createState() => _AddMotorcycleSheetState();
}

class _AddMotorcycleSheetState extends State<_AddMotorcycleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _ccController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _ccController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + keyboardInset),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.glassBorder(0.12)),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.two_wheeler_rounded,
                        color: AppColors.orange,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Add motorcycle category',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _FormField(
                    controller: _brandController,
                    label: 'Brand',
                    textCapitalization: TextCapitalization.words,
                    validator: _required,
                  ),
                  const SizedBox(height: 10),
                  _FormField(
                    controller: _modelController,
                    label: 'Model',
                    textCapitalization: TextCapitalization.words,
                    validator: _required,
                  ),
                  const SizedBox(height: 10),
                  _FormField(
                    controller: _ccController,
                    label: 'Engine size',
                    suffixText: 'cc',
                    keyboardType: TextInputType.number,
                    validator: _ccValidator,
                  ),
                  const SizedBox(height: 10),
                  _FormField(
                    controller: _descriptionController,
                    label: 'Description',
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(_saving ? 'SAVING' : 'SAVE CATEGORY'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Required' : null;
  }

  String? _ccValidator(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null) {
      return 'Enter cc';
    }
    if (parsed < 50 || parsed > 2000) {
      return '50 to 2000';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final model = await MotorcycleCatalogService.instance.addMotorcycle(
        brand: _brandController.text,
        name: _modelController.text,
        displacementCc: int.parse(_ccController.text.trim()),
        description: _descriptionController.text,
      );
      if (mounted) {
        Navigator.of(context).pop(model);
      }
    } on MotorcycleCatalogException catch (error) {
      setState(() {
        _saving = false;
        _error = error.message;
      });
    } catch (_) {
      setState(() {
        _saving = false;
        _error = 'Could not save this motorcycle category right now.';
      });
    }
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.suffixText,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final String? suffixText;
  final int maxLines;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      style: const TextStyle(
        color: AppColors.text,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffixText,
        labelStyle: TextStyle(
          color: AppColors.text.withValues(alpha: 0.56),
          fontWeight: FontWeight.w800,
        ),
        filled: true,
        fillColor: AppColors.glassWhite(0.06),
        enabledBorder: _border(AppColors.glassBorder(0.14)),
        focusedBorder: _border(AppColors.orange),
        errorBorder: _border(Colors.redAccent),
        focusedErrorBorder: _border(Colors.redAccent),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );
  }
}
