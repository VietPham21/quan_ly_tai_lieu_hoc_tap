-- ========================================================
-- KỊCH BẢN KHỞI TẠO CSDL VÀ CHÍNH SÁCH BẢO MẬT ROW LEVEL SECURITY (RLS)
-- DỰ ÁN: QUẢN LÝ TÀI LIỆU HỌC TẬP (CHECKLIST 3 & 5)
-- NỀN TẢNG: SUPABASE POSTGRESQL
-- ========================================================

-- 1. BẢNG NGƯỜI DÙNG (USERS / PROFILES)
-- Lưu trữ thông tin định danh sinh viên đồng bộ từ Firebase Authentication
CREATE TABLE IF NOT EXISTS public.users (
    id VARCHAR(128) PRIMARY KEY, -- Firebase UID
    email VARCHAR(255) NOT NULL UNIQUE,
    display_name VARCHAR(255),
    photo_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. BẢNG TÀI LIỆU HỌC TẬP (DOCUMENTS)
-- Quản lý thông tin tài liệu, liên kết URL file vật lý từ Firebase Storage
CREATE TABLE IF NOT EXISTS public.documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    subject VARCHAR(100) NOT NULL,
    category VARCHAR(100) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path TEXT,
    file_type VARCHAR(50) NOT NULL,
    file_size BIGINT DEFAULT 0,
    storage_path TEXT,          -- Đường dẫn lưu file trên Firebase Storage
    file_url TEXT,              -- Download URL từ Firebase Storage
    owner_id VARCHAR(128) NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    is_favorite BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. BẢNG QUYỀN CHIA SẺ (PERMISSIONS)
-- Quản lý phân quyền truy cập giữa các tài khoản (viewer, editor)
CREATE TABLE IF NOT EXISTS public.permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
    user_id VARCHAR(128) NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    shared_email VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('viewer', 'editor')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(document_id, user_id)
);

-- ========================================================
-- CHÍNH SÁCH BẢO MẬT ROW LEVEL SECURITY (RLS) (CHECKLIST 5)
-- ========================================================

-- Kích hoạt RLS trên cả 3 bảng
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.permissions ENABLE ROW LEVEL SECURITY;

-- Xóa các policy cũ nếu đã tồn tại để tránh xung đột
DROP POLICY IF EXISTS "Cho phép đọc danh sách users để tìm email chia sẻ" ON public.users;
DROP POLICY IF EXISTS "Cho phép chèn hoặc cập nhật thông tin user" ON public.users;
DROP POLICY IF EXISTS "Quyền xem bảng permissions" ON public.permissions;
DROP POLICY IF EXISTS "Quyền quản lý permissions" ON public.permissions;
DROP POLICY IF EXISTS "Quyền xem tài liệu documents" ON public.documents;
DROP POLICY IF EXISTS "Quyền thêm tài liệu mới" ON public.documents;
DROP POLICY IF EXISTS "Quyền cập nhật tài liệu" ON public.documents;
DROP POLICY IF EXISTS "Quyền xóa tài liệu" ON public.documents;

-- 1. POLICIES CHO BẢNG USERS
CREATE POLICY "Cho phép đọc danh sách users để tìm email chia sẻ"
ON public.users FOR SELECT
USING (true);

CREATE POLICY "Cho phép chèn hoặc cập nhật thông tin user"
ON public.users FOR ALL
USING (true)
WITH CHECK (true);

-- 2. POLICIES CHO BẢNG PERMISSIONS
CREATE POLICY "Quyền xem bảng permissions"
ON public.permissions FOR SELECT
USING (true);

CREATE POLICY "Quyền quản lý permissions"
ON public.permissions FOR ALL
USING (true)
WITH CHECK (true);

-- 3. POLICIES CHO BẢNG DOCUMENTS
CREATE POLICY "Quyền xem tài liệu documents"
ON public.documents FOR SELECT
USING (true);

CREATE POLICY "Quyền thêm tài liệu mới"
ON public.documents FOR INSERT
WITH CHECK (true);

CREATE POLICY "Quyền cập nhật tài liệu"
ON public.documents FOR UPDATE
USING (true)
WITH CHECK (true);

CREATE POLICY "Quyền xóa tài liệu"
ON public.documents FOR DELETE
USING (true);

-- ========================================================
-- BẬT REALTIME REPLICATION CHO CẢ 3 BẢNG
-- Giúp ứng dụng Flutter tự động cập nhật thời gian thực khi có thay đổi
-- ========================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'documents'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.documents;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'permissions'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.permissions;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'users'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.users;
    END IF;
END $$;
