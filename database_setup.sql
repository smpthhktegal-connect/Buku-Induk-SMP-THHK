-- ==============================================================================
-- SETUP TABEL DATABASE: BUKU INDUK SMP THHK
-- ==============================================================================

-- 1. Tabel Induk Siswa (Master Data)
CREATE TABLE IF NOT EXISTS public.buku_induk (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- Data Utama
    nis VARCHAR(20) UNIQUE NOT NULL,
    nisn VARCHAR(20) UNIQUE,
    nama_lengkap VARCHAR(150) NOT NULL,
    jenis_kelamin VARCHAR(10) CHECK (jenis_kelamin IN ('Laki-laki', 'Perempuan')),
    tempat_lahir VARCHAR(100),
    tanggal_lahir DATE,
    agama VARCHAR(50),
    kewarganegaraan VARCHAR(50) DEFAULT 'WNI',
    anak_ke INTEGER,
    jumlah_saudara INTEGER,
    foto_url TEXT, -- Menyimpan link gambar foto siswa
    
    -- Status & Kelas
    status_siswa VARCHAR(20) DEFAULT 'Aktif' CHECK (status_siswa IN ('Aktif', 'Lulus', 'Pindah', 'Keluar')),
    kelas_sekarang VARCHAR(10),
    tahun_masuk VARCHAR(10),
    
    -- Kontak & Alamat
    alamat_lengkap TEXT,
    no_telp_siswa VARCHAR(20),
    asal_sekolah VARCHAR(150),
    
    -- Data Orang Tua / Wali
    nama_ayah VARCHAR(150),
    pekerjaan_ayah VARCHAR(100),
    nama_ibu VARCHAR(150),
    pekerjaan_ibu VARCHAR(100),
    no_telp_ortu VARCHAR(20),
    nama_wali VARCHAR(150),
    pekerjaan_wali VARCHAR(100),
    
    -- Sistem Log
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Fungsi untuk Update Timestamp otomatis
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_buku_induk_modtime
BEFORE UPDATE ON public.buku_induk
FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

-- 3. Tabel Users (Guru & Admin) untuk Akses Login
CREATE TABLE IF NOT EXISTS public.users_staff (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL, -- Dalam praktek nyata gunakan bcrypt, untuk simple gunakan plain/md5
    nama_lengkap VARCHAR(100) NOT NULL,
    role VARCHAR(20) DEFAULT 'Guru' CHECK (role IN ('Admin', 'Guru')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. RPC Login Sederhana
CREATE OR REPLACE FUNCTION public.login_staff(
    p_username VARCHAR,
    p_password VARCHAR
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user RECORD;
BEGIN
    SELECT * INTO v_user
    FROM public.users_staff
    WHERE username = p_username AND password_hash = p_password;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Username atau Password salah';
    END IF;
    
    RETURN jsonb_build_object(
        'id', v_user.id,
        'nama', v_user.nama_lengkap,
        'role', v_user.role
    );
END;
$$;

-- ==============================================================================
-- 5. STORAGE BUCKET (Untuk Foto Siswa)
-- PENTING: Anda bisa jalankan kode di bawah ini, atau buat bucket secara manual 
-- melalui Dashboard Supabase -> Storage -> New Bucket bernama "foto_siswa" (Public)
-- ==============================================================================
INSERT INTO storage.buckets (id, name, public) 
VALUES ('foto_siswa', 'foto_siswa', true) 
ON CONFLICT (id) DO NOTHING;

-- Izinkan semua orang melihat foto (Public Read)
CREATE POLICY "Public Read Access" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'foto_siswa');

-- Izinkan insert/upload dokumen ke bucket (Anon/Public untuk bypass sementara)
CREATE POLICY "Public Insert Access" 
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'foto_siswa');
