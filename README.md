# Carnet de nounou

L'appli partagée entre Aurélie et Marine pour la garde de Lola.

**L'appli :** https://carnet-nounou.github.io/  
**Démo sans compte (rien n'est partagé) :** https://carnet-nounou.github.io/?demo

## Ce que l'appli propose
- **Tableau de bord** : la photo de Lola, la journée d'aujourd'hui, « La journée de Lola » (photo du jour, repas, sieste, humeur, petit mot), les évènements à venir et le récap du mois.
- **Agenda** : statut de chaque jour (travaillé, non travaillé, congé payé, maladie, absence enfant, congé exceptionnel, férié, anniversaire, repos), horaires réels, cahier de liaison en pictos, petit mot, photos et évènements (anniversaire, Halloween, Noël…).
- **Salaire** : jours travaillés, heures réelles, absences, salaire mensualisé, indemnités d'entretien et total indicatif ; récap à copier ; tableau de l'année de contrat.
- **Documents** : galerie photos, papiers (arrêts maladie, autorisations, attestations…) et contrat.
- **Couleurs** : 6 thèmes et une couleur personnalisée, choisis sur chaque téléphone.
- **Installable** sur l'écran d'accueil.

## Accès et sécurité
- Connexion par code reçu par e-mail. Seules les adresses listées dans la table `membres` peuvent entrer.
- Rôles : `parent` (peut modifier le contrat) et `nounou`.
- Photos et documents dans un espace de stockage **privé** : ils ne sont visibles que par les membres connectés, via des liens temporaires.

## Base de données (Supabase)
Script complet : `supabase/schema.sql` (tables, règles d'accès, stockage, reprise du tableau Excel).

Ajouter ou changer une personne : Supabase → Table Editor → `membres`.

Conception : Estelle Lavenac
