#!/usr/bin/env ruby
require 'fileutils'
require 'yaml'
require 'git'

config = YAML::load_file('config.yml')
mkdocs = YAML::load_file('mkdocs.template.yml')

config['projects'].each do |project_name, project_config|
  puts "== #{project_name}"

  project_dir = config['projects_dir'] + '/' + project_config['target']

  if project_config['latest'] == true
    clone_target = project_dir + '/latest'
  else
    clone_target = project_dir + '/' + project_config['ref'].gsub('tags/', '')
  end

  project_docs_dir = clone_target + '/' + project_config['docs_dir']
  pages = []

  if File.directory?(clone_target)
    puts 'Project already exists, cleaning up'
    FileUtils.rm_rf(clone_target)
  end

  puts 'Cloning ...'
  FileUtils.mkdir_p(project_dir)
  repo = Git.clone(project_config['git'], clone_target)

  puts "Switching to ref '#{project_config['ref']}'"
  repo.branch(project_config['ref']).checkout

  puts 'Cleaning up everything not related to docs'
  Dir::foreach(clone_target) do |file|
    next if(file == project_config['docs_dir'])
    next if(file == '.' || file == '..')
    FileUtils.rm_rf(clone_target + '/' + file)
  end

  puts "Building page index from #{project_docs_dir}"
  Dir.glob("#{project_docs_dir}/*.md", File::FNM_CASEFOLD).sort.each do |file|
    filepath = file.gsub('projects/', '')
    filename = filepath.match(/(\d+)-(.*).md$/)
    header = filename[2].gsub('-', ' ').split.map(&:capitalize).join(' ')
    pages.push(header => filepath)
  end
  mkdocs['pages'].push(project_name => pages)

end

mkdocs['extra']['append_pages'].each do |name, target|
  mkdocs['pages'].push(name => target)
end

File.write('mkdocs.yml', mkdocs.to_yaml)

%x( mkdocs build )