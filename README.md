# Icinga Documentation
This repository includes scripts to build the documentation for all Icinga projects.

The `build-docs.rb` script clones the configured project to a certain directory and switches to the specified
branch. It searches for `*.md` files within the configured directory and creates documentation sections out of them.
The ordering is defined by the file names. The capitalized name of each file is used as a title for this documentation
section. The generates the `mkdocs.yml` file. 

## Usage
``` bash
Usage: build-docs.rb -c config.yml -t mkdocs.template.yml}
    -f, --config FILENAME            Configuration file with project definition. Defaults to "config.yml"
    -t, --template FILENAME          This file is used as template for the generated mkdocs.yaml. Defaults to "mkdocs.template.yml"
    -h, --help                       Show this message
```

## Configuration

### `config.yml`
This file defines generally for which project documentation should be build.


General settings:

| Option        | Description                                                  |
| ------------- | ------------------------------------------------------------ |
| `site_name`   |  The `site_name` is displayed as title on the generated page |
| `source_dir'` | Target directory to store the documentation source.          |
| `site_dir`    | Target directory for generated html                          |
| `project`     | General project settings                                     |


Project settings:

| Option           | Description                                                  |
| --------------- | ------------------------------------------------------------ |
| `git`           | Git repository to clone                                                                               |
| `ref`           | Git branch or tag to checkout. For tags use `tags/v1.1.0` notation                                    |
| `target`        | A unique name to define the target. This is added to `source_dir` and `site_dir`                      |
| `docs_dir`      | Directory within the repository that includes documentation files. Eg. `doc`                          |
| `latest`        | If set to `true`, this documentation will be marked as the latest. This is important for the URLs.    |
| `subprojects`   | A project may include one ore more sub-projects.                                                      |

Subprojects are optional. They allow you to display a project documentation within another project documentation.
We need this for Icinga Web 2, Icinga Director and other projects where we summarise multiple repositories into one documentation.

Example: 

``` yaml
site_name: 'Icinga 2'
source_dir: 'www/source'
site_dir: 'www/html'
project:
  git: 'https://github.com/Icinga/icinga2.git'
  ref: 'support/2.7'
  target: 'icinga2'
  docs_dir: 'doc'
  latest: true
```

Example with subprojects:

``` yaml
site_name: 'Director'
source_dir: 'www/source'
site_dir: 'www/html'
project:
  git: 'https://github.com/Icinga/icingaweb2-module-director.git'
  ref: 'support/1.4'
  target: 'director'
  docs_dir: 'doc'
  latest: true
  subprojects:
    PuppetDB:
      git: 'https://github.com/Icinga/icingaweb2-module-puppetdb.git'
      ref: 'master'
      target: 'puppetdb'
      docs_dir: 'puppetdb/doc'
```

### `mkdocs.template.yml`
This file is used as a template for the final `mkdocs.yml`. Default settings and some other configuration options are
here.

### Run Development Server
To see a live preview of the documentation you can run a development server that will refresh automatically on changes.



Clone this repository and install dependencies:

``` bash
user@localhost ~/ $ git clone https://github.com/Icinga/icinga-docs-tools.git
user@localhost ~/ $ cd icinga-docs-tools
user@localhost ~/ $ bundle install --path vendor
```

Create and configure configuration file:

Build documentation: 

``` bash
user@localhost ~/ $ bundle exec build-docs.rb -f examples/businessprocess-latest.yml
```

Run server: 

``` bash
docker run --rm -it -p 8000:8000 -v ${PWD}:/docs squidfunk/mkdocs-material:6.1.0
```

You should be able to access the documentation now in your browser by calling the address https://localhost:8000
