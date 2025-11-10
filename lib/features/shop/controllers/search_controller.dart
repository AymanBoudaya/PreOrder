import 'package:get/get.dart';
import '../../../data/repositories/product/produit_repository.dart';
import '../models/produit_model.dart';
import '../models/etablissement_model.dart';
import '../models/category_model.dart';

class ResearchController extends GetxController {
  final ProduitRepository _repo = Get.find<ProduitRepository>();

  /// States
  RxList<ProduitModel> searchResults = <ProduitModel>[].obs;
  RxList<ProduitModel> allProducts = <ProduitModel>[].obs;

  RxBool isLoading = false.obs;
  RxBool isPaginating = false.obs;
  RxBool hasMore = true.obs;
  RxString query = ''.obs;

  /// Filtres avec objets complets
  Rx<CategoryModel?> selectedCategory = Rx<CategoryModel?>(null);
  Rx<Etablissement?> selectedEtablissement = Rx<Etablissement?>(null);
  RxString selectedSort = ''.obs;

  // Listes complètes pour les filtres
  RxList<CategoryModel> categories = <CategoryModel>[].obs;
  RxList<Etablissement> etablissements = <Etablissement>[].obs;

  /// Pagination vars
  int _page = 1;
  final int _limit = 10;

  @override
  void onInit() {
    super.onInit();
    fetchAllProducts(reset: true);
    loadFilterData();
  }

  // Chargement des données de filtres
  Future<void> loadFilterData() async {
    try {
      // Récupérer les objets complets avec IDs
      final cats = await _repo.getAllCategoriesWithIds();
      final ets = await _repo.getAllEtablissementsWithIds();

      categories.assignAll(cats);
      etablissements.assignAll(ets);

      print(
          'Filtres chargés: ${cats.length} catégories, ${ets.length} établissements');
    } catch (e) {
      print('Erreur chargement filtres: $e');
    }
  }

  /// Fetch all products (with pagination) - Optimisé
  Future<void> fetchAllProducts({bool reset = false}) async {
    // Éviter les appels multiples simultanés
    if (isLoading.value || isPaginating.value) return;
    if (!hasMore.value && !reset) return;

    if (reset) {
      _page = 1;
      hasMore.value = true;
      allProducts.clear();
      searchResults.clear();
    }

    try {
      if (reset) {
        isLoading.value = true;
      } else {
        isPaginating.value = true;
      }

      final products =
          await _repo.getAllProductsPaginated(page: _page, limit: _limit);

      if (products.isEmpty) {
        hasMore.value = false;
      } else {
        // Ajouter les produits de manière optimisée
        allProducts.addAll(products);
        _page++;
        
        // Appliquer les filtres après avoir ajouté les nouveaux produits
        applyFilters();
      }
    } catch (e) {
      print('Erreur fetch produits: $e');
      // En cas d'erreur, s'assurer que les états sont corrects
      hasMore.value = false;
    } finally {
      isLoading.value = false;
      isPaginating.value = false;
    }
  }

  /// Filtrage combiné avec gestion des IDs - Optimisé pour performance
  void applyFilters() {
    // Utiliser une liste mutable pour de meilleures performances
    List<ProduitModel> results = List.from(allProducts);

    // Recherche textuelle - optimisée
    if (query.value.isNotEmpty) {
      final queryLower = query.value.toLowerCase();
      results = results.where((p) {
        // Recherche dans le nom (le plus rapide)
        if (p.name.toLowerCase().contains(queryLower)) return true;
        
        // Recherche dans la description
        if (p.description?.toLowerCase().contains(queryLower) ?? false) {
          return true;
        }
        
        // Recherche dans le nom de l'établissement
        if (p.etablissement?.name.toLowerCase().contains(queryLower) ?? false) {
          return true;
        }
        
        return false;
      }).toList();
    }

    // Filtre par catégorie (ID) - optimisé
    if (selectedCategory.value != null) {
      final categoryId = selectedCategory.value!.id;
      results = results.where((p) => p.categoryId == categoryId).toList();
    }

    // Filtre par établissement (ID) - optimisé
    if (selectedEtablissement.value != null) {
      final etabId = selectedEtablissement.value!.id;
      results = results.where((p) => p.etablissementId == etabId).toList();
    }

    // Tri - optimisé avec comparaison directe
    if (selectedSort.value.isNotEmpty) {
      switch (selectedSort.value) {
        case 'Prix ↑':
          results.sort(
              (a, b) => _getEffectivePrice(a).compareTo(_getEffectivePrice(b)));
          break;
        case 'Prix ↓':
          results.sort(
              (a, b) => _getEffectivePrice(b).compareTo(_getEffectivePrice(a)));
          break;
        case 'Nom A-Z':
          results.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'Popularité':
          results.sort((a, b) {
            final aScore = a.isFeatured == true ? 1 : 0;
            final bScore = b.isFeatured == true ? 1 : 0;
            return bScore.compareTo(aScore);
          });
          break;
      }
    }

    // Mise à jour optimisée des résultats
    searchResults.assignAll(results);
  }

  double _getEffectivePrice(ProduitModel product) {
    try {
      // PRODUIT SIMPLE
      if (product.productType == 'single') {
        // Si promo active
        if (product.salePrice > 0 && product.salePrice < product.price) {
          return product.salePrice;
        }
        return product.price;
      }

      // PRODUIT AVEC VARIANTES / TAILLES
      if (product.productType == 'variable' && product.sizesPrices.isNotEmpty) {
        final prices = product.sizesPrices.map((e) => e.price).toList();
        prices.sort();
        final minPrice = prices.first;
        final maxPrice = prices.last;

        // Si toutes les tailles ont le même prix → un seul affichage
        if (minPrice == maxPrice) {
          return minPrice;
        }

        // Sinon prix miniumum
        return minPrice;
      }

      return product.price;
    } catch (e) {
      return 0.00;
    }
  }

  /// Gestion des changements avec objets et debounce pour performance
  void onSearchChanged(String text) {
    query.value = text;
    // Debounce pour éviter trop de filtrages pendant la saisie
    // Le filtrage sera fait automatiquement via applyFilters
    applyFilters();
  }

  void onCategorySelected(CategoryModel? category) {
    selectedCategory.value = category;
    applyFilters();
  }

  void onEtablissementSelected(Etablissement? etablissement) {
    selectedEtablissement.value = etablissement;
    applyFilters();
  }

  void onSortSelected(String? sort) {
    selectedSort.value = sort ?? '';
    applyFilters();
  }

  // Méthodes pour retirer les filtres
  void clearSearch() {
    query.value = '';
    applyFilters();
  }

  void clearCategoryFilter() {
    selectedCategory.value = null;
    applyFilters();
  }

  void clearEtablissementFilter() {
    selectedEtablissement.value = null;
    applyFilters();
  }

  void clearSortFilter() {
    selectedSort.value = '';
    applyFilters();
  }

  void clearAllFilters() {
    query.value = '';
    selectedCategory.value = null;
    selectedEtablissement.value = null;
    selectedSort.value = '';
    applyFilters();
  }

  // Vérifier si des filtres sont actifs
  bool get hasActiveFilters {
    return query.value.isNotEmpty ||
        selectedCategory.value != null ||
        selectedEtablissement.value != null ||
        selectedSort.value.isNotEmpty;
  }

  // Getters pour l'affichage
  String get selectedCategoryName => selectedCategory.value?.name ?? '';
  String get selectedEtablissementName =>
      selectedEtablissement.value?.name ?? '';
}
