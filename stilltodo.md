# Checklist du projet Star Academy

**Titre** — Star Academy : comment programmer un prime qui retient le public ?  
**Question** — Quels formats et moments du prime retiennent le mieux le public en direct, l’incitent à voter et sont les plus regardés jusqu’au bout en replay ?  
**Analyse principale** — Le taux de départ du direct par type de séquence, à créneau comparable.  
**Date limite** — Vendredi 4 décembre 2026.

## 1. Dépôt et répartition

- [x] Créer le dépôt GitHub [Projet-Big-Data](https://github.com/HarisoaR27/Projet-Big-Data).
- [ ] Vérifier la visibilité **Public** et inviter le deuxième membre du binôme dans **Settings → Collaborators**.
- [ ] Vérifier que chacun peut cloner le dépôt et pousser un commit sous sa propre identité GitHub.
- [ ] Vérifier les dossiers `src/` pour le code et `evidence/` pour les captures. Ajouter `k8s/` si des manifestes Kubernetes sont utilisés.
- [ ] Valider la répartition ci-dessous et ajuster les responsables si besoin.

| Quand | Membre A | Membre B | Résultat commun |
|---|---|---|---|
| Jour 1 | Définir le conducteur et les sessions direct | Définir les fichiers jury, sondages, votes et replay | Fichiers, clés et règles approuvés ensemble |
| Jour 2 | Générer le conducteur et le direct, déposer les données sur S3, traiter le direct et les invités | Générer les cinq autres CSV et traiter solo/duo, votes et replay | Premier bilan sur Onyxia |
| Jour 3 | Rejouer le pipeline, mesurer une alternative technique et finaliser le README | Vérifier une séquence indépendamment, assembler les captures et rédiger le PDF | Relecture croisée et rendu prêt |

- [ ] Faire **au moins 10 commits de travail réel sur plusieurs jours**, avec des contributions visibles des deux membres. Cible proposée : 4 au jour 1, 4 au jour 2, 3 au jour 3. Exemples : schémas, génération, traitement direct, traitement des autres indicateurs, contrôle, mesures, preuves, documentation.

## 2. Définir et générer les données

- [ ] Fixer ensemble les identifiants (`prime_id`, `sequence_id`, `prestation_id`, `candidat_id`, `spectateur_id` selon le fichier), le fuseau horaire et la règle d’attribution aux séquences. Utiliser des intervalles **début inclus, fin exclue** et définir une règle pour les départs et retours multiples.
- [ ] Générer plusieurs primes fictifs avec différents créneaux, types de séquences et formats. Prévoir des comparaisons effectivement possibles, par exemple des solos et des duos pour un même candidat et un même style musical.
- [ ] Versionner dans `src/` le ou les scripts Python de génération avec une graine fixe. Décrire le schéma et la provenance des données simulées.

| Fichier brut | À générer |
|---|---|
| `conducteur_primes_simule.csv` | Séquences horodatées par prime, type de séquence, prestation, candidats, style, format et présence d’un invité. Définir comment plusieurs candidats sont rattachés à une prestation. |
| `sessions_direct_simulees.csv` | Une ligne par session d’un spectateur fictif, avec son arrivée et son départ du direct. Autoriser plusieurs sessions pour simuler les retours. |
| `notes_jury_simulees.csv` | Une note par juré, candidat et prestation. |
| `sondages_public_simules.csv` | Une note par spectateur, candidat et prestation. |
| `fenetres_vote_simulees.csv` | Heure d’ouverture et de fermeture de chaque fenêtre, identifiée dans son prime. |
| `votes_public_simules.csv` | Votes horodatés, rattachés à une fenêtre, un votant fictif et un candidat. |
| `sessions_replay_simulees.csv` | Visionnages horodatés, rattachés à une prestation, avec durée vue et durée totale. Prévoir l’heure de publication de la prestation dans le conducteur. |

- [ ] Générer quelques cas contrôlés à détecter, par exemple doublons, sessions dont la fin précède le début et votes hors fenêtre. Relever ensuite les anomalies réellement détectées et le nombre de lignes concernées.
- [ ] Mesurer le poids **cumulé des sept CSV bruts**, entre **1 et 5 Mo**, par exemple avec `wc -c data/raw/*.csv`. Documenter le total exact, la date de génération et la licence retenue.

## 3. Stocker et exécuter sur Onyxia

- [ ] Vérifier l’accès au bucket S3 Onyxia ainsi qu’au service PySpark. Confirmer le mode d’exécution attendu par l’enseignante pour la preuve sur le cluster.
- [ ] Déposer les sept CSV dans `s3://<bucket>/star-academy/raw/`. Utiliser la configuration du TP S3 et lister les objets après transfert.
- [ ] Lire les données depuis S3 dans le pipeline. Si le service du TP utilise des fichiers locaux, documenter la copie depuis S3 vers la session Onyxia, puis le transfert du résultat vers S3.
- [ ] Dans Spark, typer les dates et les notes, appliquer les règles de nettoyage, comptabiliser les lignes rejetées et repérer les identifiants sans correspondance.
- [ ] Agréger les sources à la bonne granularité avant les jointures. Par exemple, calculer les notes du jury et du public séparément par candidat et prestation avant de les rapprocher.

| À cocher | Indicateur | Calcul à implémenter |
|---|---|---|
| ☐ | Départs du direct | Pour chaque séquence, rapporter les spectateurs présents au début qui quittent pendant la séquence aux spectateurs présents au début. Comparer les taux par type de séquence et créneau. |
| ☐ | Retours et invités | Parmi les spectateurs ayant déjà quitté le direct et absents au début de la prestation, calculer la part qui revient pendant celle-ci. Comparer avec et sans invité dans des créneaux comparables. |
| ☐ | Solo et duo | Comparer séparément les notes moyennes du jury et du public pour les candidats ayant chanté dans les deux formats, à style musical comparable. |
| ☐ | Participation au vote | Compter les votants uniques par fenêtre, puis rapporter le nombre à 1 000 spectateurs présents à l’ouverture. Comparer des fenêtres de même durée. |
| ☐ | Replay | Parmi les visionnages démarrés dans les 48 h suivant la publication, calculer la part regardée jusqu’au bout par format de prestation. |

- [ ] Exécuter le pipeline sur Onyxia et déposer le bilan d’analyse dans `s3://<bucket>/star-academy/processed/`. Afficher les effectifs avec les taux. Pour un dénominateur nul, afficher une valeur manquante.
- [ ] Rejouer le pipeline depuis une session propre. Vérifier le résultat et documenter comment relancer le traitement sans dupliquer les sorties.
- [ ] Mesurer une alternative technique. Exemple : écrire le même tableau intermédiaire en CSV et Parquet, comparer les tailles et chronométrer la même agrégation à la relecture sur le même service. Conserver les mesures dans le rapport et justifier le choix final.

## 4. Vérifier et capturer les preuves

- [ ] Recalculer indépendamment le taux de départ d’une séquence à partir du conducteur et des sessions brutes, avec un script Python séparé dans `src/`. Comparer les **deux effectifs** et le taux avec Spark.
- [ ] Capturer le contenu S3 pour le brut et le traité. Capturer une trace d’exécution de **chaque composant utilisé**.
- [ ] Vérifier que chaque capture affiche **l’identifiant Onyxia ou le namespace, la date et l’heure**. Numéroter les fichiers dans `evidence/` et les référencer dans le rapport. Vérifier que les captures destinées au dépôt public ne montrent aucun secret.

## 5. Finaliser et rendre

- [ ] Limiter le `README.md` à **une page** et respecter l’ordre demandé : auteurs (noms, prénoms), prérequis, données (nom, URL ou lien vers le générateur, licence, date, taille), problématique en trois phrases maximum, chemins S3, commandes de reproduction et méthode de redémarrage. Documenter l’accès aux dépendances et aux données.
- [ ] Préparer le **PDF de quatre pages maximum, annexes comprises**.
  1. Problématique, données, source, justification, taille, schéma et lien Git.
  2. Diagramme du pipeline, choix techniques, alternative et mesures.
  3. Qualité des données, exemples et nombres de lignes touchées, résultats et vérification indépendante.
  4. Limites de la simulation, effets attendus sur les résultats et le traitement avec **100 fois plus de données**, références des preuves.
- [ ] Vérifier en binôme le PDF, l’accès public au dépôt et l’historique des contributions.
- [ ] Envoyer le PDF par e-mail avant le **4 décembre 2026**. Objet : `Ecosystème Big Data II - <GrXX> - <NOM1 Prénom1> - <NOM2 Prénom2>`.
