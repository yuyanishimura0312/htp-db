# HTP-DB — Human Text Production Database

**人類が時代ごとに生成した文字・テキストの量推定データベース**

- DB ID: `htp`
- 着手日: 2026-05-15
- 経路: B（実データDB / 5段階方法論）
- 担当: db-timeseries-builder（主）+ db-text-corpus-builder（補）+ db-people-builder（副）
- Wave: 1 (MVP)
- スコープ: 1450-2026（近世・近代・現代・デジタル時代）
- Wave 2-3: 中世500-1450、古代BC3200-AD500（誤差幅flag付）

---

## 0. v2 失敗継承（暗黙知2: v1失敗をv2 READMEに）

過去のtext-corpus系DB（PESTLE / CI / Myth Narratives）で繰り返された3つの失敗を構造的に再発防止する。

### 失敗1: 推定値と実測値の混在
- **症状**: verified_rate が見かけ上高くなり、現場での引用時に推定だったと判明
- **対策**: `gta_status` 4値（`verified` / `estimated` / `extrapolated` / `placeholder`）を全数値カラムに強制。`estimation_method` を別カラムで保持

### 失敗2: 言語圏不均衡
- **症状**: 欧米中心ソース（Buringh等）に依存し、漢字圏・アラビア圏が空欄
- **対策**: `htp_language_regions.coverage_flag`（0=未カバー/1=部分/2=充足）を起動時チェック。欧米偏重検出時にWARNを発出

### 失敗3: 媒体定義の揺れ
- **症状**: 「印刷本」が時代によって意味が異なり、量推定が比較不能になる
- **対策**: `htp_media_types.medium_definition` に時代別定義を固定。`wave_introduced` で定義変更履歴を追跡

---

## 1. path-1 真実層（暗黙知5: 訂正版を重ねる誠実性）

複数の推定モデルが食い違う場合、結論を1つに収束させるのではなく、層別固定＋差分注記で透明性を保持する。

| 時代区間 | 正本（authority_tier=1） | 補助（authority_tier=2） |
|---|---|---|
| 1450-1800 | Buringh & van Zanden (2009) | OWID再集約 / Febvre & Martin |
| 1800-1985 | UNESCO UIS国別書籍統計 | OECD / Google Books Library |
| 1986-2026 | IDC Global DataSphere | Internet Archive量推定 / Statista |
| 識字補正 | UNESCO識字率 | OWID Literacy Rate |
| 漢字圏 | Sinica漢籍全文資料庫（700M字） | 四庫全書(7.97億字推定) |
| アラビア圏 | Shamela peer-reviewed (1B語) | OpenITI |

差分は `htp_source_discrepancies` テーブルに記録し、書き換えではなく **繋ぐ**。

---

## 2. KPI（件数禁止・検証通過率主導）

- `verified_rate ≥ 0.90`（一次ソース照合済み比率）
- `source_url_live_rate = 1.0`（URL live率 100%）
- `cross_refs ≥ 10`（既存64DBとの接続件数）
- `estimation_traceability ≥ 0.95`（推定値の出典追跡率）
- `cross_source_agreement` 明示（Buringh vs IDC の乖離幅を記録）
- `abstain_rate` 明示（照合不能はNULL + gta_status='estimated'）

**禁止**: 「N万件」を成果指標にすること。件数は副産物として記録のみ。

---

## 3. テーブル設計（7テーブル）

### 設計原則
- **統合ハブを最初に置く**: `htp_unified_volume` を Phase 1 の最初の DDL 行として定義（GC-DB `cycle_mechanisms` と同じ中核設計）
- 他テーブルは全て `htp_unified_volume` へ FK
- メタデータ多軸（暗黙知4）: `gta_status` / `data_quality` / `verification_status` / `source_reliability`

### テーブル一覧

1. **htp_unified_volume** — 統合ハブ。時代×媒体×言語圏×単位の推定値を範囲表現で保持
2. **htp_sources** — path-1真実層。authority_tier層別、URL live検証日時付き
3. **htp_source_discrepancies** — 複数ソース不一致の明示テーブル
4. **htp_media_types** — 媒体定義の固定（v2失敗継承: 揺れ防止）
5. **htp_language_regions** — 言語圏バランス管理（v2失敗継承: 不均衡防止）
6. **htp_cross_db_refs** — 既存64DBへの統一参照
7. **htp_quality_metadata** — KV形式品質メタデータ（全Phase共通インフラ）

---

## 4. Phase 0-6 工程（合計 2.0 FDD = 16h）

| Phase | FDD | 内容 |
|---|---|---|
| 0 Spec | 0.3 | 本ドキュメント策定。BLOCK 2件対処 |
| 1 Schema | 0.3 | SQLite DDL 7テーブル + index + seed |
| 2 ETL | 0.5 | Buringh / OWID / UNESCO / IDC / Sinica / Shamela 統合 |
| 3 Validate | 0.3 | verified_rate ≥90% / source_url 100% / 件数禁止 |
| 4 CrossRef | 0.2 | 既存64DBと cross_refs ≥ 10件 |
| 5 Dashboard | 0.25 | 赤白CI textbook.html style |
| 6 Publish | 0.15 | GitHub + db-registry + 専属/htpエージェント + Notion + MEMORY |

---

## 5. cross_refs 10件具体案

1. **TA** (Tech Acceleration) — year — supports — 印刷・デジタル加速がテキスト量増加と対応
2. **CDH** (Cost-Down History) — medium × year — supports — 印刷コスト逓減がテキスト量増加の駆動因
3. **CI** (Cultural Intelligence) — language_region — extends — 言語圏別文化生産との照合
4. **SI** (SI Framework) — year × medium — supports — 印刷革命・電信・インターネットが7,389事象と重複
5. **MG** (Management Studies) — concept — extends — 知識経済・媒体理論（McLuhan）の基盤
6. **PESTLE** — year × region — contradicts — 検閲イベントが量減少と対応（反証）
7. **UPR** (University Press Releases) — year — extends — 学術テキスト現代部分を補完
8. **TK** (Traditional Knowledge) — language_region — extends — 非文字圏の明示
9. **GC-DB SF3** (内生的成長) — concept:knowledge_spillover — supports — Romer型知識蓄積との接続
10. **FTT-DB v2** (Future Tech Trends) — year × technology — supports — AI生成テキスト出現の転換点

---

## 6. ミラツク事業接続 — 補論執筆フック

### 主要接続: 補論「情報生産の2030-2100」

動詞転換4段階:
- **書き写す**（写本期 ~1450）
- **印刷する**（近代 1450-1985）
- **発信する**（デジタル 1985-2022）
- **共に生成する**（AI時代 2022-2100）

Wave 1 公開と同時に `/future-vision-orchestrate` 起動可能。HTP-DBが歴史根拠層を担い、FVCP の4時代パネルで2030-2100を描出。

### 副次接続
- **変化のかたち連載** — 情報生産の変容型として1話化
- **事業のかたち** — コンテンツ事業の歴史的前提条件
- **暮らしのかたち** — 日記・手紙・投稿という日常的テキスト生産
- **ANSWER+** — 23.5万人研究者DBと研究テキスト生産量の相関
- **GC-DB SF3** — 知識スピルオーバーの量的基盤

---

## 7. 品質ゲート判定（各Phase）

| Phase | PASS条件 |
|---|---|
| 1 | htp_unified_volume が最初のテーブルとして存在 / 7テーブル全DDLが通る / Buringh・IDC・UNESCO登録済 |
| 2 | 全source_url のlive検証ログ存在 / gta_status NULL=0 / discrepancies に重複期間乖離記録 |
| 3 | verified_rate ≥90% / source_url live率=100% / 出典追跡率≥95% / abstain_count明示 |
| 4 | cross_db_refs ≥10件 / relationship_type 全行設定済 |
| 5 | 赤白CI :root CSS変数完全コピー / 絵文字未使用 / 推定値を範囲帯で表現 |

REJECTED 時は該当Phaseへロールバック（上限3回）。

---

## 8. Wave 2/3 想定

| Wave | スコープ | FDD | 主要課題 |
|---|---|---|---|
| 2 | 中世 500-1450 | 2-3 | 推定誤差幅 ±30-50%。アラビア語・漢字・ラテン語の三極バランス |
| 3 | 古代 BC3200-AD500 | 3-5 | 考古学的推定主体。CDLI/Perseus/Oxyrhynchus が主根拠 |
| 4 | 言語圏拡張+補論統合 | 4-8 | Global South 強化 |

---

## 履歴
- 2026-05-15 v1.0 策定。/db-master 経由で Stage 1-4 完了後の Phase 0 として作成。
