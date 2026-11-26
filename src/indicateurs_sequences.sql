CREATE TEMP VIEW conducteur AS
SELECT * FROM read_csv_auto(getvariable('dossier_donnees') || '/conducteur_primes_simule.csv');

CREATE TEMP TABLE indicateurs AS
WITH sessions AS (
    SELECT * FROM read_csv_auto(getvariable('dossier_donnees') || '/sessions_direct_simulees.csv')
),
direct AS (
    SELECT c.sequence_id,
           count(DISTINCT d.spectateur_id) AS presents_debut,
           count(DISTINCT f.spectateur_id) AS retenus_fin
    FROM conducteur c
    LEFT JOIN sessions d ON d.prime_id = c.prime_id
        AND d.debut_session <= c.debut_sequence
        AND d.fin_session > c.debut_sequence
    LEFT JOIN sessions f ON f.prime_id = c.prime_id
        AND f.spectateur_id = d.spectateur_id
        AND f.debut_session < c.fin_sequence
        AND f.fin_session >= c.fin_sequence
    GROUP BY c.sequence_id
),
vote AS (
    SELECT c.sequence_id, count(*) AS votes,
           count(DISTINCT v.votant_id) AS votants
    FROM conducteur c
    JOIN read_csv_auto(getvariable('dossier_donnees') || '/votes_public_simules.csv') v
      ON v.prime_id = c.prime_id
     AND v.vote_at >= c.debut_sequence AND v.vote_at < c.fin_sequence
    JOIN read_csv_auto(getvariable('dossier_donnees') || '/fenetres_vote_simulees.csv') f
      ON f.prime_id = v.prime_id AND f.fenetre_id = v.fenetre_id
     AND v.vote_at >= f.ouverture AND v.vote_at < f.fermeture
    GROUP BY c.sequence_id
),
replay AS (
    SELECT prestation_id, count(*) AS lectures,
           count(*) FILTER (WHERE duree_vue_s = duree_totale_s) AS lectures_completes
    FROM read_csv_auto(getvariable('dossier_donnees') || '/sessions_replay_simulees.csv')
    GROUP BY prestation_id
),
jury AS (
    SELECT prestation_id, avg(note_sur_20) AS moyenne_jury
    FROM read_csv_auto(getvariable('dossier_donnees') || '/notes_jury_simulees.csv')
    GROUP BY prestation_id
),
sondage AS (
    SELECT prestation_id, avg(note_sur_20) AS moyenne_sondage
    FROM read_csv_auto(getvariable('dossier_donnees') || '/sondages_public_simules.csv')
    GROUP BY prestation_id
)
SELECT c.prime_id, c.sequence_id, c.ordre_sequence, c.type_sequence,
       c.format, c.prestation_id, d.presents_debut, d.retenus_fin,
       round(100.0 * d.retenus_fin / nullif(d.presents_debut, 0), 2) AS retention_pct,
       coalesce(v.votes, 0) AS votes, coalesce(v.votants, 0) AS votants,
       r.lectures, r.lectures_completes,
       round(100.0 * r.lectures_completes / nullif(r.lectures, 0), 2) AS completion_pct,
       round(j.moyenne_jury, 2) AS moyenne_jury,
       round(s.moyenne_sondage, 2) AS moyenne_sondage
FROM conducteur c
JOIN direct d USING (sequence_id)
LEFT JOIN vote v USING (sequence_id)
LEFT JOIN replay r ON r.prestation_id = c.prestation_id
LEFT JOIN jury j ON j.prestation_id = c.prestation_id
LEFT JOIN sondage s ON s.prestation_id = c.prestation_id;

COPY indicateurs TO (getvariable('dossier_donnees') || '/indicateurs_sequences.parquet')
    (FORMAT PARQUET);

SELECT count(*) AS sequences_exportees FROM indicateurs;
SELECT prime_id, ordre_sequence, format, retention_pct, votants, completion_pct
FROM indicateurs
WHERE prestation_id IS NOT NULL
ORDER BY prime_id, ordre_sequence
LIMIT 6;
