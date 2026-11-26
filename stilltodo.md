# Checklist du projet Star Academy

**Titre** — Star Academy : comment programmer un prime qui retient le public ?  
**Question** — Quels formats et moments du prime sont associés à la meilleure rétention en direct, au plus grand nombre de votants et à la meilleure complétion en replay ?  
**Analyse principale** — Mesurer, parmi les spectateurs présents au début d’une séquence, la part encore présente à sa fin, retours compris. Comparer la rétention par format et par tiers du prime.  
**Date limite** — Vendredi 4 décembre 2026.

## 1. Dépôt et répartition

- [x] Créer le dépôt [Projet-Big-Data](https://github.com/HarisoaR27/Projet-Big-Data) et le cloner dans Onyxia.
- [ ] Vérifier la visibilité publique du dépôt et l’accès du deuxième membre du binôme dans **Settings → Collaborators**.
- [ ] Vérifier que chaque membre peut pousser un commit sous sa propre identité GitHub.
- [ ] Vérifier que le code est versionné dans `src/` et que les images sont présentes dans `capture/`. Le sujet indique `evidence/` comme nom attendu pour le rendu. Confirmer avec l’enseignante si `capture/` est accepté.
- [ ] Vérifier que l’historique contient **au moins 10 commits de travail réel répartis sur plusieurs jours**, avec des contributions visibles des deux membres.
- [ ] Répartir la finalisation en binôme. Répartition proposée : un membre rejoue le pipeline, mesure l’alternative CSV/Parquet et finalise le README. L’autre rassemble les preuves et rédige le PDF. Relire le rendu ensemble.

## 2. Données et provenance

- [x] Générer les sept CSV définitifs à partir d’un scénario inspiré d’une sélection de prestations publiques des **25 octobre et 1er novembre 2025**.
- [x] Utiliser un relevé ciblé assisté par IA à partir de TF1+ et de Stars Actu, puis un générateur Python à graine fixe pour respecter la limite de taille. Les horaires sont reconstruits et les comportements d’audience sont simulés.
- [x] Générer les données le **26 novembre 2026** et vérifier la taille brute cumulée : **69 698 lignes de données et 4 889 399 octets hors compression (4,89 Mo)**.
- [ ] Versionner `src/generer_donnees.py` et `PROVENANCE.md` depuis l’archive définitive. Indiquer dans le README la commande de génération, le dossier de sortie et la licence retenue.

| Fichier brut | Contenu et rôle |
|---|---|
| `conducteur_primes_simule.csv` | Référentiel des séquences et prestations. Il contient les horaires, l’ordre, le format, les candidats, le style, les invités et la publication replay. Les candidats d’une même prestation sont séparés par `\|`. |
| `sessions_direct_simulees.csv` | Une ligne par session de direct. Un spectateur peut avoir plusieurs sessions dans un prime, ce qui permet de représenter les retours. |
| `notes_jury_simulees.csv` | Une note par juré, candidat et prestation. |
| `sondages_public_simules.csv` | Une note par spectateur, candidat et prestation. |
| `fenetres_vote_simulees.csv` | Horaires d’ouverture et de fermeture des fenêtres de vote, identifiées dans chaque prime. |
| `votes_public_simules.csv` | Votes horodatés, associés à une fenêtre, à un votant et à un candidat. |
| `sessions_replay_simulees.csv` | Lectures associées à une prestation, avec la durée vue et la durée totale. |

## 3. Pipeline exécuté sur Onyxia

- [x] Configurer le profil S3 `default` et déposer les sept CSV sous `s3://user-h-randrianasolo-ece/star-academy/raw/`.
- [x] Télécharger les CSV de S3 dans un dossier temporaire sur Onyxia avec l’AWS CLI. Lire les fichiers avec **DuckDB** depuis le service VS Code PySpark.
- [x] Écrire le traitement dans `src/indicateurs_sequences.sql`. Agréger les sources séparément avant de les joindre au conducteur pour éviter de multiplier les comptages.
- [x] Publier le jeu final sous `s3://user-h-randrianasolo-ece/star-academy/processed/indicateurs_sequences.parquet`. La sortie contient **22 lignes**, une par séquence.
- [x] Comparer les formats et les moments du prime avec `src/comparer_indicateurs.sql`.
- [ ] Versionner les contrôles SQL. Reporter les compteurs effectivement affichés pour l’unicité des séquences, des votes et des fenêtres, ainsi que pour les votes sans fenêtre valide. Documenter les anomalies observées et le traitement appliqué, le cas échéant.
- [ ] Rejouer les commandes du README depuis une session propre et vérifier que la sortie est republiée au même emplacement.
- [ ] Mesurer une alternative technique. Comparer la taille et le temps de la même agrégation sur un CSV et son équivalent Parquet, avec les mêmes lignes et sur le même service. Reporter les mesures dans le PDF.

| Indicateur | Calcul réellement exécuté |
|---|---|
| **Rétention en direct** | Part des spectateurs présents au début et encore présents juste avant la fin. Un spectateur revenu avant la fin peut être compté comme retenu. |
| **Vote** | Nombre de votes et de votants distincts par séquence. L’horodatage doit appartenir à la séquence et à une fenêtre de vote valide, avec début inclus et fin exclue. |
| **Complétion en replay** | Part des lectures dont la durée vue atteint la durée totale, parmi les lectures simulées disponibles pour chaque prestation. |
| **Jury et sondages** | Moyennes calculées séparément par prestation, utilisées comme informations complémentaires. |

Les pistes initiales sur l’effet des invités, la comparaison solo/duo à candidat et style comparables, le taux de vote pour 1 000 spectateurs et la complétion à 48 heures restent des prolongements. Les résultats du rendu s’appuient sur les calculs du tableau ci-dessus.

## 4. Résultats et preuves

- [x] Vérifier indépendamment les votes de `prime_02_seq_02`. Le comptage Python depuis les CSV bruts et le Parquet récupéré depuis S3 donnent **333 votes et 333 votants distincts**.
- [x] Relever les résultats de la comparaison. La rétention est de **94,97 % en début de prime** et de **86,43 % en fin de prime**. Le battle atteint **629 votants sur une seule séquence**. Les solos affichent **56,52 % de complétion replay sur deux prestations**.
- [ ] Enregistrer dans `src/` le script Python utilisé pour la vérification indépendante, avec sa commande d’exécution.
- [ ] Vérifier que chaque capture affiche l’identifiant ou le namespace Onyxia, la date et l’heure. Reprendre la capture 07 en incluant ces éléments. Vérifier que les images publiées ne montrent aucun secret.

| Capture | Preuve attendue |
|---|---|
| `01_s3_donnees_brutes.png` | Les sept CSV sont présents sur S3 et leur taille cumulée est de 4 889 399 octets. |
| `02_duckdb_lecture_csv.png` | DuckDB lit le conducteur téléchargé depuis S3 et affiche 22 séquences, dont 10 prestations. |
| `03_duckdb_controles_qualite.png` | Les compteurs de contrôle sont affichés avant le calcul. Les clés et les fenêtres conditionnent la fiabilité du comptage des votes. |
| `04_duckdb_execution_pipeline.png` | Le SQL exporte une ligne par séquence et affiche un aperçu des indicateurs. |
| `05_s3_donnees_traitees.png` | Le Parquet final est publié sur S3 et sa taille est de 3 901 octets. |
| `06_verification_independante.png` | Les deux méthodes retrouvent les mêmes 333 votes et 333 votants distincts. |
| `07_comparaison_formats_moments.png` | Le tableau d’analyse compare les formats et les trois moments du prime, avec le nombre de séquences par groupe. |

## 5. Finaliser et rendre

- [ ] Finaliser le `README.md` sur **une page**, avec les auteurs, les informations d’exécution demandées, la provenance, la licence, les chemins S3, les commandes de reproduction et les liens vers les preuves.
- [ ] Préparer le **PDF de quatre pages maximum, annexes comprises** :
  1. Problématique, données, schéma des fichiers et lien vers le dépôt Git.
  2. Diagramme du pipeline, justification de DuckDB et résultats de la comparaison CSV/Parquet.
  3. Contrôles qualité, compteurs d’anomalies, résultats et vérification indépendante.
  4. Limites du scénario simulé, effets attendus avec **100 fois plus de données** et références aux preuves.
- [ ] Relire le PDF en binôme et vérifier le dépôt public, les liens et l’historique des contributions.
- [ ] Envoyer le PDF par e-mail avant le **4 décembre 2026**. Objet : `Ecosystème Big Data II - <GrXX> - <NOM1 Prénom1> - <NOM2 Prénom2>`.