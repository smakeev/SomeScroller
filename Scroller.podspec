Pod::Spec.new do |s|
  s.name         = "Scroller"
  s.version      = "1.0.0"
  s.summary      = "Scroll view to present items"
  s.description  = "Scroll view will scroll items infinity if needed. See README.md for more information"
  s.homepage     = "https://github.com/smakeev/SomeScroller"
  s.license      = { :type => 'MIT' }
  s.author       = { "Sergey Makeev" => "makeev.87@gmail.com" }
  s.platform     = :ios, "9.0"
  s.source       =  { :git => "https://github.com/smakeev/SomeScroller.git", :tag => "#{s.version}" }
  s.source_files  = "Scroller/Scroller/*.{swift}"
  s.exclude_files = "Scroller/Scroller/*.plist"
  s.swift_version = '5.1'
end
