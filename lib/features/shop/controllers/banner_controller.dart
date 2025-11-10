import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/repositories/banner/banner_repository.dart';
import '../../../utils/popups/loaders.dart';
import '../models/banner_model.dart';
import '../models/category_model.dart';
import '../models/etablissement_model.dart';
import '../models/produit_model.dart';

class BannerController extends GetxController {
  static BannerController get instance => Get.find();

  // Repository
  final _bannerRepository = BannerRepository.instance;

  // Observable variables
  final RxList<BannerModel> allBanners = <BannerModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  // Form variables
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final Rx<XFile?> pickedImage = Rx<XFile?>(null);
  final RxString imageUrl = ''.obs;
  final RxBool isFeatured = false.obs;
  final RxString selectedLinkType = ''.obs; // 'product', 'category', 'establishment'
  final RxString selectedLinkId = ''.obs;

  // Dropdown options
  final RxList<ProduitModel> products = <ProduitModel>[].obs;
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxList<Etablissement> establishments = <Etablissement>[].obs;

  // Selected banner for editing
  final Rx<BannerModel?> selectedBanner = Rx<BannerModel?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchAllBanners();
  }

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }

  /// Fetch all banners
  Future<void> fetchAllBanners() async {
    try {
      isLoading.value = true;
      final banners = await _bannerRepository.getAllBanners();
      allBanners.assignAll(banners);
    } catch (e) {
      TLoaders.errorSnackBar(message: 'Erreur lors du chargement des bannières: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch featured banners (for home screen)
  Future<List<BannerModel>> getFeaturedBanners() async {
    try {
      return await _bannerRepository.getFeaturedBanners();
    } catch (e) {
      debugPrint('Erreur lors du chargement des bannières mises en avant: $e');
      return [];
    }
  }

  /// Pick image from gallery or camera
  Future<void> pickImage({bool isMobile = false}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: isMobile ? 85 : 90,
        maxWidth: isMobile ? 1200 : 1920,
        maxHeight: isMobile ? 800 : 1080,
      );

      if (image != null) {
        pickedImage.value = image;
        imageUrl.value = ''; // Reset URL when new image is picked
      }
    } catch (e) {
      TLoaders.errorSnackBar(message: 'Erreur lors de la sélection de l\'image: $e');
    }
  }

  /// Add banner
  Future<void> addBanner() async {
    try {
      // Validation
      if (!formKey.currentState!.validate()) {
        return;
      }

      if (pickedImage.value == null && imageUrl.value.isEmpty) {
        TLoaders.warningSnackBar(
          title: 'Image manquante',
          message: 'Veuillez sélectionner une image pour la bannière',
        );
        return;
      }

      isLoading.value = true;

      // Upload image if a new one was picked
      String finalImageUrl = imageUrl.value;
      if (pickedImage.value != null) {
        final screenWidth = Get.width;
        final isMobileSize = screenWidth < 768;
        finalImageUrl = await _bannerRepository.uploadBannerImage(
          pickedImage.value!,
          isMobile: isMobileSize,
        );
      }

      // Create banner
      final banner = BannerModel(
        id: '',
        name: nameController.text.trim(),
        imageUrl: finalImageUrl,
        isFeatured: isFeatured.value,
        link: selectedLinkId.value.isNotEmpty ? selectedLinkId.value : null,
        linkType: selectedLinkType.value.isNotEmpty ? selectedLinkType.value : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _bannerRepository.addBanner(banner);
      await fetchAllBanners();
      
      clearForm();
      Get.back(); // Fermer l'écran
      TLoaders.successSnackBar(
        title: 'Succès',
        message: 'Bannière ajoutée avec succès',
      );
    } catch (e) {
      TLoaders.errorSnackBar(message: 'Erreur lors de l\'ajout de la bannière: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Update banner
  Future<void> updateBanner(String bannerId) async {
    try {
      // Validation
      if (!formKey.currentState!.validate()) {
        return;
      }

      isLoading.value = true;

      // Upload new image if one was picked
      String finalImageUrl = imageUrl.value;
      if (pickedImage.value != null) {
        final screenWidth = Get.width;
        final isMobileSize = screenWidth < 768;
        finalImageUrl = await _bannerRepository.uploadBannerImage(
          pickedImage.value!,
          isMobile: isMobileSize,
        );
      }

      // Update banner
      final banner = BannerModel(
        id: bannerId,
        name: nameController.text.trim(),
        imageUrl: finalImageUrl,
        isFeatured: isFeatured.value,
        link: selectedLinkId.value.isNotEmpty ? selectedLinkId.value : null,
        linkType: selectedLinkType.value.isNotEmpty ? selectedLinkType.value : null,
        updatedAt: DateTime.now(),
      );

      await _bannerRepository.updateBanner(banner);
      await fetchAllBanners();
      
      clearForm();
      Get.back(); // Fermer l'écran
      TLoaders.successSnackBar(
        title: 'Succès',
        message: 'Bannière mise à jour avec succès',
      );
    } catch (e) {
      TLoaders.errorSnackBar(message: 'Erreur lors de la mise à jour de la bannière: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete banner
  Future<void> deleteBanner(String bannerId) async {
    try {
      // Get banner to delete image
      final banner = allBanners.firstWhere((b) => b.id == bannerId);
      
      isLoading.value = true;
      
      // Delete image from storage
      if (banner.imageUrl.isNotEmpty) {
        await _bannerRepository.deleteBannerImage(banner.imageUrl);
      }
      
      // Delete banner
      await _bannerRepository.deleteBanner(bannerId);
      await fetchAllBanners();
      
      // Afficher le snackbar de succès
      TLoaders.successSnackBar(
        title: 'Succès',
        message: 'Bannière supprimée avec succès',
      );
    } catch (e) {
      TLoaders.errorSnackBar(message: 'Erreur lors de la suppression de la bannière: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load banner for editing
  void loadBannerForEditing(BannerModel banner) {
    selectedBanner.value = banner;
    nameController.text = banner.name;
    imageUrl.value = banner.imageUrl;
    pickedImage.value = null;
    isFeatured.value = banner.isFeatured ?? false;
    selectedLinkType.value = banner.linkType ?? '';
    selectedLinkId.value = banner.link ?? '';
  }

  /// Clear form
  void clearForm() {
    nameController.clear();
    pickedImage.value = null;
    imageUrl.value = '';
    isFeatured.value = false;
    selectedLinkType.value = '';
    selectedLinkId.value = '';
    selectedBanner.value = null;
  }

  /// Update search query
  void updateSearch(String query) {
    searchQuery.value = query;
  }

  /// Get filtered banners
  List<BannerModel> getFilteredBanners() {
    if (searchQuery.value.isEmpty) {
      return allBanners.toList();
    }
    return allBanners
        .where((banner) =>
            banner.name.toLowerCase().contains(searchQuery.value.toLowerCase()))
        .toList();
  }

  /// Refresh banners
  Future<void> refreshBanners() async {
    await fetchAllBanners();
  }
}

