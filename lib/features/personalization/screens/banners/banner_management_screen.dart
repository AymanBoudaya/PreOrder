import 'package:caferesto/utils/constants/sizes.dart';
import 'package:caferesto/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:caferesto/features/shop/models/banner_model.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/colors.dart';
import '../../../shop/controllers/banner_controller.dart';
import '../widgets/loading_screen.dart';
import 'add_banner_screen.dart';
import 'edit_banner_screen.dart';

class BannerManagementScreen extends StatelessWidget {
  const BannerManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(BannerController());

    return Scaffold(
      appBar: TAppBar(
        title: const Text("Gestion des bannières"),
      ),
      body: Column(
        children: [
          _buildSearchBar(context),
          Expanded(child: _buildBody(context)),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildBody(BuildContext context) {
    final controller = Get.find<BannerController>();

    return Obx(() {
      if (controller.isLoading.value) {
        return LoadingScreen(
          screenName: 'Bannières',
        );
      }
      if (controller.allBanners.isEmpty) {
        return _buildEmptyState();
      }

      return _buildBannerList(context);
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.image, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Aucune bannière trouvée",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Commencez par ajouter votre première bannière",
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Get.to(() => const AddBannerScreen()),
            icon: const Icon(Iconsax.add),
            label: const Text("Ajouter une bannière"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerList(BuildContext context) {
    final controller = Get.find<BannerController>();
    final banners = controller.getFilteredBanners();

    if (banners.isEmpty) {
      return Center(
        child: Text(
          controller.searchQuery.value.isNotEmpty
              ? "Aucun résultat pour votre recherche"
              : "Aucune bannière",
          style: TextStyle(color: Colors.grey[600], fontSize: 15),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.refreshBanners,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.defaultSpace),
        itemCount: banners.length,
        itemBuilder: (_, i) => _buildBannerCard(banners[i], context),
      ),
    );
  }

  Widget _buildBannerCard(BannerModel banner, BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: dark ? AppColors.eerieBlack : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildBannerImage(banner),
        title: Text(
          banner.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: _buildBannerSubtitle(banner),
        trailing: _buildFeaturedBadge(banner),
        onTap: () => _showBannerOptions(context, banner),
      ),
    );
  }

  Widget _buildBannerImage(BannerModel banner) {
    return Container(
      width: 80,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[100],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          banner.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Icon(Iconsax.image, color: Colors.grey[400], size: 24),
          loadingBuilder: (context, child, loading) {
            if (loading == null) return child;
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          },
        ),
      ),
    );
  }

  Widget _buildBannerSubtitle(BannerModel banner) {
    String subtitle = '';
    if (banner.linkType != null && banner.linkType!.isNotEmpty) {
      switch (banner.linkType) {
        case 'product':
          subtitle = 'Produit';
          break;
        case 'category':
          subtitle = 'Catégorie';
          break;
        case 'establishment':
          subtitle = 'Établissement';
          break;
        default:
          subtitle = 'Aucun lien';
      }
    } else {
      subtitle = 'Aucun lien';
    }

    return Text(
      subtitle,
      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
    );
  }

  Widget _buildFeaturedBadge(BannerModel banner) {
    if (!(banner.isFeatured ?? false)) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: Colors.amber.shade600, size: 14),
          const SizedBox(width: 4),
          Text(
            "Vedette",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.amber.shade700,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() => FloatingActionButton(
        onPressed: () => Get.to(() => const AddBannerScreen()),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Iconsax.additem, size: 28),
      );

  void _showBannerOptions(BuildContext context, BannerModel banner) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildBottomSheetContent(context, banner),
    );
  }

  Widget _buildBottomSheetContent(BuildContext context, BannerModel banner) {
    final dark = THelperFunctions.isDarkMode(context);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppColors.eerieBlack : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBottomSheetHeader(banner),
          const SizedBox(height: 16),
          _buildActionButtons(context, banner),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text("Annuler"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheetHeader(BannerModel banner) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildBannerImage(banner),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  banner.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                _buildBannerSubtitle(banner),
                if (banner.isFeatured ?? false) ...[
                  const SizedBox(height: 8),
                  _buildFeaturedBadge(banner),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, BannerModel banner) {
    final controller = Get.find<BannerController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                controller.loadBannerForEditing(banner);
                Get.to(() => EditBannerScreen(banner: banner));
              },
              icon: const Icon(Iconsax.edit, size: 20),
              label: const Text("Éditer"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade50,
                foregroundColor: Colors.blue.shade700,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showDeleteDialog(context, banner),
              icon: const Icon(Iconsax.trash, size: 20),
              label: const Text("Supprimer"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, BannerModel banner) {
    final controller = Get.find<BannerController>();
    Navigator.pop(context);
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber),
            SizedBox(width: 12),
            Text("Confirmer la suppression"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Supprimer la bannière \"${banner.name}\" ?"),
            const SizedBox(height: 8),
            Text(
              "Cette action est irréversible.",
              style: TextStyle(
                color: Colors.red.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              "Annuler",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back(); // Fermer le dialog de confirmation
              await controller.deleteBanner(banner.id);
              // Le snackbar de succès sera affiché par le contrôleur
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text("Supprimer"),
          )
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final controller = Get.find<BannerController>();
    final dark = THelperFunctions.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.defaultSpace),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: controller.updateSearch,
              decoration: InputDecoration(
                hintText: "Rechercher une bannière...",
                prefixIcon: const Icon(Iconsax.search_normal_1, size: 20),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: dark ? AppColors.eerieBlack : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

