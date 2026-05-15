# HTP-DB — Human Text Production Database

人類が時代ごとに生成した文字・テキストの量推定データベース。

## 概要

- **期間**: BC3200 〜 AD2026 / 5,226年
- **レコード**: 44 (unified_volume)
- **ソース**: 18 (Buringh & van Zanden 2009 / Buringh 2011 / IDC / UNESCO / Hilbert-Lopez 2011 / CDLI / Perseus / TLG / Oxyrhynchus / Sinica / Shamela / SARIT / Maya / Ge'ez / AI 他)
- **媒体**: 12 (楔形文字粘土板 → AI 生成テキスト)
- **言語圏**: 9 圏 (8 充足 + 1 部分)
- **Cross-refs**: 15 件 (TA / CDH / CI / SI / MG / PESTLE / UPR / TK / GC-DB / FTT-DB v2 / CLA / SI-Framework / Megatrend / FVCP / Manufacturing-Orchestra)

## 設計原則

1. **path-1 真実層** — Buringh / IDC / UNESCO を `authority_tier` で層別固定。差分は `htp_source_discrepancies` に注記
2. **v2 失敗継承** — 推定/実測混在防止 (`gta_status` 4値) / 言語圏不均衡防止 (`coverage_flag`) / 媒体定義揺れ防止 (`medium_definition` 固定)
3. **件数禁止 KPI** — `verified_rate ≥ 90%` / `source_url_live = 100%` / `cross_refs ≥ 10`
4. **統合ハブを最初に置く** — `htp_unified_volume` を Phase 1 の最初の DDL 行として定義

## ディレクトリ構成

```
htp-db/
├── PROJECT_PLAN.md           # 設計ドキュメント
├── htp.db                    # SQLite DB
├── phase1_schema/
│   └── schema.sql            # DDL
├── phase2_etl/
│   ├── seed_data.sql         # Wave 1 seed
│   └── wave2_4_seed.sql      # Wave 2-4 ETL
├── phase3_validate/
├── phase4_crossref/
└── phase5_dashboard/
    └── htp-dashboard.html    # 赤白CI textbook.html style ダッシュボード
```

## 利用

専属エージェント `/htp` で照会可能。

```bash
# 直接クエリ
sqlite3 htp.db "SELECT period_id, volume_estimate_central, unit FROM htp_unified_volume ORDER BY year_start"
```

## Wave 進行

| Wave | スコープ | 状態 |
|---|---|---|
| 1 | 1450-2026 (近世-デジタル) | 完走 |
| 2 | 500-1450 (中世写本期) | 完走 |
| 3 | BC3200-AD500 (古代) | 完走 |
| 4 | 言語圏拡張 + AI 時代 + 補論統合 | 完走 |

## ミラツク事業フック

補論「**情報生産の2030-2100**」の歴史根拠層。動詞転換 4 段階「書き写す → 印刷する → 発信する → 共に生成する」を量的データで裏打ち。

## 構築実績

- 着手: 2026-05-15
- 完成: 2026-05-15（Wave 1-4 同日完走）
- 経路: `/db-master` (Tier 0 メタオーケストレーター) → 経路 B 実データDB
- チーム: db-timeseries-builder（主）+ db-text-corpus-builder（補）+ db-people-builder（副）+ db-data-verifier × 4並列

## ライセンス

Private. 個別ソースのライセンスは `htp_sources.license` 列を参照。
