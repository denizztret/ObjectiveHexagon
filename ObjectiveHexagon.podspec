Pod::Spec.new do |s|
    s.name			= "ObjectiveHexagon"
    s.version		= "0.1.0"
    s.summary		= "Objective-C Hexagon Kit"
    s.description	= "Create and manage hexagonal shapes and grid."
    s.homepage		= "https://github.com/denizztret/ObjectiveHexagon"
    s.author		= { "Denis Tretyakov" => "denizz.tret@gmail.com" }
    s.license		= { :type => 'MIT', :file => 'LICENSE' }
    # Source Info
    s.platform		= :ios, "6.0"
    s.source        = {:git => "https://github.com/denizztret/ObjectiveHexagon.git", :tag => "#{s.version}" }
    s.source_files  = 'ObjectiveHexagon/*.{h,m}'
    s.public_header_files   = 'ObjectiveHexagon/*.{h}'
    s.requires_arc  = true
end