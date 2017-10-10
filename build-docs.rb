#!/usr/bin/env ruby
require 'optparse'
require 'fileutils'
require 'yaml'
require 'git'

options = {}
OptionParser.new { |opts|
  opts.banner = "Usage: #{File.basename($0)} -c config.yml -t mkdocs.template.yml}"

  options[:config] = 'config.yml'
  opts.on('-f',
          '--config FILENAME',
          'Configuration file with project definition. Defaults to "config.yml"') do |config|
    options[:config] = config
  end

  options[:template] = 'mkdocs.template.yml'
  opts.on('-t',
          '--template FILENAME',
          'This file is used as template for the generated mkdocs.yaml. Defaults to "mkdocs.template.yml"') do |template|
    options[:template] = template
  end

  opts.on_tail('-h', '--help', 'Show this message') do
    puts opts
    exit
  end
}.parse!


config = YAML::load_file(options[:config])
mkdocs = YAML::load_file(options[:template])
categories = {}
mkdocs['pages'] = []

config['projects'].each do |project_name, project_config|
  puts "== #{project_name}"

  mkdocs['site_name'] = project_name

  project_dir = config['projects_dir'] + '/' + project_config['target']

  if project_config['latest']
    clone_target = project_dir + '/latest'
  elsif project_config['ref'] == 'master'
    clone_target = project_dir + '/snapshot'
  else
    clone_target = project_dir + '/' + project_config['ref'].gsub('tags/', '')
  end

  project_docs_dir = clone_target + '/' + project_config['docs_dir']
  pages = []

  if !File.directory?(clone_target)
    puts 'Cloning ...'
    FileUtils.mkdir_p(project_dir)
    repo = Git.clone(project_config['git'], clone_target)
    puts "Checkout ref '#{project_config['ref']}'"
    repo.branch(project_config['ref']).checkout
  else
    repo = Git.open(clone_target)
    repo.fetch()
    puts "Checkout ref '#{project_config['ref']}'"
    repo.branch(project_config['ref']).checkout
  end

  puts "Building page index from #{project_docs_dir}"
  Dir.glob("#{project_docs_dir}/*.md", File::FNM_CASEFOLD).sort.each do |file|
    filepath = file.gsub('projects/', '')
    filename = filepath.match(/.*(\d+)-(.*).md$/)
    header = filename[2].gsub('-', ' ').split.map(&:capitalize).join(' ')
    pages.push(header => filepath)
  end

  if project_config['category']
    categories[project_config['category']] = [] unless categories[project_config['category']]
    categories[project_config['category']].push(project_name => pages)
  else
    # MKdocs allows only 'index.md' as homepage. This is a dirty workaround to use the first markdown file instead
    FileUtils.ln_s("#{pages[0].values[0]}", 'projects/index.md', :force => true)
    mkdocs['pages'].push('' => 'index.md')

    mkdocs['pages'].push(*pages)
  end
end

if categories
  categories.each do |cat, proj|
    mkdocs['pages'].push(cat => proj)
  end
end

if mkdocs['extra']['append_pages']
  mkdocs['extra']['append_pages'].each do |name, target|
    mkdocs['pages'].push(name => target)
  end
end

File.write('mkdocs.yml', mkdocs.to_yaml)

%x( mkdocs build )
