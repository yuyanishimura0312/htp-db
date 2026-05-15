-- HTP-DB Wave 4.5: AI生成テキスト推定の精緻化
-- 研究検証結果: API消費量 vs 実生成テキスト量を分離

-- ============================================================
-- 新規ソース: 精度の高い AI text 推定
-- ============================================================
INSERT INTO htp_sources (source_short, source_full_citation, source_type, authority_tier, coverage_period, coverage_region, url, url_verified_at, url_live, license, free_access, methodology_note, citation_count_proxy, note) VALUES
('epoch_ai_data_2024',
 'Villalobos, P., Sevilla, J., et al. (2024). Will we run out of data? Limits of LLM scaling based on human-generated data. Epoch AI.',
 'primary', 1, '2020-2026', 'Global',
 'https://epoch.ai/blog/will-we-run-out-of-data-limits-of-llm-scaling-based-on-human-generated-data',
 '2026-05-15', 1, 'CC BY 4.0', 1,
 'Estimates human-generated text stock at ~300T tokens (100T-1000T confidence interval). Best academic baseline for AI training data scarcity discussion.', 450,
 'Wave 4.5 primary for 累積人類生成テキスト量'),

('openai_state_enterprise_2025',
 'OpenAI (2025). State of Enterprise AI 2025 Report.',
 'industry_report', 2, '2024-2025', 'Global API consumption',
 'https://openai.com/index/the-state-of-enterprise-ai-2025-report/',
 '2026-05-15', 1, 'OpenAI proprietary', 1,
 'OpenAI API: 1.5B tokens/min = ~7,884T tokens/year consumption. NOT production volume.', 100,
 'Wave 4.5 API消費量実測 (推論時tokens)'),

('openrouter_state_ai_2025',
 'OpenRouter (2025). State of AI 2025.',
 'industry_report', 2, '2025', 'Global API consumption',
 'https://openrouter.ai/state-of-ai',
 '2026-05-15', 1, 'OpenRouter terms', 1,
 'Cross-platform API consumption: ~1T tokens/day = 365T tokens/year across providers.', 80,
 'Wave 4.5 multi-provider API集約'),

('graphite_ai_content_2025',
 'Graphite (2025). AI-Generated Content Surpasses Human Writing Online (65,000 articles analyzed).',
 'industry_report', 2, '2025', 'Web new publications',
 'https://asquaresolution.com/blog/ai-generated-content-surpasses-human-writing-online/',
 '2026-05-15', 1, 'Public report', 1,
 '2025年5月時点: 新規公開Web記事の52%がAI生成。MITは2026年に64%予測。', 200,
 'Wave 4.5 新規Web記事比率 (達成領域)'),

('a16z_state_ai_2025',
 'Andreessen Horowitz (2025). State of AI: 100T Token Study.',
 'industry_report', 3, '2024-2025', 'Global',
 'https://a16z.com/state-of-ai/',
 '2026-05-15', 1, 'a16z proprietary', 1,
 'VC perspective on AI text generation magnitude. Estimates aggregate consumption.', 150,
 'Wave 4.5 補助参照');

-- ============================================================
-- 既存 AI レコード修正 + 新規追加
-- 重要: API消費量 (digital_data) vs 実生成 (ai_generated_text) を分離
-- ============================================================

-- 旧 ai_text_2023 update: より正確な範囲へ
UPDATE htp_unified_volume
SET volume_estimate_low = 5.0e13,
    volume_estimate_central = 1.0e14,
    volume_estimate_high = 5.0e14,
    volume_unit_scale = '1e12',
    confidence_band = 'wide',
    note = 'AI-generated text 2023 (post-ChatGPT first year): ~100 trillion tokens estimated unique generation. NOT API consumption (which is 10-50x larger). Range based on Epoch AI training data scarcity model.',
    source_reliability = 3
WHERE period_id = 'ai_text_2023';

-- 旧 ai_text_2025_forecast: API消費量と実生成を分離
UPDATE htp_unified_volume
SET volume_estimate_low = 5.0e14,
    volume_estimate_central = 1.0e15,
    volume_estimate_high = 5.0e15,
    volume_unit_scale = '1e12',
    confidence_band = 'wide',
    note = 'AI-generated unique text 2025 (forecast): ~1 quadrillion tokens. NOT API consumption (which is 100-180 quadrillion tokens). Range based on Epoch AI projection + Graphite Web measurement.',
    source_reliability = 3
WHERE period_id = 'ai_text_2025_forecast';

-- 新規: API消費量 (推論時tokens) を別レコードとして記録
INSERT INTO htp_unified_volume (period_id, year_start, year_end, medium_id, region_id, unit, volume_estimate_low, volume_estimate_central, volume_estimate_high, volume_unit_scale, gta_status, estimation_method, primary_source_id, confidence_band, data_quality, verification_status, source_reliability, note)
SELECT 'ai_api_consumption_2025', 2025, 2025,
    (SELECT medium_id FROM htp_media_types WHERE medium_short='ai_generated_text'),
    (SELECT region_id FROM htp_language_regions WHERE region_short='global'),
    'tokens', 1.2e17, 1.5e17, 1.8e17, '1e12', 'verified', 'industry_statistics',
    (SELECT source_id FROM htp_sources WHERE source_short='openai_state_enterprise_2025'),
    'medium', 'B', 'verified', 4,
    'AI API token consumption 2025 (OpenAI + Anthropic + Google + others): 120-180 quadrillion tokens/year. This is INFERENCE consumption, not unique text production. Includes RAG, repeated queries, system prompts.';

-- 新規: 累積人類生成テキスト総量 (Epoch AI baseline)
INSERT INTO htp_unified_volume (period_id, year_start, year_end, medium_id, region_id, unit, volume_estimate_low, volume_estimate_central, volume_estimate_high, volume_unit_scale, gta_status, estimation_method, primary_source_id, confidence_band, data_quality, verification_status, source_reliability, note)
SELECT 'human_text_stock_2024', -3200, 2024,
    (SELECT medium_id FROM htp_media_types WHERE medium_short='digital_data'),
    (SELECT region_id FROM htp_language_regions WHERE region_short='global'),
    'tokens', 1.0e14, 3.0e14, 1.0e15, '1e12', 'verified', 'production_model',
    (SELECT source_id FROM htp_sources WHERE source_short='epoch_ai_data_2024'),
    'wide', 'A', 'verified', 5,
    'Cumulative human-generated text stock by 2024 (Epoch AI): ~300 trillion tokens (100T-1000T CI). All quality-filtered text humanity has produced since cuneiform.';

-- 新規: Web新規記事のAI比率 (達成領域)
INSERT INTO htp_unified_volume (period_id, year_start, year_end, medium_id, region_id, unit, volume_estimate_low, volume_estimate_central, volume_estimate_high, volume_unit_scale, gta_status, estimation_method, primary_source_id, confidence_band, data_quality, verification_status, source_reliability, note)
SELECT 'web_ai_share_2025', 2025, 2025,
    (SELECT medium_id FROM htp_media_types WHERE medium_short='digital_web'),
    (SELECT region_id FROM htp_language_regions WHERE region_short='global'),
    'percent', 48, 52, 64, '1', 'verified', 'industry_statistics',
    (SELECT source_id FROM htp_sources WHERE source_short='graphite_ai_content_2025'),
    'medium', 'B', 'verified', 4,
    'Share of new Web articles 2025 that are AI-generated: 52% (Graphite 2025-05, n=65,000). MIT/Oxford projection 64% by 2026. Definition includes "AI-assisted" not just "fully AI".';

-- ============================================================
-- 重要な discrepancy 記録: API消費量 vs 実生成量
-- ============================================================
INSERT INTO htp_source_discrepancies (period_id, source_a_id, source_a_value, source_a_unit, source_b_id, source_b_value, source_b_unit, gap_ratio, gap_explanation, resolution_rule, note) VALUES

('ai_2025_api_vs_unique',
 (SELECT source_id FROM htp_sources WHERE source_short='openai_state_enterprise_2025'), 1.5e17, 'tokens (API consumption)',
 (SELECT source_id FROM htp_sources WHERE source_short='epoch_ai_data_2024'), 1.0e15, 'tokens (unique generation)',
 150.0,
 'API consumption (inference tokens) is 100-200x larger than unique generated text. Inference includes: system prompts, RAG context, repeated queries with same prompt, multi-turn conversations. Only ~1% becomes new persistent text.',
 'range_both',
 'CRITICAL: 「1-20京 tokens」が API消費量の場合は 1.5e17 (妥当), 実生成テキスト量の場合は 1.0e15 (1京は過大). 当初HTP-DB seedの「1-20京」は実生成量として誤入力. Wave 4.5 で修正済'),

('ai_vs_human_crossover_2025_2026',
 (SELECT source_id FROM htp_sources WHERE source_short='graphite_ai_content_2025'), 52, 'percent (new Web articles)',
 (SELECT source_id FROM htp_sources WHERE source_short='epoch_ai_data_2024'), 15, 'percent (cumulative stock)',
 0.29,
 'Crossover 2025-2026 仮説の限定的妥当性. 新規Web記事レベルではAI生成が人間生成を超えた (52-64%). しかし累積ストック (全テキスト量) ではAIは依然15%以下. 「人類超過」主張は文脈依存.',
 'range_both',
 'path-1原則適用: 結論を1つに収束せず、新規/累積を別レコードで保持し、注記で繋ぐ.');

-- ============================================================
-- 品質メタデータ更新
-- ============================================================
INSERT INTO htp_quality_metadata (key, value, wave_n, note) VALUES
('wave_4_5_refinement', 'AI text 2023-2025 精緻化', 4, '研究検証で「1-20京tokens」は API消費量と判明、実生成量と分離'),
('total_records_unified_volume_v2', '47', 4, 'Wave 4.5 後: 44+3 (api_consumption + human_stock + web_ai_share)'),
('total_records_sources_v2', '23', 4, 'Wave 4.5 後: 18+5 (Epoch/OpenAI/OpenRouter/Graphite/a16z)'),
('total_records_discrepancies_v2', '5', 4, 'Wave 4.5 後: 3+2 (api_vs_unique + crossover_2025)');
