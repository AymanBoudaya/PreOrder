import 'package:caferesto/common/widgets/appbar/appbar.dart';
import 'package:caferesto/common/widgets/categories/category_card.dart';
import 'package:caferesto/common/widgets/layouts/grid_layout.dart';
import 'package:caferesto/common/widgets/products/cart/cart_menu_icon.dart';
import 'package:caferesto/common/widgets/shimmer/brands_shimmer.dart';
import 'package:caferesto/common/widgets/texts/section_heading.dart';
import 'package:caferesto/features/shop/controllers/category_controller.dart';
import 'package:caferesto/features/shop/screens/sub_category/sub_categories.dart';
import 'package:caferesto/utils/constants/colors.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:caferesto/utils/device/device_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AllCategoriesScreen extends StatefulWidget {
  const AllCategoriesScreen({super.key});

  @override
  State<AllCategoriesScreen> createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends State<AllCategoriesScreen> {
  final categoryController = CategoryController.instance;

  @override
  void initState() {
    super.initState();
    // S'assurer que les catégories sont chargées
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (categoryController.allCategories.isEmpty) {
        categoryController.fetchCategories();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: TAppBar(
        showBackArrow: true,
        title: Text(
          'Catégories',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        actions: [
          TCartCounterIcon(
            iconColor: AppColors.primary,
            counterBgColor: AppColors.primary,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => categoryController.refreshCategories(),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: TDeviceUtils.getHorizontalPadding(screenWidth),
            vertical: AppSizes.defaultSpace,
          ),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// En-tête
              TSectionHeading(
                title: 'Toutes les Catégories',
                showActionButton: false,
              ),
              const SizedBox(height: AppSizes.spaceBtwItems),

              /// Grid de toutes les catégories
              Obx(() {
                // Afficher le shimmer pendant le chargement
                if (categoryController.isLoading.value) {
                  return const TbrandsShimmer();
                }

                // Récupérer toutes les catégories (pas seulement les vedettes)
                final allCategories = categoryController.allCategories.toList();

                if (allCategories.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.defaultSpace),
                      child: Text(
                        'Aucune catégorie trouvée',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  );
                }

                // Utiliser un grid responsive similaire à StoreScreen
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth < 600 ? 1 : 2;
                    final mainAxisExtent = constraints.maxWidth < 400 ? 90.0 : 80.0;

                    return GridLayout(
                      itemCount: allCategories.length,
                      crossAxisCount: crossAxisCount,
                      mainAxisExtent: mainAxisExtent,
                      itemBuilder: (_, index) {
                        final category = allCategories[index];
                        return CategoryCard(
                          showBorder: true,
                          category: category,
                          onTap: () => Get.to(
                            () => SubCategoriesScreen(category: category),
                          ),
                        );
                      },
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

