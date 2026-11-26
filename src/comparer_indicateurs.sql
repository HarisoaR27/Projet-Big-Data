WITH sequences AS (
    SELECT *,
           (ordre_sequence - 1.0)
               / max(ordre_sequence) OVER (PARTITION BY prime_id) AS position
    FROM read_parquet(getvariable('resultat_parquet'))
),
groupes AS (
    SELECT 'Format' AS axe, format AS groupe, *
    FROM sequences
    WHERE prestation_id IS NOT NULL
    UNION ALL
    SELECT 'Moment' AS axe,
           CASE WHEN position < 1.0 / 3 THEN '1. Début'
                WHEN position < 2.0 / 3 THEN '2. Milieu'
                ELSE '3. Fin' END AS groupe, *
    FROM sequences
)
SELECT axe, groupe,
       count(*) AS sequences,
       count(lectures) AS sequences_avec_replay,
       round(100.0 * sum(retenus_fin) / nullif(sum(presents_debut), 0), 2) AS retention_pct,
       round(avg(votants), 1) AS votants_moyens_par_sequence,
       round(100.0 * sum(lectures_completes) / nullif(sum(lectures), 0), 2) AS completion_pct
FROM groupes
GROUP BY axe, groupe
ORDER BY axe, groupe;
