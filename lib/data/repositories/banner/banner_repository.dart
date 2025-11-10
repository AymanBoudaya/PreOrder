import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../features/shop/models/banner_model.dart';

class BannerRepository extends GetxController {
  static BannerRepository get instance => Get.find();

  /// Variables
  final _db = Supabase.instance.client;
  final _table = 'banners';
  final _bucket = 'banners';

  /// Charger toutes les bannières
  Future<List<BannerModel>> getAllBanners() async {
    try {
      final response = await _db
          .from(_table)
          .select()
          .order('created_at', ascending: false);
      return response
          .map((banner) => BannerModel.fromJson(banner))
          .toList();
    } on PostgrestException catch (e) {
      throw 'Erreur Supabase: ${e.message}';
    } catch (e) {
      throw 'Échec de récupération des bannières : $e';
    }
  }

  /// Charger les bannières mises en avant
  Future<List<BannerModel>> getFeaturedBanners() async {
    try {
      final response = await _db
          .from(_table)
          .select()
          .eq('is_featured', true)
          .order('created_at', ascending: false);
      return response
          .map((banner) => BannerModel.fromJson(banner))
          .toList();
    } on PostgrestException catch (e) {
      throw 'Erreur Supabase: ${e.message}';
    } catch (e) {
      throw 'Échec de récupération des bannières mises en avant : $e';
    }
  }

  /// Ajouter une bannière
  Future<BannerModel> addBanner(BannerModel banner) async {
    try {
      final bannerData = banner.toJson();
      bannerData.remove('id'); // Supprimer l'id pour laisser Supabase le générer
      bannerData['created_at'] = DateTime.now().toIso8601String();
      bannerData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _db
          .from(_table)
          .insert(bannerData)
          .select()
          .single();

      return BannerModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw 'Erreur base de données : ${e.code} - ${e.message}';
    } catch (e) {
      throw 'Erreur lors de l\'ajout de la bannière : $e';
    }
  }

  /// Modifier une bannière
  Future<void> updateBanner(BannerModel banner) async {
    try {
      final bannerData = banner.toJson();
      bannerData.remove('id');
      bannerData['updated_at'] = DateTime.now().toIso8601String();

      await _db.from(_table).update(bannerData).eq('id', banner.id);
    } on PostgrestException catch (e) {
      throw 'Erreur base de données : ${e.code} - ${e.message}';
    } catch (e) {
      throw 'Erreur lors de la mise à jour de la bannière : $e';
    }
  }

  /// Supprimer une bannière
  Future<void> deleteBanner(String bannerId) async {
    try {
      await _db.from(_table).delete().eq('id', bannerId);
    } on PostgrestException catch (e) {
      throw 'Erreur base de données : ${e.code} - ${e.message}';
    } catch (e) {
      throw 'Erreur lors de la suppression de la bannière : $e';
    }
  }

  /// Upload d'image compatible Web & Mobile
  /// [file] peut être XFile (mobile) ou Uint8List (web)
  Future<String> uploadBannerImage(dynamic file, {bool isMobile = false}) async {
    try {
      final fileName = 'banner_${DateTime.now().millisecondsSinceEpoch}.${isMobile ? 'jpg' : 'png'}';

      if (kIsWeb) {
        // Web → XFile ou Uint8List
        Uint8List bytes;
        if (file is XFile) {
          bytes = await file.readAsBytes();
        } else if (file is Uint8List) {
          bytes = file;
        } else {
          throw 'Type de fichier non supporté pour l\'upload web';
        }
        await _db.storage.from(_bucket).uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/png'),
        );
      } else {
        // Mobile → File ou XFile
        if (file is XFile) {
          final fileBytes = await file.readAsBytes();
          await _db.storage.from(_bucket).uploadBinary(
            fileName,
            fileBytes,
            fileOptions: FileOptions(contentType: 'image/jpeg'),
          );
        } else if (file is File) {
          await _db.storage.from(_bucket).upload(
            fileName,
            file,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
        } else {
          throw 'Type de fichier non supporté pour l\'upload mobile';
        }
      }

      // Récupérer l'URL publique
      final publicUrl = _db.storage.from(_bucket).getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      throw 'Erreur lors de l\'upload de l\'image : $e';
    }
  }

  /// Supprimer une image du storage
  Future<void> deleteBannerImage(String imageUrl) async {
    try {
      // Extraire le nom du fichier de l'URL
      final fileName = imageUrl.split('/').last.split('?').first;
      await _db.storage.from(_bucket).remove([fileName]);
    } catch (e) {
      debugPrint('Erreur lors de la suppression de l\'image : $e');
      // Ne pas faire échouer la suppression de la bannière si l'image ne peut pas être supprimée
    }
  }
}

