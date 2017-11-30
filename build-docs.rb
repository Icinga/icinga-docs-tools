#!/usr/bin/env ruby
require 'optparse'
require 'fileutils'
require 'yaml'

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

def clone_and_update_project(target, clone_target, git, ref)
  @git_options = "-b #{ref}" if ref =~ /tags/
  if !File.directory?(clone_target)
    puts "Cloning #{git} to #{clone_target} ..."
    FileUtils.mkdir_p(clone_target)
    %x(git clone #{git} #{clone_target})

    puts "Checking out #{ref}"
    %x(git --git-dir=#{clone_target}/.git --work-tree=#{clone_target} checkout #{ref} #{@git_options})
  else
    puts "Cleaning up #{clone_target}"
    FileUtils::rm_rf(clone_target)
    clone_and_update_project(target, clone_target, git, ref)
  end
end

def build_page_index(full_docs_dir, project_docs_dir)
  pages = []
  puts "Building page index from #{full_docs_dir}"
  Dir.glob("#{full_docs_dir}/*.md", File::FNM_CASEFOLD).sort.each do |file|
    filepath = file.gsub(full_docs_dir + '/', project_docs_dir + '/')
    filename = filepath.match(/.*(\d+)-(.*).md$/)
    if filename
      header = filename[2].gsub('-', ' ').split.map(&:capitalize).join(' ') unless File.symlink?(filepath)
    end
    pages.push(header => filepath) if header
  end

  return pages
end

config = YAML::load_file(options[:config])
mkdocs = YAML::load_file(options[:template])
mkdocs['pages'] = []


puts "== #{config['site_name']}"

version = if config['project']['latest']
            'latest'
          elsif config['project']['ref'] == 'master'
            'snapshot'
          else
            config['project']['ref'].gsub('tags/', '')
          end

source_dir = config['source_dir'] + '/' + config['project']['target']
clone_target = source_dir + '/' + version
full_docs_dir = clone_target + '/' + config['project']['docs_dir']

clone_and_update_project(config['project']['target'], clone_target, config['project']['git'], config['project']['ref'])
main_pages = build_page_index(full_docs_dir, config['project']['docs_dir'])

# MKdocs allows only 'index.md' as homepage. This is a dirty workaround to use the first markdown file instead
#FileUtils.ln_s("#{clone_target}/#{main_pages[0].values[0]}", "#{clone_target}/index.md", :force => true)
index_file = "#{clone_target}/index.md"
FileUtils.cp("#{clone_target}/#{main_pages[0].values[0]}", index_file)
index_content = File.read(index_file)
index_new_content = index_content.gsub(/\(((?!http)\S+(\.md|\.png)(\S+)?)\)/, "(#{config['project']['docs_dir']}/\\1)")
File.open(index_file, "w") {|file| file.puts index_new_content }
mkdocs['pages'].push('' => "index.md")

if config['project']['subcategories']
  subcategories = []
  config['project']['subcategories'].each do |category, subprojects|
    subproject_pages = []
    subprojects.each do |project, config|
      if config['git']
        subproject_clone_target = clone_target + '/' + config['target']
        clone_and_update_project(project, subproject_clone_target, config['git'], config['ref'])
      end
      pages = build_page_index(clone_target + '/' + config['docs_dir'], config['docs_dir'])

      subproject_pages.push(project => pages)
    end
    subcategories.push(category => subproject_pages)
  end
end

mkdocs['site_name'] = config['site_name']
mkdocs['docs_dir'] = clone_target
mkdocs['site_dir'] = config['site_dir'] + '/' + config['project']['target'] + '/' + version
mkdocs['pages'].push(*main_pages)
mkdocs['pages'].push(*subcategories) if subcategories
File.write('mkdocs.yml', mkdocs.to_yaml)

%x( mkdocs build )