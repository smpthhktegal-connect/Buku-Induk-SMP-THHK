-- ========================================================
-- SCRIPT PEMBUATAN TABEL RIWAYAT KELAS
-- Jalankan script ini di SQL Editor Supabase Anda
-- ========================================================

-- 1. Buat Tabel Riwayat Kelas
CREATE TABLE IF NOT EXISTS riwayat_kelas (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    siswa_id UUID REFERENCES buku_induk(id) ON DELETE CASCADE,
    tahun_ajaran VARCHAR(50) NOT NULL,
    kelas VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Matikan Row Level Security (RLS) sementara agar mudah diakses dari frontend (seperti tabel lainnya)
ALTER TABLE riwayat_kelas DISABLE ROW LEVEL SECURITY;

-- 3. (Opsional) Buat Index untuk mempercepat pencarian berdasarkan tahun atau siswa
CREATE INDEX IF NOT EXISTS idx_riwayat_siswa ON riwayat_kelas(siswa_id);
CREATE INDEX IF NOT EXISTS idx_riwayat_tahun ON riwayat_kelas(tahun_ajaran);
