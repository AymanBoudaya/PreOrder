-- Table pour les bannières
CREATE TABLE IF NOT EXISTS banners (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  image_url TEXT NOT NULL,
  is_featured BOOLEAN DEFAULT false,
  link UUID, -- ID du produit, catégorie ou établissement
  link_type VARCHAR(50), -- 'product', 'category', 'establishment'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_banners_is_featured ON banners(is_featured);
CREATE INDEX IF NOT EXISTS idx_banners_link_type ON banners(link_type);
CREATE INDEX IF NOT EXISTS idx_banners_created_at ON banners(created_at DESC);

-- Fonction pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION update_banners_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour mettre à jour updated_at
CREATE TRIGGER trigger_update_banners_updated_at
  BEFORE UPDATE ON banners
  FOR EACH ROW
  EXECUTE FUNCTION update_banners_updated_at();

-- Politique RLS (Row Level Security) - permettre la lecture à tous les utilisateurs authentifiés
ALTER TABLE banners ENABLE ROW LEVEL SECURITY;

-- Politique pour la lecture (tous les utilisateurs authentifiés peuvent lire)
CREATE POLICY "Public banners are viewable by authenticated users"
  ON banners FOR SELECT
  USING (auth.role() = 'authenticated');

-- Politique pour l'insertion (seulement les admins)
CREATE POLICY "Only admins can insert banners"
  ON banners FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid() AND users.role = 'Admin'
    )
  );

-- Politique pour la mise à jour (seulement les admins)
CREATE POLICY "Only admins can update banners"
  ON banners FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid() AND users.role = 'Admin'
    )
  );

-- Politique pour la suppression (seulement les admins)
CREATE POLICY "Only admins can delete banners"
  ON banners FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid() AND users.role = 'Admin'
    )
  );

-- Créer le bucket de stockage pour les bannières (à exécuter dans Supabase Storage)
-- Vous pouvez créer ce bucket manuellement dans l'interface Supabase Storage
-- Nom du bucket: 'banners'
-- Public: true

