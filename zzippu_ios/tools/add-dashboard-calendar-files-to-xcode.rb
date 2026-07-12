#!/usr/bin/env ruby
# tools/add-dashboard-calendar-files-to-xcode.rb
# 대시보드 달력 기능(S1~S6) 신규 Swift 파일을 zzippu 타겟에 등록.
# Usage: ruby tools/add-dashboard-calendar-files-to-xcode.rb

require 'xcodeproj'
require 'pathname'
require 'set'

PROJECT_PATH = File.expand_path('../zzippu.xcodeproj', __dir__)
TARGET_NAME  = 'zzippu'
ZZIPPU_ROOT  = File.expand_path('../zzippu', __dir__)

NEW_FILES = %w[
  Domain/Entities/Calendar/CalendarDayDecoration.swift
  Domain/Entities/Calendar/MonthCalendarModel.swift
  Domain/Entities/Calendar/DateVolume.swift
  Domain/UseCases/Calendar/CalendarDecorationProvider.swift
  Domain/UseCases/Calendar/ComputeCheckupScheduleUseCase.swift
  Domain/UseCases/Calendar/CheckupDecorationProvider.swift
  Domain/UseCases/Calendar/FeedingVolumeDecorationProvider.swift
  Domain/UseCases/Calendar/BuildMonthCalendarUseCase.swift
  Feature/Dashboard/CalendarViewModel.swift
  Feature/Dashboard/DashboardCalendarSection.swift
  Shared/DesignSystem/Components/Calendar/CalendarCellView.swift
  Shared/DesignSystem/Components/Calendar/WeekdayHeaderView.swift
  Shared/DesignSystem/Components/Calendar/MonthHeaderView.swift
  Shared/DesignSystem/Components/Calendar/CheckupBannerView.swift
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
    puts "  WARN — file not found on disk: #{abs_path}"
    next
  end

  parts = rel_path.split('/')
  group = find_or_create_group(zzippu_group, parts[0..-2])

  file_ref = group.new_reference(parts.last)
  file_ref.set_explicit_file_type
  file_ref.source_tree = '<group>'

  target.source_build_phase.add_file_reference(file_ref)
  puts "  added: #{rel_path}"
  added << rel_path
end

project.save
puts "\nDone. #{added.size} file(s) added to '#{TARGET_NAME}' target."
