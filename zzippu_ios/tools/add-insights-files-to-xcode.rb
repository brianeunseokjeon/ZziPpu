#!/usr/bin/env ruby
# tools/add-insights-files-to-xcode.rb
# 인사이트 기반 슬라이스(가이드 데이터/엔진/DS 컴포넌트)에서 추가된 새 파일을 zzippu 타겟에 등록한다.
# .swift → source build phase, .json → resources build phase.
# Usage: ruby tools/add-insights-files-to-xcode.rb

require 'xcodeproj'
require 'pathname'
require 'set'

PROJECT_PATH = File.expand_path('../zzippu.xcodeproj', __dir__)
TARGET_NAME  = 'zzippu'
ZZIPPU_ROOT  = File.expand_path('../zzippu', __dir__)

SOURCE_FILES = %w[
  Domain/Entities/PediatricGuideline.swift
  Domain/Entities/DomainInsight.swift
  Domain/Repositories/GuidelineRepository.swift
  Domain/UseCases/EvaluateInsightsUseCase.swift
  Data/Content/BundleGuidelineRepository.swift
  Shared/DesignSystem/Components/Feedback/DSDisclaimerCaption.swift
  Shared/DesignSystem/Components/Lists/InsightRow.swift
  Shared/DesignSystem/Components/Containers/AnalysisCard.swift
  Shared/DesignSystem/Components/Media/RangeBandChart.swift
].freeze

RESOURCE_FILES = %w[
  Shared/Resources/Guidelines/pediatric_guidelines.json
  Shared/Resources/Guidelines/who_growth_weight_boy.json
  Shared/Resources/Guidelines/who_growth_weight_girl.json
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

def registered_paths(build_phase, root)
  set = Set.new
  build_phase.files.each do |f|
    next unless f.file_ref
    path = f.file_ref.real_path.to_s
    rel  = Pathname.new(path).relative_path_from(Pathname.new(root)).to_s rescue nil
    set << rel if rel
  end
  set
end

already_src = registered_paths(target.source_build_phase, ZZIPPU_ROOT)
already_res = registered_paths(target.resources_build_phase, ZZIPPU_ROOT)

added = []

register = lambda do |rel_path, build_phase, already|
  if already.include?(rel_path)
    puts "  skip (already registered): #{rel_path}"
    return
  end
  abs_path = File.join(ZZIPPU_ROOT, rel_path)
  unless File.exist?(abs_path)
    puts "  WARN file not found: #{abs_path}"
    return
  end

  parts    = rel_path.split('/')
  filename = parts.pop
  group    = find_or_create_group(zzippu_group, parts)

  existing_ref = group.children.find { |c| c.is_a?(Xcodeproj::Project::Object::PBXFileReference) && c.path == filename }
  file_ref = existing_ref || group.new_file(abs_path)

  unless build_phase.files.any? { |f| f.file_ref == file_ref }
    build_phase.add_file_reference(file_ref)
    puts "  added: #{rel_path}"
    added << rel_path
  else
    puts "  skip (in build phase): #{rel_path}"
  end
end

SOURCE_FILES.each   { |p| register.call(p, target.source_build_phase,    already_src) }
RESOURCE_FILES.each { |p| register.call(p, target.resources_build_phase, already_res) }

if added.empty?
  puts 'No new files to add.'
else
  project.save
  puts "\nSaved project. Added #{added.size} file(s)."
end
