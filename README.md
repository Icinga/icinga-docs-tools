# Icinga Documentation
This repository includes everything for building the documentation for all tools in the Icinga ecosystem.

The `build-docs.rb` script clones each configured project to the specified directory and switches to the specified
branch. It searches for `*.md` files within the configured directory and creates documentation sections out of the found
files. The ordering is defined by the file names. The capitalized name of each file is used as a title for this documentation
section. The script will generate the `mkdocs.yml` 

## Configuration

### `config.yml`
This file defines generally for which projects documentation should be build. All settings are required.

| Option         | Description                                                             |
| -------------  | ----------------------------------------------------------------------- |
| `projects_dir` | Directory where all projects are stored                                 |
| `projects`     | Array of projects                                                       |
| `git`          | Git repository                                                          |
| `ref`          | Branch or Tag to check out                                              |
| `latest`       | If set to `true`, the project will be cloned into a `latest` directory. |
| `target`       | Target directory within `projects_dir`                                  |
| `docs_dir`     | Directory that includes the `*.md` files                                |
| `category`     | If set, the projects will be displayed under this category              | 


Example: 

``` yaml
projects_dir: 'projects'
projects:
  Icinga 2:
    git: 'https://github.com/Icinga/icinga2.git'
    ref: 'tags/v2.6.3'
    target: 'icinga2'
    docs_dir: 'doc'
  Icinga Web 2:
    git: 'https://github.com/Icinga/icingaweb2.git'
    ref: 'tags/v2.4.1'
    target: 'icingaweb2'
    docs_dir: 'doc'
```

### `mkdocs.template.yml`
This file is used as a template for the final `mkdocs.yml`. Default settings and some other configuration options are
here.

### Run Development Server
To see a live preview of the documentation you can run a development server that will refresh automatically on changes.


Install `mkdocs` and the `material` theme:

``` bash
user@localhost ~/ $ pip install mkdocs
user@localhost ~/ $ pip install mkdocs-material
```

Clone this repository and install dependencies:

``` bash
user@localhost ~/ $ git clone https://github.com/Icinga/icinga-docs-tools.git
user@localhost ~/ $ cd icinga-docs-tools
user@localhost ~/ $ bundle install
user@localhost ~/ $ bundle exec build-docs.rb
```

Run server: 

``` bash
user@localhost ~/ $ mkdocs serve
```

You should be able to access the documentation now in your browser by calling the address https://localhost:8000