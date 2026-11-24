# Organisation du projet Star Academy

Analyse principale : taux de départ pendant chaque type de séquence du prime, à créneau comparable.
Indicateurs associés : retour pendant les prestations avec ou sans invité, jury et public sur les solos et duos, votants uniques pour 1 000 spectateurs à l’ouverture, part des replays terminés dans les 48 h.

## Sources simulées
- conducteur_primes_simule.csv
- notes_jury_simulees.csv
- sondages_public_simules.csv
- sessions_direct_simulees.csv
- fenetres_vote_simulees.csv
- votes_public_simules.csv
- sessions_replay_simulees.csv

Le conducteur identifie et date les séquences et les prestations. Ensemble, fixer les clés de jointure, les conventions horaires et le dénominateur de chaque indicateur avant de coder.

## Répartition proposée

| Jour | Toi | Ta binôme | Livrable |
|---|---|---|---|
| J1 | Contrat des données et générateur conducteur/direct | Schémas jury, sondage, vote et replay, démarrage du contrôle indépendant | Schémas communs, premières contributions |
| J2 | Génération complète, dépôt S3, traitement direct et invités | Traitements solo/duo, vote et replay | Sept CSV de 1 à 5 Mo cumulés et bilan produit sur Onyxia |
| J3 | Reproduction, README, mesure d’une alternative technique | Contrôle indépendant d’une séquence, captures et rédaction | Dépôt et PDF relus ensemble |

## Avant le rendu du 4 décembre 2026

- Dépôt public, au moins 10 vrais commits sur plusieurs jours et contributions visibles des deux personnes. Cible proposée : 4 au J1, 4 au J2 et 3 au J3. Chacun contribue sous sa propre identité Git.
- Code dans src/, captures numérotées dans evidence/, manifestes dans k8s/ si utilisés.
- Montrer le contenu S3 brut et traité ainsi qu’une trace de chaque composant. Chaque capture affiche l’identifiant Onyxia ou le namespace, la date et l’heure.
- README d’une page avec commandes vérifiées et méthode de redémarrage.
- PDF de quatre pages maximum, annexes comprises. Inclure le lien Git, le schéma des données, le diagramme du traitement, les mesures comparatives, les anomalies et leurs effectifs, les résultats, la vérification indépendante, les limites et le scénario ×100.
- Envoi par e-mail. Objet : Ecosystème Big Data II - <GrXX> - <NOM1 Prénom1> - <NOM2 Prénom2>.
