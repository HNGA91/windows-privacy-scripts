# windows-privacy-scripts

Scripts batch pour réduire la télémétrie et le pistage de Windows 10 / 11 (éditions Famille et Pro).

| Fichier | Rôle |
|---|---|
| `stop-telemetrie.bat` | Applique les réglages |
| `restaurer-telemetrie.bat` | Annule les réglages et revient aux valeurs par défaut |

## Utilisation

1. Ouvrir une session sur **son propre compte** (qui doit être administrateur).
2. Clic droit sur `stop-telemetrie.bat` → **Exécuter en tant qu'administrateur**.
3. Le script propose de créer un point de restauration, puis applique les réglages.
4. Il propose ensuite de redémarrer (rien n'est redémarré sans confirmation).

> Les réglages `HKCU` s'appliquent au compte qui lance le script. Si on élève les droits avec un **autre** compte administrateur, ils seront appliqués à ce compte-là.

## Ce que fait le script

| Section | Contenu |
|---|---|
| 1. Télémétrie | Niveau minimal de données de diagnostic, CEIP, télémétrie de compatibilité, rapports d'erreurs |
| 2. Confidentialité | ID de publicité, historique d'activité, presse-papiers cloud, expériences personnalisées, recherche Bing, widgets |
| 3. Recall | Stratégies anti-Recall + désinstallation de la fonctionnalité si elle existe (PC Copilot+) |
| 4. Traces locales | Documents récents, programmes lancés, Accès rapide |
| 5. Services et tâches | `DiagTrack`, `dmwappushservice`, tâches planifiées de collecte |

## Limites

- Sur Windows **Famille / Pro**, le niveau de télémétrie ne descend pas sous « Requises ».
- Les **mises à jour majeures** peuvent réactiver certains éléments : relancer le script après chacune.
- Effets secondaires : plus de rapports d'erreurs, plus de liste « les plus utilisées » dans Démarrer, Accès rapide sans éléments récents.
- Ne bloque pas le trafic réseau : pour cela, utiliser un filtre DNS (AdGuard Home, Pi-hole, NextDNS).

## Restauration

Lancer `restaurer-telemetrie.bat` en administrateur, depuis le même compte. Recall n'est pas réinstallé automatiquement (*Activer ou désactiver des fonctionnalités Windows*).

## Licence

© 2026 Louis-Hervé N'Goma — Tous droits réservés.
