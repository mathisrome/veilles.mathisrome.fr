---
sidebar_position: 4
description: Découvrez comment fonctionne Rector
---

# Comment ça marche ?

## Recherche de tous les fichiers et charge les recteurs configurés

Rector récupère tous les fichiers dans les différents chemins qu'on lui fournit
et fait appel à tous les `recteurs` qu'on lui a demandé dans le fichier de configuration
`rector.php` ou directement dans la ligne de commande avec l'option `--config`

Dans ce contexte un `recteur` est une classe qui permet de modifié une seule chose (ex: changer le nom d'une classe)

## Analyse et reconstruction du fichier

L'itération des fichiers, des nœuds et des recteurs respecte ce cycle de vie :

```php
<?php

declare(strict_types=1);

use Rector\Contract\Rector\PhpRectorInterface;
use PhpParser\Parser;

/** @var SplFileInfo[] $fileInfos */
foreach ($fileInfos as $fileInfo) {
    // 1 file => nodes
    /** @var Parser $phpParser */
    $nodes = $phpParser->parse(file_get_contents($fileInfo->getRealPath()));

    // nodes => 1 node
    foreach ($nodes as $node) { // rather traverse all of them
        /** @var PhpRectorInterface[] $rectors */
        foreach ($rectors as $rector) {
            foreach ($rector->getNodeTypes() as $nodeType) {
                if (is_a($node, $nodeType, true)) {
                    $rector->refactor($node);
                }
            }
        }
    }
}
```

:::info
Ce fichier provient de la [documentation de Rector](https://getrector.com/documentation/how-rector-works)
:::

### Phase préparation

Les fichiers sont analysés par le bundle `nikic/php-parser`,
celui-ci prend en charge l'écriture et la modification de l'arbre du fichier analysé.

Ensuite les nœuds (les nœuds sont une liste d'objets récupérés par la librairie) sont
parcourus par `StandaloneTraverseNodeTraverser` pour préparées les métadonnées à modifier
(ex : le nom de la classe, l'espace de nom, etc...)
Toutes ces métadonnées sont ajoutées par la méthode `$node->setAttribute("key","value")`

### Phase de rectification

Une fois que tous les nœuds sont prêts, Rector boucle sur tous les `recteurs` actifs.
Chaque nœud est comparé avec la méthode `$rector->getNodeTypes()` pour vérifier si ce `recteur`
doit rectifier quelque chose sur ce nœud.
Si aucune rectification n'est à appliquer sur ce nœud alors, on passe au nœud suivant sinon
on ferra appel à la méthode `$rector->refactor($node)` et le recteur actif modifie et renvoie les nœuds modifiés.

### Ordre des `recteurs`

Les nœuds identifiés par `Rector`, vont être ensuite itérés dans l'ordre afin d'exécuter les `recteurs`. 
Par exemple les recteurs pour le nœud `Class_` sont toujours exécutés 
avant les `recteurs` pour `ClassMethod` dans une classe.

Les `recteurs` sont ensuite exécutés dans l'ordre de la configuration.

### Phase d'enregistrement ou d'identification des différences

Lorsque Rector a appliqué tous les `recteurs` sur un fichier, 
celui-ci sera renregistré si des changements ont été effectués.

Cependant, si l'option `--dry-run` a été utilisée alors, il enregistrera la différence, 
mais aucun changement ne sera appliqué.

## Rapport des modifications

Une fois toutes ces étapes effectuées, Rector affichera la liste de tous les fichiers modifiés 
ainsi que les modifications appliquées.

Mais encore une fois, si l'option `--dry-run` est appliquée, 
Rector se contentera d'afficher les modifications