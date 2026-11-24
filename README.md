# Star Academy — Comment programmer un prime qui retient le public ?

## Auteurs
- [NOM Prénom]
- [NOM Prénom]

## Prérequis
Git, Python/uv, accès Onyxia et S3. Service PySpark et mode d’exécution à confirmer.

## Jeu de données
Primes fictifs inspirés de la Star Academy, générés par le projet. Source et URL du générateur, licence, date de génération et taille exacte à renseigner. Taille brute cumulée attendue : 1 à 5 Mo.

## Problématique
Quels formats et moments du prime retiennent le mieux le public en direct, l’incitent à voter et lui donnent envie de regarder le replay ?

## Chemins S3
Brut : `s3://<bucket>/star-academy/raw/`.
Traité : `s3://<bucket>/star-academy/processed/`.

## Reproduction
À compléter après implémentation avec les commandes vérifiées : générer les CSV, mesurer leur taille, les déposer sur S3, lancer PySpark sur Onyxia, vérifier un résultat et publier le tableau final. Documenter le redémarrage et les dépendances.
