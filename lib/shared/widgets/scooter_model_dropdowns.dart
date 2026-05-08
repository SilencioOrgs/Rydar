import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/scooter_model.dart';

class ScooterModelDropdowns extends StatelessWidget {
  const ScooterModelDropdowns({
    super.key,
    required this.selected,
    required this.onSelected,
    this.models = ScooterCatalog.models,
    this.brandLabel = 'Brand',
    this.modelLabel = 'Model',
  });

  final ScooterModel? selected;
  final ValueChanged<ScooterModel> onSelected;
  final List<ScooterModel> models;
  final String brandLabel;
  final String modelLabel;

  @override
  Widget build(BuildContext context) {
    final catalog = _modelsWithSelected();
    final selectedModel =
        ScooterCatalog.findById(selected?.id, models: catalog) ??
        selected ??
        ScooterCatalog.defaultModel;
    final brands = catalog
        .map((model) => model.brand)
        .toSet()
        .toList(growable: false);
    final brandModels = ScooterCatalog.byBrand(
      selectedModel.brand,
      models: catalog,
    );

    return Column(
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('scooter-brand-${selectedModel.brand}'),
          initialValue: selectedModel.brand,
          isExpanded: true,
          dropdownColor: AppColors.panel,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
          ),
          decoration: _decoration(brandLabel),
          items: brands
              .map(
                (brand) => DropdownMenuItem(
                  value: brand,
                  child: Text(brand, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (brand) {
            if (brand == null || brand == selectedModel.brand) {
              return;
            }
            final brandModels = ScooterCatalog.byBrand(brand, models: catalog);
            if (brandModels.isNotEmpty) {
              onSelected(brandModels.first);
            }
          },
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          key: ValueKey('scooter-model-${selectedModel.id}'),
          initialValue: selectedModel.id,
          isExpanded: true,
          dropdownColor: AppColors.panel,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
          ),
          decoration: _decoration(modelLabel),
          items: brandModels
              .map(
                (model) => DropdownMenuItem(
                  value: model.id,
                  child: Text(
                    '${model.name} (${model.ccLabel})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (id) {
            final model = ScooterCatalog.findById(id, models: catalog);
            if (model != null) {
              onSelected(model);
            }
          },
        ),
      ],
    );
  }

  List<ScooterModel> _modelsWithSelected() {
    final baseModels = models.isEmpty ? ScooterCatalog.models : models;
    final selectedModel = selected;
    if (selectedModel == null ||
        ScooterCatalog.findById(selectedModel.id, models: baseModels) != null) {
      return baseModels;
    }
    return [...baseModels, selectedModel];
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: AppColors.text.withValues(alpha: 0.56),
        fontWeight: FontWeight.w800,
      ),
      filled: true,
      fillColor: AppColors.glassWhite(0.06),
      enabledBorder: _border(AppColors.glassBorder(0.14)),
      focusedBorder: _border(AppColors.orange),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );
  }
}
