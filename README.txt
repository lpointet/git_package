GIT PACKAGE
-----------
Ce script permet de g�n�rer l'arborescence des fichiers ayant �t� modifi�s entre 2 commits d'un d�p�t git (2 versions par exemple).
L'arborescence peut �tre faite sous 2 formes :
- un simple dossier
- une archive gzipp�e (.tar.gz) *

* l'archive est la sortie par d�faut

Utilisation
-----------
La seule option disponible, outre "-h" qui permet d'afficher l'aide, permet de demander le dossier simple plut�t que l'archive gzipp�e : "-d"

Ce script requiert 2 param�tres :
- le nom du dossier � cr�er (l'extension ".tar.gz" est ajout�e automatiquement dans le cas o� l'on demande une archive)
- le commit (tag, branche, sha...) de la nouvelle version qui doit �tre mise en production

2 autres param�tres peuvent �galement �tre pass�s :
- le commit (tag, branche, sha...) de l'ancienne version de l'application : par d�faut, il vaut "prod"
- le chemin vers le d�p�t git, dans le cas o� l'on ex�cute le script � partir d'un autre dossier que le d�p�t

Exemples
--------
=> Cr�ation de hotfix.tar.gz � partir de la diff�rence entre les tags "2.2.0" et "2.2.1" du d�p�t "~/webperso/eparcov2_dev/"
lionel@esox:$ ./pack.sh hotfix 2.2.0 2.2.1 ~/webperso/eparcov2_dev/

=> Cr�ation de mep.tar.gz � partir de la diff�rence entre les tags "2.2.0" et la branche "prod" du d�p�t "~/webperso/eparcov2_dev/"
lionel@esox:~/webperso/eparcov2_dev/$ ~/webperso/veille/shell/git_package/pack.sh mep 2.2.0