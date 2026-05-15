-- HTP-DB: Human Text Production Database
-- Wave 1 MVP Schema (1450-2026)
-- 設計原則: htp_unified_volume を最初に置く（個別最適化散逸防止）

-- ============================================================
-- TABLE 1: htp_unified_volume — 統合ハブ
-- 時代×媒体×言語圏×単位 の推定値を範囲表現で保持
-- ============================================================
CREATE TABLE htp_unified_volume (
    volume_id INTEGER PRIMARY KEY AUTOINCREMENT,
    period_id TEXT NOT NULL,              -- 例: '1450-1500', '2020-2025'
    year_start INTEGER NOT NULL,
    year_end INTEGER NOT NULL,
    medium_id INTEGER NOT NULL,
    region_id INTEGER NOT NULL,
    unit TEXT NOT NULL,                   -- 'characters', 'words', 'titles', 'books', 'bytes'
    volume_estimate_low REAL,             -- 推定下限
    volume_estimate_central REAL,         -- 中央値
    volume_estimate_high REAL,            -- 推定上限
    volume_unit_scale TEXT,               -- '1e6', '1e9', '1e12', '1e21' (ZB)
    gta_status TEXT NOT NULL DEFAULT 'estimated'
        CHECK (gta_status IN ('verified', 'estimated', 'extrapolated', 'placeholder')),
    estimation_method TEXT,               -- 'archaeological_count', 'production_model', 'industry_statistics', 'extrapolation'
    primary_source_id INTEGER NOT NULL,
    secondary_source_ids TEXT,            -- JSON array
    confidence_band TEXT,                 -- 'tight', 'medium', 'wide', 'very_wide'
    data_quality TEXT,                    -- 'A', 'B', 'C', 'D'
    verification_status TEXT DEFAULT 'unverified'
        CHECK (verification_status IN ('verified', 'partial', 'unverified', 'disputed')),
    source_reliability INTEGER CHECK (source_reliability BETWEEN 1 AND 5),
    note TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (medium_id) REFERENCES htp_media_types(medium_id),
    FOREIGN KEY (region_id) REFERENCES htp_language_regions(region_id),
    FOREIGN KEY (primary_source_id) REFERENCES htp_sources(source_id)
);
CREATE INDEX idx_uv_period ON htp_unified_volume(year_start, year_end);
CREATE INDEX idx_uv_medium ON htp_unified_volume(medium_id);
CREATE INDEX idx_uv_region ON htp_unified_volume(region_id);
CREATE INDEX idx_uv_gta ON htp_unified_volume(gta_status);

-- ============================================================
-- TABLE 2: htp_sources — path-1 真実層
-- authority_tier で層別固定
-- ============================================================
CREATE TABLE htp_sources (
    source_id INTEGER PRIMARY KEY AUTOINCREMENT,
    source_short TEXT NOT NULL UNIQUE,    -- 例: 'buringh_vanzanden_2009'
    source_full_citation TEXT NOT NULL,
    source_type TEXT NOT NULL
        CHECK (source_type IN ('primary', 'secondary', 'synthesis', 'industry_report')),
    authority_tier INTEGER NOT NULL
        CHECK (authority_tier IN (1, 2, 3)),  -- 1=正本, 2=補助, 3=推計
    coverage_period TEXT,                 -- 例: '1450-1800'
    coverage_region TEXT,                 -- 例: 'Europe 9 regions'
    url TEXT,
    url_verified_at TEXT,                 -- ISO 8601
    url_live INTEGER DEFAULT 0,           -- 0/1 boolean
    license TEXT,                         -- 'CC BY 4.0', 'CC BY-SA', 'Academic copyright', 'Public Domain'
    free_access INTEGER DEFAULT 0,        -- 0/1
    methodology_note TEXT,
    citation_count_proxy INTEGER,         -- 学界引用数（信頼度プロキシ）
    note TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_src_short ON htp_sources(source_short);
CREATE INDEX idx_src_tier ON htp_sources(authority_tier);

-- ============================================================
-- TABLE 3: htp_source_discrepancies — 不一致明示テーブル
-- 書き換えではなく繋ぐ（path-1 暗黙知5: 訂正版を重ねる誠実性）
-- ============================================================
CREATE TABLE htp_source_discrepancies (
    discrepancy_id INTEGER PRIMARY KEY AUTOINCREMENT,
    period_id TEXT NOT NULL,
    medium_id INTEGER,
    region_id INTEGER,
    source_a_id INTEGER NOT NULL,
    source_a_value REAL,
    source_a_unit TEXT,
    source_b_id INTEGER NOT NULL,
    source_b_value REAL,
    source_b_unit TEXT,
    gap_ratio REAL,                       -- source_b / source_a
    gap_explanation TEXT,
    resolution_rule TEXT,                 -- 'adopt_a', 'adopt_b', 'range_both', 'abstain', 'no_consensus'
    note TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (source_a_id) REFERENCES htp_sources(source_id),
    FOREIGN KEY (source_b_id) REFERENCES htp_sources(source_id),
    FOREIGN KEY (medium_id) REFERENCES htp_media_types(medium_id),
    FOREIGN KEY (region_id) REFERENCES htp_language_regions(region_id)
);

-- ============================================================
-- TABLE 4: htp_media_types — 媒体定義の固定
-- v2失敗継承: 媒体定義揺れの再発防止
-- ============================================================
CREATE TABLE htp_media_types (
    medium_id INTEGER PRIMARY KEY AUTOINCREMENT,
    medium_short TEXT NOT NULL UNIQUE,    -- 'cuneiform_tablet', 'papyrus', 'parchment_codex', 'paper_manuscript', 'print_book', 'newspaper', 'digital_web', 'digital_social', 'digital_data'
    medium_name_ja TEXT NOT NULL,
    medium_name_en TEXT NOT NULL,
    medium_definition TEXT NOT NULL,      -- 時代別定義を固定
    era_start_year INTEGER,
    era_peak_year INTEGER,
    era_end_year INTEGER,                 -- NULL = 現役
    parent_medium_id INTEGER,
    physical_unit TEXT,                   -- 'pages', 'characters', 'bytes', 'tokens'
    wave_introduced INTEGER DEFAULT 1,
    note TEXT,
    FOREIGN KEY (parent_medium_id) REFERENCES htp_media_types(medium_id)
);

-- ============================================================
-- TABLE 5: htp_language_regions — 言語圏バランス管理
-- v2失敗継承: 言語圏不均衡の再発防止
-- ============================================================
CREATE TABLE htp_language_regions (
    region_id INTEGER PRIMARY KEY AUTOINCREMENT,
    region_short TEXT NOT NULL UNIQUE,    -- 'europe_latin', 'sinosphere', 'arabic', 'south_asia', 'mesoamerica', 'global'
    region_name_ja TEXT NOT NULL,
    region_name_en TEXT NOT NULL,
    primary_languages TEXT,               -- JSON array of ISO 639-3
    un_region TEXT,                       -- UN M49 region
    coverage_flag INTEGER DEFAULT 0       -- 0=未カバー, 1=部分, 2=充足
        CHECK (coverage_flag IN (0, 1, 2)),
    literacy_rate_source_id INTEGER,
    bias_warning TEXT,                    -- 欧米偏重WARN等
    note TEXT,
    FOREIGN KEY (literacy_rate_source_id) REFERENCES htp_sources(source_id)
);

-- ============================================================
-- TABLE 6: htp_cross_db_refs — 既存64DBへの統一参照
-- cross_refs ≥ 10件ゲート対応
-- ============================================================
CREATE TABLE htp_cross_db_refs (
    ref_id INTEGER PRIMARY KEY AUTOINCREMENT,
    source_db TEXT NOT NULL,              -- 'TA', 'CDH', 'CI', 'SI', 'MG', 'PESTLE', 'UPR', 'TK', 'GC-DB', 'FTT-DB-v2'
    target_record_id TEXT,                -- 該当DBのレコードID（可能なら）
    connection_key TEXT NOT NULL,         -- 'year', 'medium_type', 'language_region', 'concept'
    relationship_type TEXT NOT NULL
        CHECK (relationship_type IN ('supports', 'contradicts', 'extends', 'mirrors', 'complements')),
    htp_volume_id INTEGER,                -- 関連する htp_unified_volume レコード
    note TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (htp_volume_id) REFERENCES htp_unified_volume(volume_id)
);

-- ============================================================
-- TABLE 7: htp_quality_metadata — KV形式品質メタデータ
-- 全Phase共通インフラ
-- ============================================================
CREATE TABLE htp_quality_metadata (
    meta_id INTEGER PRIMARY KEY AUTOINCREMENT,
    key TEXT NOT NULL,                    -- 'verified_rate', 'source_url_live_rate', 'cross_refs_count', 'estimation_traceability', 'abstain_count'
    value TEXT NOT NULL,
    wave_n INTEGER DEFAULT 1,
    computed_at TEXT DEFAULT CURRENT_TIMESTAMP,
    note TEXT
);
CREATE INDEX idx_qm_key ON htp_quality_metadata(key);
CREATE INDEX idx_qm_wave ON htp_quality_metadata(wave_n);
