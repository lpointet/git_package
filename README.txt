GIT PACKAGE
-----------
Ce script permet de générer l'arborescence des fichiers ayant été modifiés entre 2 commits d'un dépôt git (2 versions par exemple).
L'arborescence peut être faite sous 2 formes :
- un simple dossier
- une archive gzippée (.tar.gz) *

* l'archive est la sortie par défaut

Utilisation
-----------
La seule option disponible, outre "-h" qui permet d'afficher l'aide, permet de demander le dossier simple plutôt que l'archive gzippée : "-d"

Ce script requiert 2 paramètres :
- le nom du dossier à créer (l'extension ".tar.gz" est ajoutée automatiquement dans le cas où l'on demande une archive)
- le commit (tag, branche, sha...) de la nouvelle version qui doit être mise en production

2 autres paramètres peuvent également être passés :
- le commit (tag, branche, sha...) de l'ancienne version de l'application : par défaut, il vaut "prod"
- le chemin vers le dépôt git, dans le cas où l'on exécute le script à partir d'un autre dossier que le dépôt

Exemples
--------
=> Création de hotfix.tar.gz à partir de la différence entre les tags "2.2.0" et "2.2.1" du dépôt "~/webperso/eparcov2_dev/"
lionel@esox:$ ./pack.sh hotfix 2.2.0 2.2.1 ~/webperso/eparcov2_dev/

=> Création de mep.tar.gz à partir de la différence entre les tags "2.2.0" et la branche "prod" du dépôt "~/webperso/eparcov2_dev/"
lionel@esox:~/webperso/eparcov2_dev/$ ~/webperso/veille/shell/git_package/pack.sh mep 2.2.0