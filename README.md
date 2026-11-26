# Star Academy — Comment programmer un prime qui retient le public ?

## Auteurs

- Pia 
- Harisoa

## Jeu de données

Le jeu **Star Academy 2025–2026 — audience simulée** a été généré le **26 novembre 2026**. Il contient **7 CSV**, **69 698 lignes** et **4 889 399 octets hors compression (4,89 Mo)**. Licence du jeu généré — [à renseigner par les auteurs].

Pour respecter la limite de 5 Mo, nous avons utilisé une IA pour relever une sélection de prestations des primes du 25 octobre et du 1er novembre 2025 à partir de sources publiques. Ce relevé ciblé a remplacé une collecte automatisée de pages web. Un script Python à graine fixe a ensuite généré les sept CSV avec un volume maîtrisé.

Le conducteur reprend des prestations documentées avec des horaires reconstruits pour le scénario. Les sessions de direct et de replay, les fenêtres de vote, les votes, les notes et les sondages sont simulés. Ce choix permet de relier les trois types d’engagement à une même séquence. Les résultats décrivent le scénario généré. Les URL sources figurent dans le conducteur et la méthode est détaillée dans [PROVENANCE.md](PROVENANCE.md). [TF1+ — Prime du 25 octobre](https://www.tf1.fr/tf1/star-academy/videos/star-academy-2025-prime-2-partie-1-du-25-octobre-2025-04437941.html) · [TF1+ — Prime du 1er novembre](https://www.tf1.fr/tf1/star-academy/videos/star-academy-2025-prime-3-partie-1-du-1-novembre-2025-95947030.html) · [Stars Actu — Programme annoncé du 25 octobre](https://www.stars-actu.fr/2025/10/star-academy-les-duos-et-chansons-du-2eme-prime-du-25-octobre-devoiles/)

## Problématique

Quels formats et moments du prime sont associés à la meilleure rétention en direct, au plus grand nombre de votants et à la meilleure complétion en replay ?

## Chemins S3

- **Entrées CSV** — `s3://user-h-randrianasolo-ece/star-academy/raw/`
- **Sortie Parquet** — `s3://user-h-randrianasolo-ece/star-academy/processed/indicateurs_sequences.parquet`

## Reproduction

Depuis la racine du dépôt, dans le terminal Onyxia avec le profil S3 `default` configuré :

```bash
(
  set -e
  set -o pipefail
  S3="s3://user-h-randrianasolo-ece/star-academy"
  DONNEES=$(mktemp -d)

  aws s3 --profile default cp "$S3/raw/" "$DONNEES/" \
    --recursive --exclude "*" --include "*.csv"

  {
    printf "SET VARIABLE dossier_donnees = '%s';\n" "$DONNEES"
    cat src/indicateurs_sequences.sql
  } | duckdb -bail

  aws s3 --profile default cp "$DONNEES/indicateurs_sequences.parquet" \
    "$S3/processed/indicateurs_sequences.parquet"

  {
    printf "SET VARIABLE resultat_parquet = '%s';\n" "$DONNEES/indicateurs_sequences.parquet"
    cat src/comparer_indicateurs.sql
  } | duckdb -bail
)
```

Pour relancer le pipeline, rejouer le bloc complet. Il récupère les CSV dans un nouveau dossier temporaire et republie le résultat au même emplacement. Pour reconstruire les entrées, utiliser le [générateur Python](src/generer_donnees.py) et déposer les sept CSV produits sous `raw/`.

## Preuves d’exécution

| Preuve | Résultat observé et rôle dans le pipeline |
|---|---|
| **01 — Ingestion sur S3** | Les **7 CSV** totalisent **4 889 399 octets** sous `raw/`. Comparer le nombre d’objets et leur taille au jeu attendu permet de repérer un transfert incomplet avant le calcul. [Voir la capture 01](capture/01_s3_donnees_brutes.png) |
| **02 — Lecture dans DuckDB** | DuckDB lit le conducteur téléchargé depuis S3 et compte **22 séquences**, dont **10 prestations**. Le conducteur est la référence pour rattacher les événements aux séquences et expliquer à quel niveau chaque indicateur est calculé. [Voir la capture 02](capture/02_duckdb_lecture_csv.png) |
| **03 — Contrôles qualité** | Les requêtes vérifient les identifiants de séquence et de vote, les clés des fenêtres et la validité des horaires de vote. Une fenêtre dupliquée peut multiplier les votes lors de la jointure. Un vote hors fenêtre risquerait d’être attribué à tort au prime. [Voir la capture 03](capture/03_duckdb_controles_qualite.png) |
| **04 — Calcul des indicateurs** | Le traitement agrège le direct, les votes et les replays séparément avant de les joindre au conducteur. Cette méthode évite qu’un vote soit répété pour chaque lecture replay et conserve **une ligne par séquence** dans le résultat. [Voir la capture 04](capture/04_duckdb_execution_pipeline.png) |
| **05 — Publication de la sortie** | S3 liste `indicateurs_sequences.parquet`, de **3 901 octets**, sous `processed/`. Le fichier est ainsi disponible pour une analyse ultérieure, indépendamment du dossier temporaire utilisé par DuckDB. [Voir la capture 05](capture/05_s3_donnees_traitees.png) |
| **06 — Vérification indépendante** | Un script Python recompte les votes et les votants de `prime_02_seq_02` à partir des horaires des CSV bruts. Il retrouve **333 votes et 333 votants distincts**, comme dans le Parquet récupéré depuis S3. Ce contrôle vérifie le comptage sur une séquence avec une autre implémentation. [Voir la capture 06](capture/06_verification_independante.png) |
| **07 — Comparaison des formats et des moments** | Dans la simulation, la rétention passe de **94,97 % en début de prime** à **86,43 % en fin de prime**. Le solo affiche la meilleure complétion replay parmi les formats (**56,52 %**, sur deux prestations). Le battle atteint **629 votants** sur une seule séquence. Les effectifs et les fenêtres de vote aident à interpréter ces écarts. [Voir la capture 07](capture/07_comparaison_formats_moments.png) |