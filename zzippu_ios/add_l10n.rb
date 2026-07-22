# encoding: utf-8
require 'xcodeproj'
proj = Xcodeproj::Project.open('zzippu.xcodeproj')
root = proj.root_object

# 소스(기본) 언어 = 한국어, 지원 언어에 ko/en 등록
root.development_region = 'ko'
regions = root.known_regions || []
%w[ko en Base].each { |r| regions << r unless regions.include?(r) }
root.known_regions = regions
puts "developmentRegion=#{root.development_region}, knownRegions=#{root.known_regions.inspect}"

# 문자열 카탈로그를 앱 타깃 리소스로 등록
target = proj.targets.find { |t| t.name == 'zzippu' }
main = proj.main_group['zzippu'] || proj.main_group
base = 'Localizable.xcstrings'
unless main.files.any? { |f| f.display_name == base }
  ref = main.new_reference(base)
  target.resources_build_phase.add_file_reference(ref)
  puts "added resource: #{base}"
else
  puts "already: #{base}"
end

proj.save
puts 'saved'
