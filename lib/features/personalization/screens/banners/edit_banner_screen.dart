import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../shop/controllers/banner_controller.dart';
import '../../../shop/controllers/category_controller.dart';
import '../../../shop/controllers/etablissement_controller.dart';
import '../../../../data/repositories/product/produit_repository.dart';
import '../../../shop/models/banner_model.dart';

class EditBannerScreen extends StatelessWidget {
  final BannerModel banner;

  const EditBannerScreen({super.key, required this.banner});

  @override
  Widget build(BuildContext context) {
    final bannerController = Get.find<BannerController>();
    final categoryController = Get.find<CategoryController>();
    final produitRepository = ProduitRepository.instance;
    final etablissementController = Get.find<EtablissementController>();

    // Charger les données pour les dropdowns
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      bannerController.categories.assignAll(categoryController.allCategories);
      try {
        final products = await produitRepository.getAllProducts();
        bannerController.products.assignAll(products);
      } catch (e) {
        debugPrint('Erreur chargement produits: $e');
      }
      try {
        final establishments = await etablissementController.getTousEtablissements();
        bannerController.establishments.assignAll(establishments);
      } catch (e) {
        debugPrint('Erreur chargement établissements: $e');
      }
    });

    // Charger la bannière pour édition
    WidgetsBinding.instance.addPostFrameCallback((_) {
      bannerController.loadBannerForEditing(banner);
    });

    return Scaffold(
      appBar: TAppBar(
        title: const Text("Modifier la bannière"),
      ),
      body: Obx(() => _buildBody(context, bannerController)),
    );
  }

  Widget _buildBody(BuildContext context, BannerController controller) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.defaultSpace),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Image
              _buildImageSection(context, controller, isMobile),
              const SizedBox(height: AppSizes.spaceBtwSections),

              // Nom de la bannière
              TextFormField(
                controller: controller.nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la bannière',
                  prefixIcon: Icon(Iconsax.text),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.spaceBtwInputFields),

              // Type de lien
              Obx(() {
                final currentValue = controller.selectedLinkType.value;
                return DropdownButtonFormField<String?>(
                  value: currentValue.isEmpty ? null : currentValue,
                  decoration: const InputDecoration(
                    labelText: 'Type de lien',
                    prefixIcon: Icon(Iconsax.link),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Aucun lien')),
                    DropdownMenuItem(value: 'product', child: Text('Produit')),
                    DropdownMenuItem(value: 'category', child: Text('Catégorie')),
                    DropdownMenuItem(
                      value: 'establishment',
                      child: Text('Établissement'),
                    ),
                  ],
                  onChanged: (value) {
                    controller.selectedLinkType.value = value ?? '';
                    if (value != banner.linkType) {
                      controller.selectedLinkId.value = ''; // Reset selection
                    }
                  },
                );
              }),
              const SizedBox(height: AppSizes.spaceBtwInputFields),

              // Sélection du lien selon le type
              if (controller.selectedLinkType.value.isNotEmpty)
                _buildLinkSelector(context, controller),
              const SizedBox(height: AppSizes.spaceBtwInputFields),

              // Bannière mise en avant
              SwitchListTile(
                title: const Text('Bannière mise en avant'),
                subtitle: const Text('Afficher cette bannière sur la page d\'accueil'),
                value: controller.isFeatured.value,
                onChanged: (value) {
                  controller.isFeatured.value = value;
                },
                secondary: Icon(
                  Iconsax.star,
                  color: controller.isFeatured.value
                      ? Colors.amber
                      : Colors.grey,
                ),
              ),
              const SizedBox(height: AppSizes.spaceBtwSections),

              // Bouton Modifier
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () => controller.updateBanner(banner.id),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Modifier la bannière'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(
    BuildContext context,
    BannerController controller,
    bool isMobile,
  ) {
    final dark = THelperFunctions.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkContainer : Colors.grey[100],
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Image de la bannière',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSizes.spaceBtwItems),
          Obx(() {
            final pickedImage = controller.pickedImage.value;
            if (pickedImage != null) {
              return _buildLocalImagePreview(context, pickedImage);
            } else if (controller.imageUrl.value.isNotEmpty) {
              return _buildNetworkImagePreview(context, controller.imageUrl.value);
            } else {
              return _buildImagePlaceholder(context, controller, isMobile);
            }
          }),
          const SizedBox(height: AppSizes.spaceBtwItems),
          ElevatedButton.icon(
            onPressed: () => controller.pickImage(isMobile: isMobile),
            icon: const Icon(Iconsax.image),
            label: Text(isMobile ? 'Changer l\'image (Mobile)' : 'Changer l\'image (PC)'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalImagePreview(BuildContext context, XFile imageFile) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd),
      child: FutureBuilder<Uint8List?>(
        future: imageFile.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            );
          } else if (snapshot.hasError) {
            return Container(
              width: double.infinity,
              height: 200,
              color: Colors.grey[300],
              child: const Icon(Icons.error, size: 40),
            );
          } else {
            return Container(
              width: double.infinity,
              height: 200,
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildNetworkImagePreview(BuildContext context, String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => Container(
          width: double.infinity,
          height: 200,
          color: Colors.grey[300],
          child: const Icon(Icons.error, size: 40),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(
    BuildContext context,
    BannerController controller,
    bool isMobile,
  ) {
    final dark = THelperFunctions.isDarkMode(context);

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: dark ? AppColors.dark : Colors.grey[200],
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd),
        border: Border.all(
          color: dark ? Colors.grey[700]! : Colors.grey[300]!,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.image,
            size: 64,
            color: dark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: AppSizes.spaceBtwItems),
          Text(
            isMobile
                ? 'Taille recommandée: 1200x800px (Mobile)'
                : 'Taille recommandée: 1920x1080px (PC)',
            style: TextStyle(
              color: dark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkSelector(
    BuildContext context,
    BannerController controller,
  ) {
    return Obx(() {
      final linkType = controller.selectedLinkType.value;
      if (linkType.isEmpty) return const SizedBox.shrink();

      if (linkType == 'product') {
        final products = controller.products;
        if (products.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Aucun produit disponible', style: TextStyle(color: Colors.grey)),
          );
        }
        
        final selectedValue = controller.selectedLinkId.value;
        final isValidValue = selectedValue.isNotEmpty && 
            products.any((p) => p.id == selectedValue);
        
        return DropdownButtonFormField<String>(
          value: isValidValue ? selectedValue : null,
          decoration: const InputDecoration(
            labelText: 'Sélectionner un produit',
            prefixIcon: Icon(Iconsax.shop),
          ),
          items: products.map((product) {
            return DropdownMenuItem(
              value: product.id,
              child: Text(product.name),
            );
          }).toList(),
          onChanged: (value) {
            controller.selectedLinkId.value = value ?? '';
          },
        );
      } else if (linkType == 'category') {
        final categories = controller.categories;
        if (categories.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Aucune catégorie disponible', style: TextStyle(color: Colors.grey)),
          );
        }
        
        final selectedValue = controller.selectedLinkId.value;
        final isValidValue = selectedValue.isNotEmpty && 
            categories.any((c) => c.id == selectedValue);
        
        return DropdownButtonFormField<String>(
          value: isValidValue ? selectedValue : null,
          decoration: const InputDecoration(
            labelText: 'Sélectionner une catégorie',
            prefixIcon: Icon(Iconsax.category),
          ),
          items: categories.map((category) {
            return DropdownMenuItem(
              value: category.id,
              child: Text(category.name),
            );
          }).toList(),
          onChanged: (value) {
            controller.selectedLinkId.value = value ?? '';
          },
        );
      } else if (linkType == 'establishment') {
        final establishments = controller.establishments.where((e) => e.id != null).toList();
        if (establishments.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Aucun établissement disponible', style: TextStyle(color: Colors.grey)),
          );
        }
        
        final selectedValue = controller.selectedLinkId.value;
        final isValidValue = selectedValue.isNotEmpty && 
            establishments.any((e) => e.id == selectedValue);
        
        return DropdownButtonFormField<String>(
          value: isValidValue ? selectedValue : null,
          decoration: const InputDecoration(
            labelText: 'Sélectionner un établissement',
            prefixIcon: Icon(Iconsax.home),
          ),
          items: establishments.map((establishment) {
            return DropdownMenuItem(
              value: establishment.id!,
              child: Text(establishment.name),
            );
          }).toList(),
          onChanged: (value) {
            controller.selectedLinkId.value = value ?? '';
          },
        );
      }

      return const SizedBox.shrink();
    });
  }
}

