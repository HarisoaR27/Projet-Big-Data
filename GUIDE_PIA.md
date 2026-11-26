# Guide du binôme — Reproduction et comparaison CSV / Parquet

Ta mission est de **rejouer le pipeline Star Academy dans ton espace Onyxia**, puis de mesurer la différence entre CSV et Parquet sur les mêmes données. À la fin, tu auras deux captures, une note avec tes mesures et une branche GitHub à faire relire.

## 1. Récupérer le projet dans Onyxia

Ouvre **VS Code sur Onyxia**, puis **Terminal → Nouveau terminal**. Si tu n’as jamais cloné le projet dans cet espace, lance :

```bash
cd ~/work
git clone https://github.com/HarisoaR27/Projet-Big-Data.git
cd Projet-Big-Data
```

Si tu as déjà le dossier `Projet-Big-Data`, ouvre-le et vérifie `git status --short`. Si la sortie est vide, récupère les changements avec `git pull --ff-only` depuis la branche du projet. Vérifie que le README affiche les chemins **Bronze** et **Gold**.

Crée ensuite ta branche de travail et vérifie ton identité Git.

```bash
git switch -c mesures-csv-parquet
git config user.name
git config user.email
```

Si une valeur manque, configure-la pour ce dépôt avec `git config user.name "Prénom Nom"` et `git config user.email "TON_EMAIL_GITHUB"`. Tu peux utiliser l’adresse `noreply` fournie dans les paramètres de ton compte GitHub.

**Pourquoi ?** Ta branche te permet de préparer tes changements et de les faire relire. Ton identité Git permet d’attribuer ta contribution dans l’historique.

## 2. Mettre les sept CSV dans ton bucket Bronze

Si ton profil AWS `default` manque, configure-le depuis **Onyxia → Stockage de données → Détails du profil S3**, comme dans le TP. Garde le script de configuration et les identifiants hors de Git et des captures.

Dans le même terminal, remplace `user-TON-NOM` par le nom exact de ton bucket personnel. Garde ce terminal ouvert pour la suite.

```bash
S3="s3://user-TON-NOM/star-academy"
aws s3 --profile default ls "s3://user-TON-NOM/"

preuve() {
  date '+%Y-%m-%d %H:%M:%S %Z'
  printf 'Onyxia : %s\n' "${KUBERNETES_NAMESPACE:-$(hostname)}"
}
```

Utilise les **sept CSV définitifs** du projet. Tu peux les obtenir de deux façons :

- Si le dépôt contient `src/generer_donnees.py`, lance `python3 src/generer_donnees.py`. Avec ce générateur, les CSV sont créés dans `src/data/raw/`. Utilise le premier chemin dans le bloc ci-dessous.
- Si le générateur manque, demande à Harisoa l’archive `star_academy_2025_dataset.zip`. Téléverse-la dans Onyxia, puis lance `unzip star_academy_2025_dataset.zip -d /tmp/star-academy-binome` depuis le dossier qui contient le ZIP. Utilise alors `CSV_SOURCE="/tmp/star-academy-binome/data/raw"` dans le bloc ci-dessous.

```bash
CSV_SOURCE="src/data/raw"
wc -c "$CSV_SOURCE"/*.csv

aws s3 --profile default cp "$CSV_SOURCE/" "$S3/bronze/" \
  --recursive --exclude "*" --include "*.csv"

aws s3 --profile default ls "$S3/bronze/" --recursive --summarize
```

**Attendu** — 7 objets et **4 889 399 octets**. Si les totaux diffèrent, vérifie le dossier source avant de continuer.

**Pourquoi ?** Bronze contient les fichiers sources du pipeline. En repartant des mêmes CSV, tu peux vérifier que les résultats sont reproductibles dans ton propre environnement.

## 3. Rejouer le pipeline et vérifier Gold

Depuis la racine du dépôt, colle ce bloc. DuckDB traite les CSV téléchargés dans Onyxia. L’AWS CLI publie ensuite le Parquet dans ton bucket.

```bash
(
  set -euo pipefail
  DONNEES=$(mktemp -d)

  aws s3 --profile default cp "$S3/bronze/" "$DONNEES/" \
    --recursive --exclude "*" --include "*.csv"

  preuve
  {
    printf "SET VARIABLE dossier_donnees = '%s';\n" "$DONNEES"
    cat src/indicateurs_sequences.sql
  } | duckdb -bail

  aws s3 --profile default cp "$DONNEES/indicateurs_sequences.parquet" \
    "$S3/gold/indicateurs_sequences.parquet"

  preuve
  aws s3 --profile default ls "$S3/gold/indicateurs_sequences.parquet"

  aws s3 --profile default cp "$S3/gold/indicateurs_sequences.parquet" \
    "$DONNEES/resultat_s3.parquet"

  duckdb -bail -c "
    SELECT count(*) AS sequences
    FROM read_parquet('$DONNEES/resultat_s3.parquet');

    SELECT sequence_id, votes, votants
    FROM read_parquet('$DONNEES/resultat_s3.parquet')
    WHERE sequence_id = 'prime_02_seq_02';
  "
)
```

**Attendu** — Le Parquet relu depuis Gold contient **22 séquences**. Pour `prime_02_seq_02`, il affiche **333 votes et 333 votants distincts**, comme dans le résultat déjà vérifié par Harisoa.

Prends une capture de la fin de la commande avec le chemin Gold, les résultats, **la date, l’heure et ton identifiant Onyxia** visibles. Nomme-la **`09_reproduction_binome.png`** et place-la dans **`capture/`** à la racine du dépôt.

**Pourquoi ?** Relire le fichier depuis Gold confirme que la sortie publiée peut être récupérée et que le pipeline donne le même résultat dans ta session.

## 4. Mesurer l’alternative CSV / Parquet

On utilise le fichier des sessions en direct. Le bloc convertit le CSV en Parquet dans un dossier temporaire, affiche les tailles, puis chronomètre **la même agrégation** sur les deux formats, dans les deux ordres. Cette mesure ne crée aucune table intermédiaire sur S3.

```bash
(
  set -euo pipefail
  MESURE=$(mktemp -d)

  aws s3 --profile default cp \
    "$S3/bronze/sessions_direct_simulees.csv" "$MESURE/direct.csv"

  duckdb -bail -c "
    COPY (SELECT * FROM read_csv_auto('$MESURE/direct.csv'))
    TO '$MESURE/direct.parquet' (FORMAT PARQUET);
  "

  preuve
  wc -c "$MESURE/direct.csv" "$MESURE/direct.parquet"

  duckdb -bail <<SQL
.timer on
.print CSV - passage 1
SELECT prime_id, count(*) AS sessions
FROM read_csv_auto('$MESURE/direct.csv')
GROUP BY prime_id ORDER BY prime_id;

.print Parquet - passage 1
SELECT prime_id, count(*) AS sessions
FROM read_parquet('$MESURE/direct.parquet')
GROUP BY prime_id ORDER BY prime_id;

.print Parquet - passage 2
SELECT prime_id, count(*) AS sessions
FROM read_parquet('$MESURE/direct.parquet')
GROUP BY prime_id ORDER BY prime_id;

.print CSV - passage 2
SELECT prime_id, count(*) AS sessions
FROM read_csv_auto('$MESURE/direct.csv')
GROUP BY prime_id ORDER BY prime_id;
SQL
)
```

Vérifie que **les effectifs par prime sont identiques dans les quatre tableaux**. Relève, pour chaque format, la taille en octets et les deux temps `real` en secondes. Si les temps sont proches ou varient entre les passages, rapporte-le tel quel.

Prends **`08_comparaison_csv_parquet.png`** et place-la dans **`capture/`**. Affiche les tailles, les temps, la date, l’heure et ton identifiant Onyxia. Réduis le zoom du terminal si nécessaire.

**Pourquoi ?** Comparer le même calcul sur les mêmes lignes permet d’étudier l’effet du format de fichier. Le chronométrage porte sur la lecture et l’agrégation dans DuckDB. Le transfert S3 et la conversion ont lieu avant la mesure.

## 5. Rédiger ta partie du rapport

Crée `MESURES_CSV_PARQUET.md` à la racine du dépôt. Remplace les champs entre crochets par tes résultats. Ce texte servira à préparer la section **Choix techniques et mesures** du PDF.

| Format | Taille en octets | Temps `real` passage 1 | Temps `real` passage 2 |
|---|---:|---:|---:|
| CSV | [taille] | [temps en s] | [temps en s] |
| Parquet | [taille] | [temps en s] | [temps en s] |

> Nous avons comparé le comptage des sessions par prime sur le CSV source et son équivalent Parquet, dans la même session DuckDB sur Onyxia. Les deux formats donnent [effectifs observés par prime]. Le Parquet occupe [taille] octets contre [taille] octets pour le CSV. Les temps mesurés montrent [conclusion fondée sur les deux passages]. Avec un jeu de données 100 fois plus gros, le volume transféré, la lecture des colonnes et le coût des jointures seraient à mesurer à nouveau.

Ajoute les références aux captures `08` et `09`. Dans le PDF, décris aussi le parcours **S3 Bronze → copie dans Onyxia → calcul DuckDB → S3 Gold**.

## 6. Envoyer ta contribution sur GitHub

Une fois les deux images et la note enregistrées, prépare les trois fichiers :

```bash
git add -- MESURES_CSV_PARQUET.md \
  capture/08_comparaison_csv_parquet.png \
  capture/09_reproduction_binome.png

git diff --cached --name-status
```

Si la liste correspond à ton travail, enregistre et pousse ton commit :

```bash
git commit -m "Reproduit le pipeline et mesure la lecture CSV et Parquet" &&
git push -u origin mesures-csv-parquet
```

Sur GitHub, ouvre une **pull request** vers la branche principale du projet. Indique dans sa description si la reproduction a réussi et résume tes mesures. Si GitHub refuse le push pour une question de droits, demande à Harisoa de vérifier ton accès dans **Settings → Collaborators**.

## Contrôle final

- [ ] J’ai retrouvé 22 séquences et 333 votes pour la séquence de référence.
- [ ] Les requêtes CSV et Parquet donnent les mêmes effectifs.
- [ ] J’ai noté les tailles, les temps observés et les limites de la mesure.
- [ ] Les deux captures sont dans `capture/`, avec les noms prévus, la date, l’heure et mon identifiant Onyxia.
- [ ] Ma contribution apparaît sur GitHub sous mon identité et la pull request est prête à relire.

Le dossier de travail des images est `capture/`. Au moment du rendu, le binôme vérifie ensemble le nom `evidence/` demandé dans le sujet et actualise les références si le dossier est renommé.