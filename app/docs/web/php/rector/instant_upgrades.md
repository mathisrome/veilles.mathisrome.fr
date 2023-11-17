---
sidebar_position: 5
---

# Mise à jour instantanée

Pour cette partie, je vais montrer des exemples avec Symfony, parce que c'est le Framework que je connais le mieux.

Imaginons que vous avez un projet en Symfony 6.1 et que nous voulons passer en Symfony 6.2.

## Installation et utilisation du projet

### Télécharger
Vous trouverez ci-dessous la commande permettant de télécharger le projet d'exemple :

```bash
git clone --branch no-rector https://github.com/mathisrome/veille-rector.git
```

:::info

La commande ci-dessus, vous renvoie directement sur la version où Rector n'est pas installé, 
vous pouvez suivre les indications ci-dessous sans problème

:::

### Lancer le projet

:::info

Pour lancer le projet, il faudra Docker d'installé !

:::

Pour lancer le projet utiliser la commande suivante : 

```bash
docker compose up -d
```

:::info

Pour la suite des explications, vous aurez besoin d'exécuter les commandes dans le container
php qui a été créé par la commande `docker compose up -d`.

Afin de rentrer dans le container utiliser la commande `docker compose exec php /bin/bash`

:::

Installer toutes les dépendances nécéssaires en utilisant les commandes suivantes :

```bash
composer install && yarn install && yarn build
```

Une fois la commande terminée, vous pourrez [accéder à l'applicaiton](http://localhost)

## Mise en place de Rector

À présent, nous allons installer Rector avec la commande : 

```bash
composer require rector/rector --dev
```

Une fois l'installation terminée, nous pourrons créer le fichier de configuration de Rector 
en utilisant la commande suivante :

```bash
vendor/bin/rector
```

Le fichier suivant a été créé dans le dossier `app` de notre projet :

```php title="app/rector.php"
<?php

declare(strict_types=1);

use Rector\CodeQuality\Rector\Class_\InlineConstructorDefaultToPropertyRector;
use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\LevelSetList;

return static function (RectorConfig $rectorConfig): void {
    $rectorConfig->paths([
        __DIR__ . '/config',
        __DIR__ . '/public',
        __DIR__ . '/src',
        __DIR__ . '/tests',
    ]);

    // register a single rule
    $rectorConfig->rule(InlineConstructorDefaultToPropertyRector::class);

    // define sets of rules
    //    $rectorConfig->sets([
    //        LevelSetList::UP_TO_PHP_81
    //    ]);
};
```

Maintenant, nous allons modifier ce fichier afin que les fichiers dans 
le dossier `app/src` soit automatiquement adaptés aux bonnes pratiques de Symfony 6.3

```php title="app/rector.php"
<?php

declare(strict_types=1);

use Rector\CodeQuality\Rector\Class_\InlineConstructorDefaultToPropertyRector;
use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Symfony\Set\SymfonySetList;
use Rector\Symfony\Symfony62\Rector\MethodCall\SimplifyFormRenderingRector;

return static function (RectorConfig $rectorConfig): void {
    // Permet de définir tous les chemins que doit parcourir Rector
    $rectorConfig->paths([
        __DIR__ . '/src',
    ]);

    // register a single rule
    // Symplify form rendering by not calling ->createView() on render function
    $rectorConfig->rule(SimplifyFormRenderingRector::class);

    $rectorConfig->symfonyContainerXml(__DIR__ . '/var/cache/dev/App_KernelDevDebugContainer.xml');

    // define sets of rules
    $rectorConfig->sets([
        SymfonySetList::SYMFONY_63,
        SymfonySetList::SYMFONY_CODE_QUALITY,
    ]);
};

```

Rector est prêt à être utilisé, pour monter de versions les fichiers, faites la commande suivante :

```bash
vendor/bin/rector --dry-run
```

Comme dit précédemment la commande avec l'option `--dry-run` affiche les fichiers modifiés sans les sauvegarder.

Comme vous pouvez le voir Rector modifiera automatiquement le nom de la méthode du `ContactController.php`
pour ne plus appliquer le suffixe `Action` qui n'est plus une bonne pratique.

Il supprimera aussi la méthode `createView()` du formulaire qui n'est plus necéssaire 
depuis la version 6.2 de Symfony.

Afin d'appliquer les modifications, vous pouvez relancer la commande sans l'option `--dry-run` :

```bash
vendor/bin/rector
```

Nous venons de voir une des manipulations minimales de Rector, pour en savoir plus sur toutes les règles
applicables pour un projet Symfony [cliquer ici](https://github.com/rectorphp/rector-symfony).