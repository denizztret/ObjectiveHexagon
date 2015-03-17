Pod::Spec.new do |s|
    s.name			= "ObjectiveHexagon"
    s.version		= "0.2.0"
    s.summary		= "Objective-C Hexagon Kit"
    s.description	= "Create and manage hexagonal shapes and grid."
    s.homepage		= "https://github.com/denizztret/ObjectiveHexagon"
    s.author		= { "Denis Tretyakov" => "denizz.tret@gmail.com" }
    s.license		= { :type => 'MIT', :file => 'LICENSE' }
    # Source Info
    s.ios.deployment_target = "7.0"
    s.source        = {:git => "https://github.com/denizztret/ObjectiveHexagon.git", :tag => "0.2.0" }
    s.source_files  = 'ObjectiveHexagon/*.{h,m}'
    s.public_header_files   = 'ObjectiveHexagon/*.{h}'
    s.requires_arc  = true
end
