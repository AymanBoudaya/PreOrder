# Instructions pour créer le bucket "banners" dans Supabase Storage

## ⚠️ IMPORTANT : Cette étape est REQUISE avant d'utiliser la gestion des bannières

Le bucket "banners" doit être créé dans Supabase Storage pour pouvoir uploader les images des bannières.

## Méthode 1 : Via l'interface Supabase (Recommandé - Plus Simple)

1. Connectez-vous à votre projet Supabase : https://app.supabase.com
2. Allez dans la section **Storage** dans le menu de gauche
3. Cliquez sur **Buckets** dans le sous-menu
4. Cliquez sur le bouton **New bucket** (en haut à droite)
5. Configurez le bucket :
   - **Name**: `banners` (doit être exactement "banners")
   - **Public bucket**: ✅ **IMPORTANT** - Cocher cette option (pour permettre l'accès public aux images)
   - **File size limit**: Laissez par défaut ou définissez une limite (ex: 5MB = 5242880 bytes)
   - **Allowed MIME types**: Optionnel, vous pouvez laisser vide ou spécifier `image/jpeg, image/png, image/webp, image/jpg`
6. Cliquez sur **Create bucket**
7. ✅ Vérifiez que le bucket apparaît dans la liste avec l'icône "Public" visible

## Méthode 2 : Via SQL (Alternative - Nécessite des permissions admin)

⚠️ **Note** : Cette méthode nécessite des permissions administrateur dans Supabase. Si vous n'avez pas ces permissions, utilisez la Méthode 1.

Exécutez le SQL suivant dans l'éditeur SQL de Supabase :

```sql
-- Créer le bucket "banners"
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'banners', 
  'banners', 
  true,  -- Public
  5242880,  -- 5MB en bytes
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
)
ON CONFLICT (id) DO NOTHING;

-- Politiques RLS pour le bucket "banners"

-- Politique pour la lecture publique (tous les utilisateurs peuvent lire)
CREATE POLICY "Public can view banners"
ON storage.objects FOR SELECT
USING (bucket_id = 'banners');

-- Politique pour l'insertion (seulement les admins)
CREATE POLICY "Only admins can upload banners"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'banners' AND
  auth.role() = 'authenticated' AND
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid() AND users.role = 'Admin'
  )
);

-- Politique pour la mise à jour (seulement les admins)
CREATE POLICY "Only admins can update banners"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'banners' AND
  auth.role() = 'authenticated' AND
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid() AND users.role = 'Admin'
  )
);

-- Politique pour la suppression (seulement les admins)
CREATE POLICY "Only admins can delete banners"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'banners' AND
  auth.role() = 'authenticated' AND
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid() AND users.role = 'Admin'
  )
);
```

**⚠️ Important** : Si vous obtenez une erreur de permissions, utilisez la Méthode 1 (interface Supabase) qui est plus simple et ne nécessite pas de permissions spéciales.

## Vérification

Après avoir créé le bucket, vous pouvez vérifier qu'il existe en :
1. Allant dans Storage > Buckets dans l'interface Supabase
2. Vérifiant que le bucket "banners" apparaît dans la liste
3. Vérifiant que l'option "Public" est activée (icône de globe visible)

## Configuration des Politiques RLS (Row Level Security)

Si vous avez créé le bucket via l'interface (Méthode 1), vous devrez peut-être configurer les politiques RLS manuellement :

1. Allez dans Storage > Policies
2. Sélectionnez le bucket "banners"
3. Créez les politiques suivantes (ou exécutez le SQL de la Méthode 2 pour les créer automatiquement)

## Important

- ✅ Le bucket doit être **public** pour que les images soient accessibles depuis l'application
- ✅ Assurez-vous que les politiques RLS (Row Level Security) sont correctement configurées
- ✅ Les images seront stockées avec des noms uniques basés sur le timestamp pour éviter les collisions
- ✅ Seuls les utilisateurs avec le rôle "Admin" peuvent uploader/modifier/supprimer des bannières

## Résolution des problèmes

### Erreur : "bucket not found"
- Vérifiez que le bucket "banners" existe dans Storage > Buckets
- Vérifiez que le nom du bucket est exactement "banners" (minuscules)

### Erreur : "Permission denied"
- Vérifiez que les politiques RLS sont correctement configurées
- Vérifiez que votre utilisateur a le rôle "Admin" dans la table `users`

### Les images ne s'affichent pas
- Vérifiez que le bucket est **public**
- Vérifiez que les URLs des images sont correctes
- Vérifiez que les politiques RLS permettent la lecture publique
