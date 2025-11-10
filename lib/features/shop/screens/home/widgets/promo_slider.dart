import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../models/banner_model.dart';
import '../../../models/category_model.dart';
import '../../../models/produit_model.dart';
import '../../brand/brand_products.dart';
import '../../product_details/product_detail.dart';
import '../../sub_category/sub_categories.dart';
import '../../../controllers/category_controller.dart';
import '../../../../../data/repositories/product/produit_repository.dart';
import '../../../controllers/etablissement_controller.dart';

class TPromoSlider extends StatefulWidget {
  const TPromoSlider({
    super.key,
    required this.banners,
    required this.height,
    this.autoPlay = true,
    this.autoPlayInterval = 4000,
  });

  final List<BannerModel> banners;
  final double height;
  final bool autoPlay;
  final int autoPlayInterval;

  @override
  State<TPromoSlider> createState() => _TPromoSliderState();
}

class _TPromoSliderState extends State<TPromoSlider> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    if (widget.autoPlay && widget.banners.length > 1) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(Duration(milliseconds: widget.autoPlayInterval),
        (timer) {
      if (_currentPage < widget.banners.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _goToNextPage() {
    if (_currentPage < widget.banners.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
    _resetAutoPlay();
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController.animateToPage(
        widget.banners.length - 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
    _resetAutoPlay();
  }

  void _resetAutoPlay() {
    if (widget.autoPlay) {
      _timer?.cancel();
      _startAutoPlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dark = THelperFunctions.isDarkMode(context);

    return Column(
      children: [
        /// Banner Slider avec boutons de navigation
        SizedBox(
          height: widget.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              /// PageView principal
              PageView.builder(
                controller: _pageController,
                itemCount: widget.banners.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (_, index) {
                  return _buildBannerItem(
                      widget.banners[index], screenWidth, dark);
                },
              ),

              /// Bouton de navigation gauche - seulement s'il y a plus d'une image
              if (widget.banners.length > 1)
                Positioned(
                  left: 8,
                  child: _buildNavigationButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: _goToPreviousPage,
                  ),
                ),

              /// Bouton de navigation droite - seulement s'il y a plus d'une image
              if (widget.banners.length > 1)
                Positioned(
                  right: 8,
                  child: _buildNavigationButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: _goToNextPage,
                  ),
                ),
            ],
          ),
        ),

        /// Indicateurs de points
        if (widget.banners.length > 1) ...[
          const SizedBox(height: AppSizes.spaceBtwItems),
          _buildDotIndicators(),
        ],
      ],
    );
  }

  Widget _buildBannerItem(BannerModel banner, double screenWidth, bool dark) {
    return Padding(
      padding: _getBannerPadding(screenWidth),
      child: InkWell(
        onTap: () => _handleBannerTap(banner),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: _getBannerBorderRadius(screenWidth),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: _getBannerBorderRadius(screenWidth),
            child: Stack(
              children: [
                /// Image de fond avec fit optimisé
                CachedNetworkImage(
                  imageUrl: banner.imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) {
                    return Container(
                      color: AppColors.primary,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.white, size: 40),
                            const SizedBox(height: 8),
                            Text(
                              'Image non trouvée',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                /// Overlay gradient pour améliorer la lisibilité
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleBannerTap(BannerModel banner) {
    if (banner.link == null || banner.link!.isEmpty) {
      return; // Pas de lien, ne rien faire
    }

    if (banner.linkType == null || banner.linkType!.isEmpty) {
      return; // Pas de type de lien, ne rien faire
    }

    switch (banner.linkType) {
      case 'product':
        _navigateToProduct(banner.link!);
        break;
      case 'category':
        _navigateToCategory(banner.link!);
        break;
      case 'establishment':
        _navigateToEstablishment(banner.link!);
        break;
      default:
        break;
    }
  }

  void _navigateToProduct(String productId) async {
    try {
      final produitRepository = ProduitRepository.instance;
      final products = await produitRepository.getAllProducts();
      final product = products.firstWhere(
        (p) => p.id == productId,
        orElse: () => ProduitModel.empty(),
      );

      if (product.id.isNotEmpty) {
        Get.to(() => ProductDetailScreen(product: product));
      } else {
        Get.snackbar(
          'Erreur',
          'Produit non trouvé',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger le produit',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _navigateToCategory(String categoryId) async {
    try {
      final categoryController = Get.find<CategoryController>();
      await categoryController.fetchCategories();
      final category = categoryController.allCategories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => CategoryModel.empty(),
      );

      if (category.id.isNotEmpty) {
        Get.to(() => SubCategoriesScreen(category: category));
      } else {
        Get.snackbar(
          'Erreur',
          'Catégorie non trouvée',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger la catégorie',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _navigateToEstablishment(String establishmentId) async {
    try {
      final etablissementController = Get.find<EtablissementController>();
      final establishments = await etablissementController.getTousEtablissements();
      final establishmentIndex = establishments.indexWhere(
        (e) => e.id == establishmentId,
      );

      if (establishmentIndex >= 0) {
        final establishment = establishments[establishmentIndex];
        Get.to(() => BrandProducts(brand: establishment));
      } else {
        Get.snackbar(
          'Erreur',
          'Établissement non trouvé',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger l\'établissement',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withOpacity(0.4),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildDotIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < widget.banners.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _currentPage == i ? 24 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color:
                  _currentPage == i ? AppColors.primary : Colors.grey.shade400,
              boxShadow: _currentPage == i
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
          ),
      ],
    );
  }

  /// Détermine le padding du banner selon la largeur de l'écran
  EdgeInsets _getBannerPadding(double screenWidth) {
    if (screenWidth < 480) {
      return const EdgeInsets.symmetric(horizontal: 4); // Réduit le padding
    } else if (screenWidth < 768) {
      return const EdgeInsets.symmetric(horizontal: 6);
    } else if (screenWidth < 1024) {
      return const EdgeInsets.symmetric(horizontal: 8);
    } else {
      return const EdgeInsets.symmetric(horizontal: 10);
    }
  }

  /// Détermine le border radius selon la largeur de l'écran
  BorderRadius _getBannerBorderRadius(double screenWidth) {
    if (screenWidth < 480) {
      return BorderRadius.circular(16);
    } else if (screenWidth < 768) {
      return BorderRadius.circular(20);
    } else {
      return BorderRadius.circular(24);
    }
  }
}
