#!/usr/bin/env ruby
# tools/add-files-to-xcode.rb
# DesignSystem 신규 Swift 파일을 zzippu 타겟에 등록하는 스크립트.
# Usage: ruby tools/add-files-to-xcode.rb

require 'xcodeproj'
require 'pathname'

PROJECT_PATH = File.expand_path('../zzippu.xcodeproj', __dir__)
TARGET_NAME  = 'zzippu'
ZZIPPU_ROOT  = File.expand_path('../zzippu', __dir__)

# 등록할 신규 파일 (zzippu/ 기준 상대 경로)
NEW_FILES = %w[
  Shared/DesignSystem/Foundation/Color+Hex.swift
  Shared/DesignSystem/Foundation/View+DSShadow.swift
  Shared/DesignSystem/Theme/DynamicColor.swift
  Shared/DesignSystem/Theme/Theme.swift
  Shared/DesignSystem/Theme/Theme+zzippu.swift
  Shared/DesignSystem/Theme/EnvironmentTheme.swift
  Shared/DesignSystem/Tokens/PrimitiveColors.generated.swift
  Shared/DesignSystem/Tokens/PrimitiveScale.generated.swift
  Shared/DesignSystem/Tokens/SemanticColors.generated.swift
  Shared/DesignSystem/Tokens/Typography.generated.swift
  Shared/DesignSystem/Tokens/Shadows.generated.swift
  Shared/DesignSystem/Tokens/Motion.generated.swift
  Shared/DesignSystem/Components/Buttons/DSButton.swift
  Shared/DesignSystem/Components/Buttons/DSIconButton.swift
  Shared/DesignSystem/Components/Containers/DSCard.swift
  Shared/DesignSystem/Components/Inputs/DSTextField.swift
  Shared/DesignSystem/Components/Inputs/DSChip.swift
  Shared/DesignSystem/Components/Feedback/DSStatusPill.swift
  Shared/DesignSystem/Components/Feedback/DSBadge.swift
  Shared/DesignSystem/Components/Lists/DSSectionHeader.swift
  Shared/DesignSystem/Components/Lists/DSEmptyState.swift
  Shared/DesignSystem/Components/Lists/DSListRow.swift
  Shared/DesignSystem/Components/Lists/TimelineRow.swift
  Shared/DesignSystem/Components/Overlays/DSBottomSheet.swift
  Shared/DesignSystem/Components/Feedback/ToastCenter.swift
  Shared/DesignSystem/Components/Feedback/DSGaugeBar.swift
  Shared/DesignSystem/Components/Media/BabyAvatar.swift
  Shared/DesignSystem/Components/Navigation/DSTabBar.swift
  Shared/DesignSystem/Components/Navigation/AppHeader.swift
  Shared/DesignSystem/Components/Inputs/DSNumberStepper.swift
].freeze

project = Xcodeproj::Project.open(PROJECT_PATH)
target  = project.targets.find { |t| t.name == TARGET_NAME }
raise "Target '#{TARGET_NAME}' not found" unless target

# Find or create a group under the zzippu group matching the path
zzippu_group = project.main_group.find_subpath('zzippu', false)
raise 'zzippu group not found in project' unless zzippu_group

# Helper: find or create nested group
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

# Collect already-registered file paths (relative to zzippu/)
already = Set.new
target.source_build_phase.files.each do |f|
  next unless f.file_ref
  path = f.file_ref.real_path.to_s
  rel  = Pathname.new(path).relative_path_from(Pathname.new(ZZIPPU_ROOT)).to_s rescue nil
  already << rel if rel
end

added = []
NEW_FILES.each do |rel_path|
  # Skip if already in target
  if already.include?(rel_path)
    puts "  skip (already registered): #{rel_path}"
    next
  end

  abs_path = File.join(ZZIPPU_ROOT, rel_path)
  unless File.exist?(abs_path)
    puts "  WARN file not found: #{abs_path}"
    next
  end

  # Determine group path: everything except the filename
  parts      = rel_path.split('/')
  filename   = parts.pop
  group_path = parts

  group = find_or_create_group(zzippu_group, group_path)

  # Check if file reference already exists in the group
  existing_ref = group.children.find { |c| c.is_a?(Xcodeproj::Project::Object::PBXFileReference) && c.path == filename }
  file_ref = existing_ref || group.new_file(abs_path)

  # Add to Sources build phase
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
