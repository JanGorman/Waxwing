Pod::Spec.new do |s|

  s.name         = "Waxwing"
  s.version      = "2.0.3"
  s.summary      = "iOS version migrations"

  s.description  = <<-DESC
                   iOS version migrations in Swift. When mangling data or performing any other kind of updates you want to ensure that all relevant migrations are run in order and only once. Waxwing allows you to just that.
                   DESC

  s.homepage     = "https://github.com/JanGorman/Waxwing"

  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "Jan Gorman" => "gorman.jan@gmail.com" }
  s.social_media_url   = "http://twitter.com/JanGorman"

  s.platform     = :ios, "8.0"
  s.requires_arc = true
  
  s.source       = { :git => "https://github.com/JanGorman/Waxwing.git", :tag => s.version.to_s }

  s.source_files  = "Waxwing/WaxWing/Waxwing.swift"

end
