#!/usr/bin/env ruby
require 'optparse'
require 'fileutils'
require 'yaml'
require 'date'

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

def cleanup_and_clone(target, clone_target, git, ref)
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
    cleanup_and_clone(target, clone_target, git, ref)
  end
end

def titleize(string)
  # Remove .md
  title = string.gsub('.md', '')

  # Remove numbering on the front
  title = title.gsub(/^\d+-/, '')

  # Remove dashes and underscores
  title = title.gsub(/(-|_)/, ' ')

  # Uppercase only first letter of each word, ignore stopwords
  stopwords = ['and', 'or', 'to', 'by', 'on', 'with', 'is', 'at', 'of', 'from', 'for']
  title = title.split.map { |word|
    if stopwords.include?(word)
      word
    else
      word[0].upcase + word[1..-1]
    end
  }.join(" ")

  return title
end

def build_page_index(full_docs_dir, project_docs_dir)
  pages = []
  puts "Building page index from #{full_docs_dir}"

  Dir.glob("#{full_docs_dir}/**", File::FNM_CASEFOLD).sort.each do |file|
    next if !file.match(/.*(\d+)-(.*)$/)

    filepath = file.gsub(full_docs_dir + '/', project_docs_dir + '/')
    filename = filepath.match(/.*(\d+)-(.*)$/)

    if(File.directory?("#{file}"))
      subdirectory = []
      nav_item = titleize(filename[2]) unless File.symlink?(filepath)
  
      Dir.glob("#{file}/*.md", File::FNM_CASEFOLD).sort.each do |subfile|
        subfile_path = subfile.gsub(full_docs_dir + '/', project_docs_dir + '/')
        subfile_name = subfile.match(/.*(\d+)-(.*)$/)
  
        header = titleize(subfile_name[2]) unless File.symlink?(subfile)
        subdirectory.push(header => subfile_path) if header
      end
  
      pages.push(nav_item => subdirectory) if nav_item
    else  
      header = titleize(filename[2]) unless File.symlink?(filepath)
      pages.push(header => filepath) if header
    end
  end

  return pages
end

def get_events(git, source_dir, categories)
  events = []
  event_categories = categories
  clone_target = source_dir + '/events'
  cleanup_and_clone('events', clone_target, git, 'master')
  event_categories.each do |category|
    category_events = YAML::load_file(clone_target + '/' + category + '.yml')
    if category_events
      category_events_sorted = category_events.sort_by { |k| k['date'] }
      category_events_sorted.each do |event|
        if event['date'] > Date.today
          events << event
          break
        else
          next
        end
      end
    end
  end

  events_sorted = events.sort_by { |k| k['date']}

  events_sorted.each do |k|
    k['date'] = Date::ABBR_MONTHNAMES[k['date'].month]
  end

  return events_sorted
end

config = YAML::load_file('config.yml')
project_config = YAML::load_file(options[:config])
mkdocs = YAML::load_file(options[:template])
mkdocs['nav'] = []



puts "== #{project_config['site_name']}"

version = if project_config['project']['latest']
            'latest'
          elsif project_config['project']['ref'] == 'master'
            'snapshot'
          else
            project_config['project']['ref'].gsub('tags/', '')
            project_config['project']['ref'].gsub('support/', '')
          end

source_dir = project_config['source_dir'] + '/' + project_config['project']['target']
clone_target = source_dir + '/' + version
full_docs_dir = clone_target + '/' + project_config['project']['docs_dir']

cleanup_and_clone(project_config['project']['target'],
                  clone_target,
                  project_config['project']['git'],
                  project_config['project']['ref'])

main_pages = build_page_index(full_docs_dir, project_config['project']['docs_dir'])
# MKdocs allows only 'index.md' as homepage. This is a dirty workaround to use the first markdown file instead
#FileUtils.ln_s("#{clone_target}/#{main_pages[0].values[0]}", "#{clone_target}/index.md", :force => true)
index_file = "#{clone_target}/index.md"
FileUtils.cp("#{clone_target}/#{main_pages[0].values[0]}", index_file)
index_content = File.read(index_file)
index_new_content = index_content.gsub(/\(((?!http)\S+(\.md|\.png)(\w)?)/,
                                       "(#{project_config['project']['docs_dir']}/\\1")

File.open(index_file, "w") {|file| file.puts index_new_content }
mkdocs['nav'].push('' => "index.md")

if project_config['project']['subprojects']
  subproject_navigation = []

  project_config['project']['subprojects'].each do |subproject|

    if subproject[1]['git']
      subproject_clone_target = clone_target + '/' + subproject[1]['target']
      cleanup_and_clone(subproject[1], subproject_clone_target, subproject[1]['git'], subproject[1]['ref'])
    end

    subproject_navigation.push(subproject[0] => build_page_index(clone_target + '/' + subproject[1]['docs_dir'], subproject[1]['docs_dir']))
  end
end

mkdocs['site_name'] = project_config['site_name']
mkdocs['docs_dir'] = clone_target
mkdocs['site_dir'] = project_config['site_dir'] + '/' + project_config['project']['target'] + '/' + version
mkdocs['repo_url'] = project_config['project']['git'].gsub('.git', '').downcase
mkdocs['nav'].push(*main_pages)
mkdocs['nav'].push(*subproject_navigation) if subproject_navigation
#mkdocs['extra']['events'] = get_events(config['events']['git'],
#                                       config['events']['source_dir'],
#                                       config['events']['categories'])

File.write('mkdocs.yml', mkdocs.to_yaml)
%x(mkdocs build)
