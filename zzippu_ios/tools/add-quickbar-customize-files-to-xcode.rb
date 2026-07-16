#!/usr/bin/env ruby
# tools/add-quickbar-customize-files-to-xcode.rb
# 빠른기록 커스터마이즈 신규 Swift 파일을 zzippu 타겟에 등록.
# Usage: ruby tools/add-quickbar-customize-files-to-xcode.rb

require 'xcodeproj'
require 'pathname'

PROJECT_PATH = File.expand_path('../zzippu.xcodeproj', __dir__)
TARGET_NAME  = 'zzippu'
ZZIPPU_ROOT  = File.expand_path('../zzippu', __dir__)

NEW_FILES = %w[
  Feature/Home/QuickAction.swift
  Feature/Home/QuickBarSettings.swift
  Feature/Home/QuickBarEditSheet.swift
].freeze

project = Xcodeproj::Project.open(PROJECT_PATH)
target  = project.targets.find { |t| t.name == TARGET_NAME }
raise "Target '#{TARGET_NAME}' not found" unless target

zzippu_group = project.main_group.find_subpath('zzippu', false)
raise 'zzippu group not found in project' unless zzippu_group

def find_or_create_group(parent, components)
  cur = parent
  components.each do |seg|
    existing = cur.children.find { |c| c.is_a?(Xcodeproj::Project::Object::PBXGroup) && c.name == seg }
    if existing
      cur = existing
    else
      cur = cur.new_group(seg, seg)
    end
  end
  cur
end

already = Set.new
target.source_build_phase.files.each do |f|
  next unless f.file_ref
  path = f.file_ref.real_path.to_s
  rel  = Pathname.new(path).relative_path_from(Pathname.new(ZZIPPU_ROOT)).to_s rescue nil
  already << rel if rel
end

added = []
NEW_FILES.each do |rel_path|
  if already.include?(rel_path)
    puts "  skip (already registered): #{rel_path}"
    next
  end

  abs_path = File.join(ZZIPPU_ROOT, rel_path)
  unless File.exist?(abs_path)
    puts "  WARN file not found: #{abs_path}"
    next
  end

  parts      = rel_path.split('/')
  filename   = parts.pop
  group_path = parts

  group = find_or_create_group(zzippu_group, group_path)

  existing_ref = group.children.find { |c| c.is_a?(Xcodeproj::Project::Object::PBXFileReference) && c.path == filename }
  file_ref = existing_ref || group.new_file(abs_path)

  unless target.source_build_phase.files.any? { |f| f.file_ref == file_ref }
    target.source_build_phase.add_file_reference(file_ref)
    puts "  added: #{rel_path}"
    added << rel_path
  else
    puts "  skip (in build phase): #{rel_path}"
  end
end

if added.empty?
  puts 'No new files to add.'
else
  project.save
  puts "\nSaved project. Added #{added.size} file(s)."
end
