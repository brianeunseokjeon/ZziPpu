#!/usr/bin/env ruby
# tools/add-t6-files-to-xcode.rb
# T6 슬라이스(홈 타임라인 기록 편집: RecordEditSheet)에서 추가된 새 파일을 zzippu 타겟에 등록한다.
# Usage: ruby tools/add-t6-files-to-xcode.rb

require 'xcodeproj'
require 'pathname'
require 'set'

PROJECT_PATH = File.expand_path('../zzippu.xcodeproj', __dir__)
TARGET_NAME  = 'zzippu'
ZZIPPU_ROOT  = File.expand_path('../zzippu', __dir__)

NEW_FILES = %w[
  Feature/Recording/RecordEditSheet.swift
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
    cur = existing || cur.new_group(seg, seg)
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
  group      = find_or_create_group(zzippu_group, parts)

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
