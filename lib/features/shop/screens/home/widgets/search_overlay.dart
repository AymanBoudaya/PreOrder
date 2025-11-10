import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../common/widgets/appbar/appbar.dart';
import '../../../../../common/widgets/custom_shapes/containers/search_container.dart';
import '../../../../../common/widgets/layouts/grid_layout.dart';
import '../../../../../common/widgets/products/product_cards/product_card_vertical.dart';
import '../../../../../common/widgets/shimmer/vertical_product_shimmer.dart';
import '../../../../../common/widgets/texts/section_heading.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/device/device_utility.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/search_controller.dart';
import '../../../models/category_model.dart';
import '../../../models/etablissement_model.dart';

class SearchOverlay extends StatefulWidget {
  const SearchOverlay({super.key});

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay> {
  final ResearchController controller = Get.put(ResearchController());
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showFilters = true;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
    
    // Initialiser avec les produits
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.allProducts.isEmpty) {
        controller.fetchAllProducts(reset: true);
      }
    });

    // Listener pour la pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !controller.isPaginating.value &&
          controller.query.value.isEmpty &&
          controller.hasMore.value) {
        controller.fetchAllProducts();
      }

      // Masquer/afficher les filtres lors du scroll
      if (_scrollController.offset > 100 && _showFilters) {
        setState(() => _showFilters = false);
      } else if (_scrollController.offset <= 100 && !_showFilters) {
        setState(() => _showFilters = true);
      }
    });

    // Lier le controller de texte avec debounce
    _searchController.addListener(() {
      controller.onSearchChanged(_searchController.text);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: dark ? AppColors.dark : AppColors.light,
      appBar: TAppBar(
        showBackArrow: true,
        title: Text(
          'Recherche',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.fetchAllProducts(reset: true),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: TDeviceUtils.getHorizontalPadding(screenWidth),
              vertical: AppSizes.defaultSpace,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// --- Search Field ---
                TSearchContainer(
                  text: 'Rechercher un produit, établissement...',
                  icon: Iconsax.search_normal,
                  controller: _searchController,
                  showBackground: true,
                  showBorder: true,
                ),
                const SizedBox(height: AppSizes.spaceBtwSections),

                /// --- Active Filters ---
                Obx(() => _buildActiveFilters(dark)),
                
                /// --- Filters Section ---
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _showFilters
                      ? Column(
                          children: [
                            const SizedBox(height: AppSizes.spaceBtwItems),
                            _buildFiltersSection(dark, screenWidth),
                            const SizedBox(height: AppSizes.spaceBtwSections),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),

                /// --- Results Section ---
                Obx(() => _buildResultsSection(dark, screenWidth)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Active Filters avec badges
  Widget _buildActiveFilters(bool dark) {
    if (!controller.hasActiveFilters) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      margin: const EdgeInsets.only(bottom: AppSizes.spaceBtwItems),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkContainer : AppColors.lightContainer,
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd),
        border: Border.all(
          color: dark ? AppColors.darkerGrey : AppColors.grey,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtres actifs:',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: dark ? AppColors.grey : AppColors.darkerGrey,
                ),
          ),
          const SizedBox(height: AppSizes.sm),
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: [
              if (controller.query.value.isNotEmpty)
                _buildFilterChip(
                  label: 'Recherche: "${controller.query.value}"',
                  onRemove: () {
                    _searchController.clear();
                    controller.clearSearch();
                  },
                  dark: dark,
                ),
              if (controller.selectedCategory.value != null)
                _buildFilterChip(
                  label: 'Catégorie: ${controller.selectedCategoryName}',
                  onRemove: controller.clearCategoryFilter,
                  dark: dark,
                ),
              if (controller.selectedEtablissement.value != null)
                _buildFilterChip(
                  label: 'Établissement: ${controller.selectedEtablissementName}',
                  onRemove: controller.clearEtablissementFilter,
                  dark: dark,
                ),
              if (controller.selectedSort.value.isNotEmpty)
                _buildFilterChip(
                  label: 'Tri: ${controller.selectedSort.value}',
                  onRemove: controller.clearSortFilter,
                  dark: dark,
                ),
              _buildClearAllChip(dark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onRemove,
    required bool dark,
  }) {
    return Chip(
      label: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.white,
            ),
      ),
      backgroundColor: AppColors.primary,
      deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.white),
      onDeleted: onRemove,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelPadding: const EdgeInsets.symmetric(horizontal: AppSizes.xs),
    );
  }

  Widget _buildClearAllChip(bool dark) {
    return InkWell(
      onTap: () {
        _searchController.clear();
        controller.clearAllFilters();
      },
      borderRadius: BorderRadius.circular(AppSizes.cardRadiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.cardRadiusSm),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.clear_all, size: 16, color: AppColors.error),
            const SizedBox(width: AppSizes.xs),
            Text(
              'Tout effacer',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.error,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Section des filtres
  Widget _buildFiltersSection(bool dark, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TSectionHeading(
          title: 'Filtres',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSizes.spaceBtwItems),
        Row(
          children: [
            Expanded(child: _buildCategoryFilter(dark)),
            const SizedBox(width: AppSizes.spaceBtwItems),
            Expanded(child: _buildEtablissementFilter(dark)),
          ],
        ),
        const SizedBox(height: AppSizes.spaceBtwItems),
        _buildSortFilter(dark),
      ],
    );
  }

  Widget _buildCategoryFilter(bool dark) {
    return Obx(() => DropdownButtonFormField<CategoryModel>(
          value: controller.selectedCategory.value,
          decoration: InputDecoration(
            labelText: 'Catégorie',
            filled: true,
            fillColor: dark ? AppColors.darkContainer : AppColors.lightContainer,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.inputFieldRadius),
              borderSide: BorderSide(
                color: dark ? AppColors.darkerGrey : AppColors.grey,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.inputFieldRadius),
              borderSide: BorderSide(
                color: dark ? AppColors.darkerGrey : AppColors.grey,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.inputFieldRadius),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.sm,
            ),
          ),
          isExpanded: true,
          dropdownColor: dark ? AppColors.dark : AppColors.white,
          style: Theme.of(context).textTheme.bodyMedium,
          items: [
            DropdownMenuItem<CategoryModel>(
              value: null,
              child: Text(
                'Toutes les catégories',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: dark ? AppColors.grey : AppColors.darkerGrey,
                    ),
              ),
            ),
            ...controller.categories.map((category) {
              return DropdownMenuItem<CategoryModel>(
                value: category,
                child: Text(
                  category.name,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ],
          onChanged: controller.onCategorySelected,
        ));
  }

  Widget _buildEtablissementFilter(bool dark) {
    return Obx(() => DropdownButtonFormField<Etablissement>(
          value: controller.selectedEtablissement.value,
          decoration: InputDecoration(
            labelText: 'Établissement',
            filled: true,
            fillColor: dark ? AppColors.darkContainer : AppColors.lightContainer,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.inputFieldRadius),
              borderSide: BorderSide(
                color: dark ? AppColors.darkerGrey : AppColors.grey,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.inputFieldRadius),
              borderSide: BorderSide(
                color: dark ? AppColors.darkerGrey : AppColors.grey,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.inputFieldRadius),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.sm,
            ),
          ),
          dropdownColor: dark ? AppColors.dark : AppColors.white,
          isExpanded: true,
          style: Theme.of(context).textTheme.bodyMedium,
          items: [
            DropdownMenuItem<Etablissement>(
              value: null,
              child: Text(
                'Tous les établissements',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: dark ? AppColors.grey : AppColors.darkerGrey,
                    ),
              ),
            ),
            ...controller.etablissements.map((etablissement) {
              return DropdownMenuItem<Etablissement>(
                value: etablissement,
                child: Text(
                  etablissement.name,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ],
          onChanged: controller.onEtablissementSelected,
        ));
  }

  Widget _buildSortFilter(bool dark) {
    return Obx(() => DropdownButtonFormField<String>(
          value: controller.selectedSort.value.isEmpty
              ? null
              : controller.selectedSort.value,
          decoration: InputDecoration(
            labelText: 'Trier par',
            filled: true,
            fillColor: dark ? AppColors.darkContainer : AppColors.lightContainer,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.inputFieldRadius),
              borderSide: BorderSide(
                color: dark ? AppColors.darkerGrey : AppColors.grey,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.inputFieldRadius),
              borderSide: BorderSide(
                color: dark ? AppColors.darkerGrey : AppColors.grey,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.inputFieldRadius),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.sm,
            ),
          ),
          dropdownColor: dark ? AppColors.dark : AppColors.white,
          style: Theme.of(context).textTheme.bodyMedium,
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                'Aucun tri',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: dark ? AppColors.grey : AppColors.darkerGrey,
                    ),
              ),
            ),
            ...['Prix ↑', 'Prix ↓', 'Nom A-Z', 'Popularité'].map((sort) {
              return DropdownMenuItem<String>(
                value: sort,
                child: Text(
                  sort,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }),
          ],
          onChanged: controller.onSortSelected,
        ));
  }

  /// Section des résultats
  Widget _buildResultsSection(bool dark, double screenWidth) {
    if (controller.isLoading.value && controller.searchResults.isEmpty) {
      return const TVerticalProductShimmer();
    }

    if (controller.searchResults.isEmpty) {
      return _buildEmptyState(dark);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Info nombre de résultats
        Container(
          padding: const EdgeInsets.all(AppSizes.md),
          margin: const EdgeInsets.only(bottom: AppSizes.spaceBtwItems),
          decoration: BoxDecoration(
            color: dark ? AppColors.darkContainer : AppColors.lightContainer,
            borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${controller.searchResults.length} produit(s) trouvé(s)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: dark ? AppColors.grey : AppColors.darkerGrey,
                    ),
              ),
              if (controller.hasActiveFilters)
                Icon(
                  Iconsax.info_circle,
                  size: AppSizes.iconSm,
                  color: AppColors.primary,
                ),
            ],
          ),
        ),

        /// Grid de produits
        GridLayout(
          itemCount: controller.searchResults.length,
          itemBuilder: (_, index) {
            return ProductCardVertical(
              product: controller.searchResults[index],
            );
          },
          crossAxisCount: TDeviceUtils.getCrossAxisCount(screenWidth),
          mainAxisExtent: TDeviceUtils.getMainAxisExtent(screenWidth),
        ),
        const SizedBox(height: AppSizes.spaceBtwSections),

        /// Pagination loader
        if (controller.isPaginating.value)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSizes.defaultSpace),
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  /// État vide amélioré
  Widget _buildEmptyState(bool dark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.defaultSpace * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.search_normal_1,
              size: 80,
              color: dark ? AppColors.grey : AppColors.darkerGrey,
            ),
            const SizedBox(height: AppSizes.spaceBtwSections),
            Text(
              'Aucun produit trouvé',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spaceBtwItems),
            Obx(() {
              if (controller.hasActiveFilters) {
                return Column(
                  children: [
                    Text(
                      'Essayez de modifier vos filtres de recherche',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: dark ? AppColors.grey : AppColors.darkerGrey,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.spaceBtwSections),
                    ElevatedButton.icon(
                      onPressed: () {
                        _searchController.clear();
                        controller.clearAllFilters();
                      },
                      icon: const Icon(Iconsax.refresh),
                      label: const Text('Réinitialiser les filtres'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                      ),
                    ),
                  ],
                );
              } else {
                return Text(
                  'Aucun produit ne correspond à votre recherche',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: dark ? AppColors.grey : AppColors.darkerGrey,
                      ),
                  textAlign: TextAlign.center,
                );
              }
            }),
          ],
        ),
      ),
    );
  }
}
